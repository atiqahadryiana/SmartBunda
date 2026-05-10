"""Reusable MyFCD lookup with local cache fallback.

The public MyFCD pages are partly dynamic, so this scraper is deliberately
defensive: it tries query and listing pages, extracts any nutrient-like table
it can find, and falls back to the offline SQLite/JSON cache when live data is
missing or the network is unavailable.
"""

from __future__ import annotations

import logging
import re
from pathlib import Path
from urllib.parse import quote_plus

import requests
from bs4 import BeautifulSoup

from food_calorie.config import normalize_label
from food_calorie.database import NutritionDatabase
from food_calorie.nutrition import NutritionInfo


LOGGER = logging.getLogger(__name__)
MYFCD_BASE_URL = "https://myfcd.moh.gov.my"
MYFCD_ENDPOINTS = (
    "/",
    "/myfcdcurrent/",
    "/myfcd97/",
    "/myfcdindustri/",
)
NUTRIENT_ALIASES = {
    "calories": ("energy", "calorie", "kcal"),
    "protein": ("protein",),
    "carbohydrates": ("carbohydrate", "carbohydrates", "cho"),
    "fat": ("fat", "lipid"),
    "sugar": ("sugar", "sugars"),
    "sodium": ("sodium", "natrium", "na"),
}


class MyFCDClient:
    def __init__(
        self,
        *,
        database: NutritionDatabase,
        timeout: float = 10.0,
        base_url: str = MYFCD_BASE_URL,
    ) -> None:
        self.database = database
        self.timeout = timeout
        self.base_url = base_url.rstrip("/")
        self.session = requests.Session()
        self.session.headers.update(
            {
                "User-Agent": (
                    "SMARTBUNDA-FoodRecognition/1.0 "
                    "(nutrition lookup for student project)"
                )
            }
        )

    def lookup(self, food_name: str, *, refresh: bool = False) -> NutritionInfo | None:
        cached = self.database.get(food_name)
        if cached and not refresh:
            return cached

        try:
            live = self._lookup_live(food_name)
        except requests.RequestException as error:
            LOGGER.warning("MyFCD network lookup failed for %s: %s", food_name, error)
            live = None

        if live is not None:
            self.database.upsert(live)
            return live
        return cached

    def _lookup_live(self, food_name: str) -> NutritionInfo | None:
        query = food_name.replace("_", " ")
        pages = []
        for endpoint in MYFCD_ENDPOINTS:
            url = f"{self.base_url}{endpoint}"
            response = self.session.get(url, params={"search": query}, timeout=self.timeout)
            response.raise_for_status()
            pages.append(response.text)

        for html in pages:
            info = self._parse_page(query, html)
            if info is not None:
                return info
        return None

    def _parse_page(self, query: str, html: str) -> NutritionInfo | None:
        soup = BeautifulSoup(html, "html.parser")
        text = soup.get_text(" ", strip=True)
        if normalize_label(query) not in normalize_label(text):
            return None

        nutrients = self._parse_tables(soup)
        if not nutrients:
            nutrients = self._parse_loose_text(text)
        if not nutrients:
            return None

        return NutritionInfo(
            food_name=query.title(),
            calories=nutrients.get("calories"),
            protein=nutrients.get("protein"),
            carbohydrates=nutrients.get("carbohydrates"),
            fat=nutrients.get("fat"),
            sugar=nutrients.get("sugar"),
            sodium=nutrients.get("sodium"),
            serving_size="per 100g",
            source="MyFCD",
        )

    def _parse_tables(self, soup: BeautifulSoup) -> dict[str, float]:
        parsed: dict[str, float] = {}
        for row in soup.select("tr"):
            cells = [cell.get_text(" ", strip=True) for cell in row.select("th,td")]
            if len(cells) < 2:
                continue
            label = cells[0].lower()
            value = _first_number(" ".join(cells[1:]))
            if value is None:
                continue
            key = _match_nutrient(label)
            if key:
                parsed[key] = value
        return parsed

    def _parse_loose_text(self, text: str) -> dict[str, float]:
        parsed: dict[str, float] = {}
        for key, aliases in NUTRIENT_ALIASES.items():
            for alias in aliases:
                match = re.search(rf"{re.escape(alias)}\D+(\d+(?:\.\d+)?)", text, re.I)
                if match:
                    parsed[key] = float(match.group(1))
                    break
        return parsed


def seed_database_from_json(database: NutritionDatabase, json_path: Path) -> None:
    import json

    raw = json.loads(json_path.read_text(encoding="utf-8"))
    for key, value in raw.items():
        database.upsert(
            NutritionInfo(
                food_name=key.replace("_", " ").title(),
                calories=value.get("calories"),
                protein=value.get("protein_g"),
                carbohydrates=value.get("carbs_g"),
                fat=value.get("fat_g"),
                sugar=value.get("sugar_g"),
                sodium=value.get("sodium_mg"),
                serving_size=value.get("serving", "per serving"),
                source=value.get("source", "offline_seed"),
            )
        )


def search_url(food_name: str) -> str:
    return f"{MYFCD_BASE_URL}/?search={quote_plus(food_name)}"


def _first_number(text: str) -> float | None:
    match = re.search(r"[-+]?\d+(?:\.\d+)?", text)
    return float(match.group(0)) if match else None


def _match_nutrient(label: str) -> str | None:
    normalized = label.lower()
    for key, aliases in NUTRIENT_ALIASES.items():
        if any(alias in normalized for alias in aliases):
            return key
    return None
