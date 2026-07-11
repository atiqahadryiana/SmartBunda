"""Re-export the trained Keras model to TFLite with Flex delegate support.

Run this AFTER installing TensorFlow (see setup instructions below).
Place the Keras model from training at: artifacts/food_cnn.keras

Usage:
    python re_export_tflite.py

The script writes:
    artifacts/food_cnn.tflite  (with SELECT_TF_OPS / Flex delegate support)
"""

from __future__ import annotations

from pathlib import Path

import tensorflow as tf

SCRIPT_DIR = Path(__file__).resolve().parent
DEFAULT_KERAS_PATH = SCRIPT_DIR / "artifacts" / "food_cnn.keras"
DEFAULT_TFLITE_PATH = SCRIPT_DIR / "artifacts" / "food_cnn.tflite"
ASSETS_DIR = SCRIPT_DIR.parent / "assets" / "ml"


def export_tflite(
    keras_path: Path,
    output_path: Path,
    copy_to_assets: bool = True,
) -> None:
    print(f"Loading Keras model from: {keras_path}")
    model = tf.keras.models.load_model(keras_path)

    converter = tf.lite.TFLiteConverter.from_keras_model(model)

    # --- REQUIRED FIX for "failed precondition" error ---
    # Enable SELECT_TF_OPS (Flex delegate) so ops like BatchNormalization,
    # which are not natively supported in TFLite, are delegated to TF.
    converter.target_spec.supported_ops = [
        tf.lite.OpsSet.TFLITE_BUILTINS,
        tf.lite.OpsSet.SELECT_TF_OPS,
    ]

    # Float16 weight quantization (2x compression, no quality loss)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    converter.target_spec.supported_types = [tf.float16]

    print("Converting to TFLite (this may take a moment)...")
    tflite_model = converter.convert()

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_bytes(tflite_model)
    print(f"TFLite model saved: {output_path} ({len(tflite_model)} bytes)")

    if copy_to_assets:
        ASSETS_DIR.mkdir(parents=True, exist_ok=True)
        dest = ASSETS_DIR / "food_cnn.tflite"
        dest.write_bytes(tflite_model)
        print(f"Copied to Flutter assets: {dest}")


def main() -> None:
    keras_path = DEFAULT_KERAS_PATH
    if not keras_path.exists():
        print(f"ERROR: Keras model not found at {keras_path}")
        print()
        print("To train the model first, run:")
        print("    python train_cnn.py --dataset-dir dataset --epochs 60")
        print()
        print("Then re-run this script.")
        return

    export_tflite(keras_path, DEFAULT_TFLITE_PATH)


if __name__ == "__main__":
    main()
