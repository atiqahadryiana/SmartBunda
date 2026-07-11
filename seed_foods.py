"""Seed the Firestore `Foods` collection with the curated Malaysian dishes.

Source of truth: the per-100g dishes in
`lib/utils/food_nutrition_lookup.dart` (LocalNutritionLookup._kFoods). This
parses that list, scales each dish to its default portion, and upserts one
document per dish into the `Foods` collection in the schema the in-app food
picker expects (see lib/models/food_item.dart / lib/services/food_database.dart).

Run once (idempotent — deterministic doc ids, re-running updates in place):

    python seed_foods.py

Requires: firebase-admin, and serviceAccount.json (Admin SDK key) in the
project root. Writes bypass Firestore rules (Admin SDK), so no sign-in needed.
"""

import re
import sys

import firebase_admin
from firebase_admin import credentials, firestore

DART_SRC = "lib/utils/food_nutrition_lookup.dart"
SERVICE_ACCOUNT = "serviceAccount.json"
COLLECTION = "Foods"


def slugify(name: str) -> str:
    s = name.lower().strip()
    s = re.sub(r"[^a-z0-9]+", "-", s)
    return s.strip("-")


def _field(entry: str, name: str, default=None):
    m = re.search(rf"{name}:\s*'([^']*)'", entry)
    if m:
        return m.group(1)
    m = re.search(rf"{name}:\s*([\d.]+)", entry)
    if m:
        return float(m.group(1)) if "." in m.group(1) else int(m.group(1))
    return default


def parse_foods():
    src = open(DART_SRC, encoding="utf-8").read()
    start = src.index("const List<FoodNutritionData> _kFoods")
    end = src.index("];", start)
    block = src[start:end]
    entries = re.findall(
        r"FoodNutritionData\((.*?)\)\s*,\s*(?=FoodNutritionData|\Z)", block, re.S
    )
    foods = []
    for e in entries:
        name = _field(e, "name")
        if not name:
            continue
        portion = _field(e, "defaultPortionG", 200) or 200
        factor = portion / 100.0
        kcal = _field(e, "energyKcalPer100g", 0) or 0
        p = _field(e, "proteinGPer100g", 0) or 0
        f = _field(e, "fatGPer100g", 0) or 0
        c = _field(e, "carbsGPer100g", 0) or 0
        iron = _field(e, "ironMgPer100g", 0) or 0
        foods.append(
            {
                "name": name,
                "servingSize": f"{int(portion)} g serving",
                "caloriesPerServing": round(kcal * factor),
                "nutrients": {
                    "calories": round(kcal * factor),
                    "protein_g": round(p * factor),
                    "carb_g": round(c * factor),
                    "fat_g": round(f * factor),
                    "iron_mg": round(iron * factor, 1),
                    "folate_mcg": 0,
                },
                "category": _field(e, "category", ""),
                "source": "system",
                "isActive": True,
            }
        )
    return foods


def main():
    foods = parse_foods()
    print(f"Parsed {len(foods)} Malaysian dishes from {DART_SRC}")
    if not foods:
        print("Nothing to seed — aborting.")
        sys.exit(1)

    cred = credentials.Certificate(SERVICE_ACCOUNT)
    firebase_admin.initialize_app(cred)
    db = firestore.client()

    batch = db.batch()
    for food in foods:
        doc_id = slugify(food["name"])
        ref = db.collection(COLLECTION).document(doc_id)
        batch.set(ref, food, merge=True)
    batch.commit()
    print(f"Seeded {len(foods)} foods into '{COLLECTION}' "
          f"(project from serviceAccount.json).")


if __name__ == "__main__":
    main()
