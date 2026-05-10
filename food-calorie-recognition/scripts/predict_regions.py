from __future__ import annotations

import argparse
from pathlib import Path

import cv2

from food_calorie.config import PROJECT_ROOT
from food_calorie.predictor import FoodPredictor
from food_calorie.vision import detect_candidate_food_regions, estimate_portion_multiplier


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Experimental multi-food region prediction.")
    parser.add_argument("image", type=Path)
    parser.add_argument("--model", type=Path, default=PROJECT_ROOT / "models" / "food_calorie_model.h5")
    parser.add_argument("--labels", type=Path, default=PROJECT_ROOT / "models" / "class_names.json")
    parser.add_argument("--nutrition-db", type=Path, default=PROJECT_ROOT / "data" / "myfcd_cache.sqlite")
    parser.add_argument("--seed-food-db", type=Path, default=PROJECT_ROOT / "data" / "food_database.json")
    parser.add_argument("--annotated-output", type=Path, default=PROJECT_ROOT / "outputs" / "annotated_prediction.jpg")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    image_bgr = cv2.imread(str(args.image))
    if image_bgr is None:
        raise ValueError(f"Could not read image: {args.image}")

    predictor = FoodPredictor(args.model, args.labels, args.nutrition_db, seed_food_db_path=args.seed_food_db)
    boxes = detect_candidate_food_regions(image_bgr)
    total_calories = 0.0

    for box in boxes:
        x, y, w, h = box
        crop_bgr = image_bgr[y : y + h, x : x + w]
        crop_rgb = cv2.cvtColor(crop_bgr, cv2.COLOR_BGR2RGB)
        result = predictor.predict_array(crop_rgb)
        portion = estimate_portion_multiplier(box, image_bgr.shape)
        calories = (result.calories or 0) * portion
        total_calories += calories

        label = f"{result.food_name} {result.confidence * 100:.1f}% {calories:.0f} kcal"
        cv2.rectangle(image_bgr, (x, y), (x + w, y + h), (0, 180, 0), 2)
        cv2.putText(image_bgr, label, (x, max(24, y - 8)), cv2.FONT_HERSHEY_SIMPLEX, 0.55, (0, 180, 0), 2)
        print(
            f"{result.food_name}: confidence={result.confidence * 100:.2f}%, "
            f"portion={portion:.2f}x, calories={calories:.0f}"
        )

    args.annotated_output.parent.mkdir(parents=True, exist_ok=True)
    cv2.imwrite(str(args.annotated_output), image_bgr)
    print(f"Estimated total calories: {total_calories:.0f} kcal")
    print(f"Saved annotated image: {args.annotated_output}")


if __name__ == "__main__":
    main()
