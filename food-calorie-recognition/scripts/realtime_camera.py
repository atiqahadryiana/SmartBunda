from __future__ import annotations

import argparse
from pathlib import Path

import cv2

from food_calorie.config import PROJECT_ROOT
from food_calorie.predictor import FoodPredictor


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Real-time webcam food prediction demo.")
    parser.add_argument("--camera", type=int, default=0)
    parser.add_argument("--model", type=Path, default=PROJECT_ROOT / "models" / "food_calorie_model.h5")
    parser.add_argument("--labels", type=Path, default=PROJECT_ROOT / "models" / "class_names.json")
    parser.add_argument("--nutrition-db", type=Path, default=PROJECT_ROOT / "data" / "myfcd_cache.sqlite")
    parser.add_argument("--seed-food-db", type=Path, default=PROJECT_ROOT / "data" / "food_database.json")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    predictor = FoodPredictor(args.model, args.labels, args.nutrition_db, seed_food_db_path=args.seed_food_db)
    camera = cv2.VideoCapture(args.camera)
    if not camera.isOpened():
        raise RuntimeError(f"Could not open camera index {args.camera}")

    try:
        while True:
            ok, frame_bgr = camera.read()
            if not ok:
                break
            frame_rgb = cv2.cvtColor(frame_bgr, cv2.COLOR_BGR2RGB)
            result = predictor.predict_array(frame_rgb)
            label = f"{result.food_name} {result.confidence * 100:.1f}% {result.calories or 0:.0f} kcal"
            cv2.putText(frame_bgr, label, (20, 40), cv2.FONT_HERSHEY_SIMPLEX, 0.8, (0, 255, 0), 2)
            cv2.imshow("Food calorie prediction", frame_bgr)
            if cv2.waitKey(1) & 0xFF == ord("q"):
                break
    finally:
        camera.release()
        cv2.destroyAllWindows()


if __name__ == "__main__":
    main()
