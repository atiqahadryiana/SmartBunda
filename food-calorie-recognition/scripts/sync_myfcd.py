from __future__ import annotations

import argparse
from pathlib import Path

from food_calorie.config import PROJECT_ROOT
from food_calorie.database import NutritionDatabase
from food_calorie.myfcd import MyFCDClient, seed_database_from_json


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Seed, refresh, and export MyFCD cache.")
    parser.add_argument("foods", nargs="*", help="Food names to refresh from MyFCD.")
    parser.add_argument("--db", type=Path, default=PROJECT_ROOT / "data" / "myfcd_cache.sqlite")
    parser.add_argument("--seed-json", type=Path, default=PROJECT_ROOT / "data" / "food_database.json")
    parser.add_argument("--export-json", type=Path, default=PROJECT_ROOT / "outputs" / "nutrition_export.json")
    parser.add_argument("--export-csv", type=Path, default=PROJECT_ROOT / "outputs" / "nutrition_export.csv")
    parser.add_argument("--offline-seed-only", action="store_true")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    db = NutritionDatabase(args.db)
    if args.seed_json.exists():
        seed_database_from_json(db, args.seed_json)

    if args.foods and not args.offline_seed_only:
        client = MyFCDClient(database=db)
        for food_name in args.foods:
            result = client.lookup(food_name, refresh=True)
            status = "found" if result else "not found"
            print(f"{food_name}: {status}")

    db.export_json(args.export_json)
    db.export_csv(args.export_csv)
    print(f"Exported JSON: {args.export_json}")
    print(f"Exported CSV: {args.export_csv}")


if __name__ == "__main__":
    main()
