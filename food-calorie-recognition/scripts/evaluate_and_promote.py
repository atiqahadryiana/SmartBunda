from __future__ import annotations

import argparse
import json
import shutil
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Copy model assets into SMARTBUNDA only if evaluation passed."
    )
    parser.add_argument("--metrics", type=Path, default=Path("models/evaluation_metrics.json"))
    parser.add_argument("--model", type=Path, default=Path("models/food_calorie_model.tflite"))
    parser.add_argument("--labels", type=Path, default=Path("models/class_names.json"))
    parser.add_argument("--nutrition-db", type=Path, default=Path("data/myfcd_cache.sqlite"))
    parser.add_argument("--target-assets", type=Path, default=Path("../assets/ml"))
    parser.add_argument("--min-accuracy", type=float, default=0.95)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    metrics = json.loads(args.metrics.read_text(encoding="utf-8"))
    accuracy = float(metrics.get("accuracy", 0.0))
    print(f"Test accuracy: {accuracy:.4%}")
    print(f"Required accuracy: {args.min_accuracy:.4%}")
    if accuracy < args.min_accuracy:
        print("FAILED: SMARTBUNDA mobile assets were not changed.")
        return

    for path in (args.model, args.labels):
        if not path.exists():
            raise FileNotFoundError(path)
    args.target_assets.mkdir(parents=True, exist_ok=True)
    shutil.copy2(args.model, args.target_assets / "food_calorie_model.tflite")
    shutil.copy2(args.labels, args.target_assets / "class_names.json")
    if args.nutrition_db.exists():
        shutil.copy2(args.nutrition_db, args.target_assets / "myfcd_cache.sqlite")
    print(f"PASSED: copied model, labels, and nutrition DB to {args.target_assets}")


if __name__ == "__main__":
    main()
