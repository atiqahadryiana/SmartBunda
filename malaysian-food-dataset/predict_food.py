"""Run inference with a trained Smartbunda food CNN model."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

import numpy as np
import tensorflow as tf

from food_cnn import IMAGE_SIZE


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Predict food class from an image.")
    parser.add_argument("image", type=Path, help="Image path to classify.")
    parser.add_argument(
        "--model",
        type=Path,
        default=Path("artifacts/food_cnn.keras"),
        help="Trained Keras model path.",
    )
    parser.add_argument(
        "--labels",
        type=Path,
        default=Path("artifacts/labels.json"),
        help="Labels JSON written by train_cnn.py.",
    )
    parser.add_argument("--top-k", type=int, default=5)
    return parser.parse_args()


def load_labels(labels_path: Path) -> list[str]:
    labels = json.loads(labels_path.read_text(encoding="utf-8"))
    return [item["label"] for item in sorted(labels, key=lambda item: item["index"])]


def load_image(image_path: Path) -> np.ndarray:
    image = tf.keras.utils.load_img(image_path, target_size=IMAGE_SIZE)
    image_array = tf.keras.utils.img_to_array(image)
    return np.expand_dims(image_array, axis=0)


def main() -> None:
    args = parse_args()
    model = tf.keras.models.load_model(args.model)
    labels = load_labels(args.labels)
    image = load_image(args.image)

    probabilities = model.predict(image, verbose=0)[0]
    top_indices = probabilities.argsort()[-args.top_k:][::-1]

    for index in top_indices:
        print(f"{labels[index]}: {probabilities[index]:.4f}")


if __name__ == "__main__":
    main()
