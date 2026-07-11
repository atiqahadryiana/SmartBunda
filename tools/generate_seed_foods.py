"""Generate lib/data/seed_foods.dart from tools/foods_master.csv.

Single source of truth for the seeded food catalog. Edit foods_master.csv,
then re-run:  py -3.14 tools/generate_seed_foods.py

Each row -> one FoodItem with a stable kebab-case id (so re-seeding overwrites
rather than duplicates). Nutrition is per the stated serving (energy kcal;
protein/carb/fat g; iron/calcium/sodium mg; folate/vit D/vit B12 mcg),
MyFCD-grounded (myfcd.moh.gov.my) and Malaysian-portion estimates.
"""

import csv
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CSV_PATH = ROOT / "tools" / "foods_master.csv"
OUT_PATH = ROOT / "lib" / "data" / "seed_foods.dart"


def kebab(name: str) -> str:
    s = name.lower()
    s = re.sub(r"[()&/,.]", " ", s)
    s = re.sub(r"[^a-z0-9]+", "-", s)
    return "seed-" + s.strip("-")


def dart_num(value: str) -> str:
    """Render ints without a decimal; keep floats as-is."""
    value = (value or "0").strip()
    try:
        f = float(value)
    except ValueError:
        return "0"
    return str(int(f)) if f == int(f) else str(f)


HEADER = '''/// SmartBunda — multicultural food catalog seed (GENERATED).
///
/// DO NOT EDIT BY HAND. Generated from tools/foods_master.csv by
/// tools/generate_seed_foods.py — edit the CSV and re-run the generator.
///
/// A curated set of Malay, Malaysian-Chinese, Malaysian-Indian and popular
/// Western dishes used to populate the food catalog. Seeded into the Firestore
/// `foods` collection via the "Seed sample foods" action on the Food database
/// admin screen. Each entry carries a stable kebab-case [id] so re-running the
/// seed overwrites rather than duplicates.
///
/// Nutrition figures are per the stated serving for a single typical portion
/// (energy in kcal; protein/carb/fat in grams; iron/calcium/sodium in mg;
/// folate, vitamin D and vitamin B12 in mcg). Values are based on the Malaysian
/// Food Composition Database (MyFCD, myfcd.moh.gov.my) and Malaysian RNI
/// references, converted to a typical serving size. They are best-effort
/// references for guidance, not lab-exact measurements for any specific recipe.
library smartbunda.seed_foods;

import 'package:smartbunda/models/food_item.dart';

/// Builds the list of sample foods to seed. Kept as a function so each call
/// returns fresh [FoodItem] instances.
List<FoodItem> buildSeedFoods() => [
'''

FOOTER = "    ];\n"


def main() -> int:
    rows = []
    seen_ids: dict[str, str] = {}
    with CSV_PATH.open(encoding="utf-8") as f:
        for row in csv.DictReader(f):
            name = row["name"].strip()
            if not name:
                continue
            fid = kebab(name)
            if fid in seen_ids:
                raise SystemExit(
                    f"Duplicate id {fid!r} from {name!r} and {seen_ids[fid]!r}"
                )
            seen_ids[fid] = name
            rows.append(row)

    lines = [HEADER]
    current_cat = None
    for row in rows:
        cat = row["category"].strip()
        if cat != current_cat:
            current_cat = cat
            lines.append(f"      // ── {cat} ──\n")
        fid = kebab(row["name"])
        name = row["name"].replace("'", r"\'")
        serving = row["serving"].replace("'", r"\'")
        lines.append(
            "      FoodItem(\n"
            f"        id: '{fid}',\n"
            f"        name: '{name}',\n"
            f"        servingSize: '{serving}',\n"
            f"        caloriesPerServing: {dart_num(row['calories'])},\n"
            f"        proteinG: {dart_num(row['protein'])},\n"
            f"        carbG: {dart_num(row['carbs'])},\n"
            f"        fatG: {dart_num(row['fat'])},\n"
            f"        ironMg: {dart_num(row['iron_mg'])},\n"
            f"        folateMcg: {dart_num(row['folate_mcg'])},\n"
            f"        calciumMg: {dart_num(row['calcium_mg'])},\n"
            f"        vitaminDMcg: {dart_num(row['vitamin_d_mcg'])},\n"
            f"        vitaminB12Mcg: {dart_num(row['vitamin_b12_mcg'])},\n"
            f"        sodiumMg: {dart_num(row['sodium_mg'])},\n"
            "      ),\n"
        )
    lines.append(FOOTER)

    OUT_PATH.write_text("".join(lines), encoding="utf-8")
    print(f"Wrote {len(rows)} foods to {OUT_PATH}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
