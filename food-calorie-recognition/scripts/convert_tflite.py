from __future__ import annotations

import argparse
from pathlib import Path

from food_calorie.config import PROJECT_ROOT
from food_calorie.tflite import convert_to_tflite


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Convert Keras model to TensorFlow Lite.")
    parser.add_argument("--model", type=Path, default=PROJECT_ROOT / "models" / "food_calorie_model.h5")
    parser.add_argument("--output", type=Path, default=PROJECT_ROOT / "models" / "food_calorie_model.tflite")
    parser.add_argument("--no-quantization", action="store_true")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    output_path = convert_to_tflite(
        args.model,
        args.output,
        quantize=not args.no_quantization,
    )
    print(f"Saved TensorFlow Lite model: {output_path}")


if __name__ == "__main__":
    main()
