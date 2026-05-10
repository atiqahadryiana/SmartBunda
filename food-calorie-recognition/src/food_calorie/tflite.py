"""TensorFlow Lite conversion helpers."""

from __future__ import annotations

from pathlib import Path

import tensorflow as tf


def convert_to_tflite(
    model_path: Path,
    output_path: Path,
    *,
    quantize: bool = True,
) -> Path:
    model = tf.keras.models.load_model(model_path)
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    if quantize:
        # Dynamic range quantization reduces file size and usually improves mobile CPU speed.
        converter.optimizations = [tf.lite.Optimize.DEFAULT]
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_bytes(converter.convert())
    return output_path
