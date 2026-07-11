"""Scrape food nutrition from the Malaysian Food Composition Database (MyFCD).

Source: https://myfcd.moh.gov.my/  (Institute for Medical Research, Malaysia)

How it works (discovered via tools/myfcd_probe*.py):
  1. The food list is served as JSON by a DataTables endpoint:
        GET {module}/index.php/ajax/datatable_data
     Each row is [code, NAME, version, module], e.g.
        ["R101061", "BISCUIT, COCONUT", "1.01", "myfcdcurrent"].
  2. Each food's full nutrient table is at:
        {module}/index.php/site/detail_product/{code}/0/0/0/0/0
     The data lives in a 3-column table: Nutrient | Unit | Value per 100g.

Output (per 100g edible portion):
  - assets/myfcd_foods.csv  -> import-ready columns matching the in-app importer
    (id,name,serving,calories,protein,carbs,fat,iron,folate,
     calcium,vitamin_d,vitamin_b12,sodium)

Usage:
  python tools/myfcd_scrape.py                  # current module (~233 foods)
  python tools/myfcd_scrape.py --module myfcd97 # the larger legacy module
  python tools/myfcd_scrape.py --limit 20       # quick test
  python tools/myfcd_scrape.py --delay 0.5      # politeness delay between hits

Be polite: this hits a public government server. Keep --delay reasonable and
don't run it repeatedly. Values are per 100g; adjust 'serving' after import if
you want per-portion figures.
"""

from __future__ import annotations

import argparse
import csv
import re
import sys
import time
from pathlib import Path

import requests
from bs4 import BeautifulSoup

HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
        "(KHTML, like Gecko) Chrome/124.0 Safari/537.36"
    ),
    "Accept-Language": "en-US,en;q=0.9",
}

# MyFCD nutrient label (lowercased, stripped) -> our CSV column.
# Labels confirmed against live detail pages (tools/myfcd_probe5.py). MyFCD uses
# specific wording we must match exactly-ish:
#   - Folate is "Folic Acid (B9)" (NOT "folate").
#   - Vitamin D is split into "Ergocalciferol (D2)" + "Cholecalciferol (D3)";
#     we SUM them into vitamin_d (see scrape_detail).
#   - Vitamin B12 has NO row in the current module, so it stays blank.
NUTRIENT_MAP = {
    "energy": "calories",
    "protein": "protein",
    "carbohydrate": "carbs",
    "fat": "fat",
    "iron": "iron",
    "iron, fe": "iron",
    "calcium": "calcium",
    "calcium, ca": "calcium",
    "sodium": "sodium",
    "sodium, na": "sodium",
    "folic acid (b9)": "folate",
    "folate": "folate",
    "folate, total": "folate",
    "vitamin b12": "vitamin_b12",
    "vitamin b-12": "vitamin_b12",
    "cobalamin": "vitamin_b12",
}

# Vitamin D is reported as two separate vitamers; sum them.
VITAMIN_D_LABELS = ("ergocalciferol (d2)", "cholecalciferol (d3)")

CSV_COLUMNS = [
    "id", "name", "serving", "calories", "protein", "carbs", "fat",
    "iron", "folate", "calcium", "vitamin_d", "vitamin_b12", "sodium",
]


def base_url(module: str) -> str:
    return f"https://myfcd.moh.gov.my/{module}/index.php"


def fetch_food_list(session: requests.Session, module: str) -> list[tuple[str, str]]:
    """Return [(code, name), ...] from the DataTables JSON endpoint."""
    url = base_url(module) + "/ajax/datatable_data"
    params = {
        "draw": "1", "start": "0", "length": "100000",
        "search[value]": "", "search[regex]": "false",
        "columns[0][data]": "0", "columns[0][searchable]": "true",
        "columns[0][orderable]": "true",
        "order[0][column]": "0", "order[0][dir]": "asc",
    }
    r = session.get(url, params=params, timeout=120)
    r.raise_for_status()
    data = r.json()
    out = []
    for row in data.get("data", []):
        if len(row) >= 2 and row[0]:
            out.append((str(row[0]).strip(), str(row[1]).strip()))
    return out


def normalise_label(label: str) -> str:
    s = label.lower().strip()
    s = re.sub(r"\s+", " ", s)
    return s


def parse_number(text: str) -> float | None:
    if text is None:
        return None
    t = text.strip().replace(",", "")
    if t in ("", "-", "tr", "trace", "nd", "n/a", "na"):
        return None
    m = re.search(r"[-+]?\d*\.?\d+", t)
    return float(m.group(0)) if m else None


def to_title(name: str) -> str:
    """MyFCD names are often ALL CAPS; make them readable but keep as-is words."""
    if name.isupper():
        return name.title()
    return name


def kebab_id(code: str) -> str:
    return f"myfcd-{code.lower()}"


def _category_digit(code: str) -> str:
    """First numeric digit of a MyFCD code (after any letter prefix).

    MyFCD major categories: 1 = raw/packaged ingredients, 2 = prepared/cooked
    dishes, 4/5 = mixed/analytical sets. Returns '' if no digit found.
    """
    m = re.search(r"\d", code)
    return m.group(0) if m else ""


