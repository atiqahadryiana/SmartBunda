"""Seed the SmartBunda Firestore `foods` collection from tools/foods_master.csv.

Usage:
    python scripts/seed_fooddb.py

Requires:
    pip install firebase-admin

Credentials:
    Put serviceAccount.json at the project root, or set
    GOOGLE_APPLICATION_CREDENTIALS to a service-account JSON path.

The CSV is the single source of truth used by lib/data/seed_foods.dart. This
script mirrors that data into Firestore using stable `seed-*` document IDs, so
running it again updates the latest nutrition values instead of duplicating
foods.
"""

from __future__ import annotations

import csv
import os
import re
from pathlib import Path
from typing import Any

import firebase_admin
from firebase_admin import credentials, firestore

SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parent
CSV_PATH = PROJECT_ROOT / "tools" / "foods_master.csv"
SERVICE_ACCOUNT = PROJECT_ROOT / "serviceAccount.json"


def kebab(name: str) -> str:
    text = name.lower()
    text = re.sub(r"[()&/,.]", " ", text)
    text = re.sub(r"[^a-z0-9]+", "-", text)
    return "seed-" + text.strip("-")


def number(value: str) -> int | float:
    raw = (value or "0").strip()
    try:
        parsed = float(raw)
    except ValueError:
        return 0
    return int(parsed) if parsed == int(parsed) else parsed


def food_doc(row: dict[str, str]) -> dict[str, Any]:
    calories = number(row["calories"])
    protein = number(row["protein"])
    carbs = number(row["carbs"])
    fat = number(row["fat"])
    iron = number(row["iron_mg"])
    folate = number(row["folate_mcg"])
    calcium = number(row["calcium_mg"])
    vitamin_d = number(row["vitamin_d_mcg"])
    vitamin_b12 = number(row["vitamin_b12_mcg"])
    sodium = number(row["sodium_mg"])

    return {
        "name": row["name"].strip(),
        "category": row["category"].strip(),
        "servingSize": row["serving"].strip(),
        "caloriesPerServing": calories,
        "proteinG": protein,
        "carbG": carbs,
        "fatG": fat,
        "ironMg": iron,
        "folateMcg": folate,
        "calciumMg": calcium,
        "vitaminDMcg": vitamin_d,
        "vitaminB12Mcg": vitamin_b12,
        "sodiumMg": sodium,
        "nutrients": {
            "calories": calories,
            "protein_g": protein,
            "carb_g": carbs,
            "fat_g": fat,
            "iron_mg": iron,
            "folate_mcg": folate,
            "calcium_mg": calcium,
            "vitamin_d_mcg": vitamin_d,
            "vitamin_b12_mcg": vitamin_b12,
            "sodium_mg": sodium,
        },
        "isActive": True,
        "source": "seed",
    }


def load_foods() -> list[tuple[str, dict[str, Any]]]:
    if not CSV_PATH.exists():
        raise FileNotFoundError(f"Missing food CSV: {CSV_PATH}")

    foods: list[tuple[str, dict[str, Any]]] = []
    seen: set[str] = set()
    with CSV_PATH.open(encoding="utf-8", newline="") as handle:
        for row in csv.DictReader(handle):
            name = row["name"].strip()
            if not name:
                continue
            doc_id = kebab(name)
            if doc_id in seen:
                raise ValueError(f"Duplicate generated food id: {doc_id}")
            seen.add(doc_id)
            foods.append((doc_id, food_doc(row)))
    return foods


def initialize_firebase() -> None:
    cred_path = (
        SERVICE_ACCOUNT
        if SERVICE_ACCOUNT.exists()
        else os.getenv("GOOGLE_APPLICATION_CREDENTIALS")
    )
    if cred_path:
        cred = credentials.Certificate(str(cred_path))
        firebase_admin.initialize_app(cred)
    else:
        firebase_admin.initialize_app()


def seed_fooddb() -> None:
    foods = load_foods()
    initialize_firebase()

    db = firestore.client()
    batch = db.batch()
    count = 0

    for doc_id, payload in foods:
        ref = db.collection("foods").document(doc_id)
        batch.set(ref, payload)
        count += 1
        if count % 450 == 0:
            batch.commit()
            batch = db.batch()

    batch.commit()
    print(f"Seeded {count} foods into Firestore 'foods' collection.")


if __name__ == "__main__":
    seed_fooddb()
