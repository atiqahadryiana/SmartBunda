"""Evaluate the trained food CNN and promote it to Flutter assets if it passes.

Example:
    python evaluate_and_promote.py --min-accuracy 0.95

The script intentionally refuses to copy model files into the mobile app when
validation accuracy is below the configured threshold.
"""

from __future__ import annotations

import argparse
import json
import shutil
from pathlib import Path

import tensorflow as tf

from food_cnn import IMAGE_SIZE


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Evaluate food_cnn.keras and copy mobile assets only after it passes."
    )
    parser.add_argument("--dataset-dir", type=Path, default=Path("dataset"))
    parser.add_argument("--model", type=Path, default=Path("artifacts/food_cnn.keras"))
    parser.add_argument("--labels", type=Path, default=Path("artifacts/labels.json"))
    parser.add_argument("--tflite", type=Path, default=Path("artifacts/food_cnn.tflite"))
    parser.add_argument("--app-assets-dir", type=Path, default=Path("../assets/ml"))
    parser.add_argument("--report", type=Path, default=Path("artifacts/evaluation_report.json"))
    parser.add_argument("--batch-size", type=int, default=32)
    parser.add_argument("--validation-split", type=float, default=0.2)
    parser.add_argument("--seed", type=int, default=42)
    parser.add_argument(
        "--min-accuracy",
        type=float,
        default=0.95,
        help="Required validation accuracy before copying assets into the app.",
    )
    return parser.parse_args()


def build_validation_dataset(args: argparse.Namespace) -> tuple[tf.data.Dataset, list[str]]:
    val_ds = tf.keras.utils.image_dataset_from_directory(
        args.dataset_dir,
        labels="inferred",
        label_mode="categorical",
        color_mode="rgb",
        batch_size=args.batch_size,
        image_size=IMAGE_SIZE,
        validation_split=args.validation_split,
        subset="validation",
        seed=args.seed,
        shuffle=False,
    )
    return val_ds.prefetch(tf.data.AUTOTUNE), list(val_ds.class_names)


def evaluate_model(args: argparse.Namespace) -> dict[str, float | int | str | bool]:
    if not args.model.exists():
        raise FileNotFoundError(f"Model not found: {args.model}")
    if not args.labels.exists():
        raise FileNotFoundError(f"Labels not found: {args.labels}")

    val_ds, class_names = build_validation_dataset(args)
    model = tf.keras.models.load_model(args.model)
    top_k = min(5, len(class_names))
    top_k_name = f"top_{top_k}_accuracy"
    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=1e-4),
        loss=tf.keras.losses.CategoricalCrossentropy(label_smoothing=0.05),
        metrics=[
            tf.keras.metrics.CategoricalAccuracy(name="accuracy"),
            tf.keras.metrics.TopKCategoricalAccuracy(k=top_k, name=top_k_name),
        ],
    )
    metrics = model.evaluate(val_ds, verbose=1, return_dict=True)
    accuracy = float(metrics["accuracy"])
    passed = accuracy >= args.min_accuracy
    return {
        "model": str(args.model),
        "dataset_dir": str(args.dataset_dir),
        "class_count": len(class_names),
        "validation_split": args.validation_split,
        "accuracy": accuracy,
        "loss": float(metrics["loss"]),
        top_k_name: float(metrics[top_k_name]),
        "min_accuracy": args.min_accuracy,
        "passed": passed,
    }


def write_report(report_path: Path, report: dict[str, float | int | str | bool]) -> None:
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(json.dumps(report, indent=2), encoding="utf-8")


def promote_assets(args: argparse.Namespace) -> None:
    if not args.tflite.exists():
        raise FileNotFoundError(f"TFLite model not found: {args.tflite}")
    args.app_assets_dir.mkdir(parents=True, exist_ok=True)
    shutil.copy2(args.tflite, args.app_assets_dir / "food_cnn.tflite")
    shutil.copy2(args.labels, args.app_assets_dir / "labels.json")


def main() -> None:
    args = parse_args()
    report = evaluate_model(args)
    write_report(args.report, report)

    accuracy = float(report["accuracy"])
    print(f"Validation accuracy: {accuracy:.4%}")
    print(f"Required accuracy: {args.min_accuracy:.4%}")
    print(f"Saved report: {args.report}")

    if report["passed"]:
        promote_assets(args)
        print(f"PASSED: copied TFLite model and labels to {args.app_assets_dir}")
    else:
        print("FAILED: accuracy is below threshold. Mobile assets were not changed.")


if __name__ == "__main__":
    main()