def scrape_detail(
    session: requests.Session, module: str, code: str
) -> dict[str, float] | None:
    """Fetch one food's per-100g nutrient values; return {column: value}."""
    url = base_url(module) + f"/site/detail_product/{code}/0/0/0/0/0"
    r = session.get(url, timeout=90)
    if r.status_code != 200 or "uncaught" in r.text.lower():
        return None
    soup = BeautifulSoup(r.text, "html.parser")

    # Find the nutrient table: the one whose header mentions "Value per 100".
    nutrient_table = None
    for table in soup.find_all("table"):
        head = table.get_text(" ", strip=True).lower()
        if "value per 100" in head or ("nutrient" in head and "unit" in head):
            nutrient_table = table
            break
    if nutrient_table is None:
        return None

    values: dict[str, float] = {}
    vitamin_d_total = 0.0
    saw_vitamin_d = False
    for tr in nutrient_table.find_all("tr"):
        cells = [c.get_text(" ", strip=True) for c in tr.find_all(["td", "th"])]
        if len(cells) < 3:
            continue
        label = normalise_label(cells[0])
        val = parse_number(cells[2])  # column 2 is "Value per 100g"

        # Vitamin D: accumulate D2 + D3.
        if label in VITAMIN_D_LABELS:
            saw_vitamin_d = True
            if val is not None:
                vitamin_d_total += val
            continue

        # Everything else: exact label match only (no prefix matching, so
        # "Fatty acids..." never gets mistaken for "fat", etc.).
        column = NUTRIENT_MAP.get(label)
        if column is None:
            continue
        if val is not None and column not in values:
            values[column] = val

    if saw_vitamin_d:
        values["vitamin_d"] = round(vitamin_d_total, 3)
    return values or None


def main(argv: list[str]) -> int:
    ap = argparse.ArgumentParser(description="Scrape MyFCD food nutrition.")
    ap.add_argument("--module", default="myfcdcurrent",
                    help="myfcdcurrent (default) or myfcd97")
    ap.add_argument("--limit", type=int, default=0, help="max foods (0 = all)")
    ap.add_argument("--delay", type=float, default=0.4,
                    help="seconds between detail requests")
    ap.add_argument("--out", default=None, help="output CSV path")
    ap.add_argument("--cooked", action="store_true",
                    help="only prepared/cooked dishes (MyFCD category code 2xx)")
    ap.add_argument("--append", action="store_true",
                    help="append to the CSV instead of overwriting (no header)")
    args = ap.parse_args(argv)

    session = requests.Session()
    session.headers.update(HEADERS)
    session.headers["Referer"] = f"https://myfcd.moh.gov.my/{args.module}/"
    session.get(f"https://myfcd.moh.gov.my/{args.module}/", timeout=60)  # cookies

    foods = fetch_food_list(session, args.module)
    if args.cooked:
        # MyFCD major category 2 = "Prepared/cooked dishes". Codes look like
        # "222001" or "R222001"; the digit right after any letter prefix is the
        # category. Keep only those starting with 2.
        before = len(foods)
        foods = [(c, n) for c, n in foods if _category_digit(c) == "2"]
        print(f"Cooked-dish filter: {len(foods)}/{before} foods kept (category 2xx).")
    if args.limit:
        foods = foods[: args.limit]
    print(f"Scraping {len(foods)} foods from module '{args.module}'.")

    out_path = Path(args.out) if args.out else (
        Path(__file__).resolve().parent.parent / "assets" / "myfcd_foods.csv"
    )
    out_path.parent.mkdir(parents=True, exist_ok=True)

    ok = 0
    skipped = 0
    mode = "a" if args.append and out_path.exists() else "w"
    with out_path.open(mode, newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=CSV_COLUMNS)
        if mode == "w":
            writer.writeheader()
        for i, (code, name) in enumerate(foods, 1):
            try:
                nutrients = scrape_detail(session, args.module, code)
            except Exception as e:  # noqa: BLE001
                print(f"  [{i}/{len(foods)}] {code} ERROR {e!r}")
                nutrients = None
            if not nutrients:
                skipped += 1
                print(f"  [{i}/{len(foods)}] {code} {name}  -- no data, skipped")
                time.sleep(args.delay)
                continue

            row = {c: "" for c in CSV_COLUMNS}
            row["id"] = kebab_id(code)
            row["name"] = to_title(name)
            row["serving"] = "100 g"
            for col, val in nutrients.items():
                # calories/protein/carbs/fat read cleanest as whole-ish numbers,
                # but the importer parses any number, so write the raw value.
                row[col] = val
            writer.writerow(row)
            ok += 1
            if i % 10 == 0 or i == len(foods):
                print(f"  [{i}/{len(foods)}] scraped {ok}, skipped {skipped}")
            time.sleep(args.delay)

    print(f"\nDone. Wrote {ok} foods to {out_path} (skipped {skipped}).")
    print("Import it in-app via Food database -> Import (xlsx/xls): open the CSV "
          "in Excel and Save As .xlsx first, then import.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
