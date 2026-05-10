from __future__ import annotations

import argparse
from pathlib import Path

from food_calorie.config import PROJECT_ROOT
from food_calorie.predictor import FoodPredictor


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Predict food and calories from an image.")
    parser.add_argument("image", type=Path, help="Path to uploaded or captured food image.")
    parser.add_argument("--model", type=Path, default=PROJECT_ROOT / "models" / "food_calorie_model.h5")
    parser.add_argument("--labels", type=Path, default=PROJECT_ROOT / "models" / "class_names.json")
    parser.add_argument("--nutrition-db", type=Path, default=PROJECT_ROOT / "data" / "myfcd_cache.sqlite")
    parser.add_argument("--seed-food-db", type=Path, default=PROJECT_ROOT / "data" / "food_database.json")
    parser.add_argument("--offline", action="store_true", help="Disable live MyFCD lookup.")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    predictor = FoodPredictor(
        args.model,
        args.labels,
        args.nutrition_db,
        seed_food_db_path=args.seed_food_db,
        enable_live_myfcd=not args.offline,
    )
    result = predictor.predict_file(args.image)

    print(f"Predicted Food Name: {result.food_name.replace('_', ' ').title()}")
    print(f"Confidence Score: {result.confidence * 100:.2f}%")
    print(result.to_api_dict())


if __name__ == "__main__":
    main()
