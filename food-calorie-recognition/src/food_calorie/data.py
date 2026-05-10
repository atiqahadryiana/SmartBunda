"""Dataset loading and food metadata helpers."""

from __future__ import annotations

import json
import random
from pathlib import Path
from typing import Any

import tensorflow as tf

from food_calorie.config import IMAGE_SIZE, normalize_label


AUTOTUNE = tf.data.AUTOTUNE


def validate_dataset(dataset_dir: Path) -> None:
    """Fail early when the image folder structure is not trainable."""

    if not dataset_dir.exists():
        raise FileNotFoundError(f"Dataset directory not found: {dataset_dir}")
    class_dirs = [path for path in dataset_dir.iterdir() if path.is_dir()]
    if len(class_dirs) < 2:
        raise ValueError(
            "Dataset must contain at least two class folders, for example "
            "dataset/pizza and dataset/burger."
        )


def load_image_datasets(
    dataset_dir: Path,
    *,
    image_size: tuple[int, int] = IMAGE_SIZE,
    batch_size: int = 32,
    validation_split: float = 0.2,
    seed: int = 42,
) -> tuple[tf.data.Dataset, tf.data.Dataset, list[str]]:
    """Create training and validation datasets from a folder-per-class dataset."""

    validate_dataset(dataset_dir)
    common = {
        "directory": dataset_dir,
        "labels": "inferred",
        "label_mode": "int",
        "image_size": image_size,
        "batch_size": batch_size,
        "validation_split": validation_split,
        "seed": seed,
    }
    train_ds = tf.keras.utils.image_dataset_from_directory(
        subset="training",
        shuffle=True,
        **common,
    )
    val_ds = tf.keras.utils.image_dataset_from_directory(
        subset="validation",
        shuffle=False,
        **common,
    )

    class_names = [normalize_label(name) for name in train_ds.class_names]
    return train_ds, val_ds, class_names


def _image_files(dataset_dir: Path) -> tuple[list[Path], list[int], list[str]]:
    class_dirs = sorted(path for path in dataset_dir.iterdir() if path.is_dir())
    class_names = [normalize_label(path.name) for path in class_dirs]
    extensions = {".jpg", ".jpeg", ".png", ".bmp", ".webp"}
    paths: list[Path] = []
    labels: list[int] = []
    for index, class_dir in enumerate(class_dirs):
        for path in sorted(class_dir.rglob("*")):
            if path.is_file() and path.suffix.lower() in extensions:
                paths.append(path)
                labels.append(index)
    if not paths:
        raise ValueError(f"No image files found in {dataset_dir}")
    return paths, labels, class_names


def _dataset_from_paths(
    paths: list[Path],
    labels: list[int],
    *,
    image_size: tuple[int, int],
    batch_size: int,
    shuffle: bool,
    seed: int,
) -> tf.data.Dataset:
    path_values = [str(path) for path in paths]
    ds = tf.data.Dataset.from_tensor_slices((path_values, labels))
    if shuffle:
        ds = ds.shuffle(buffer_size=len(path_values), seed=seed, reshuffle_each_iteration=True)

    def load_image(path: tf.Tensor, label: tf.Tensor) -> tuple[tf.Tensor, tf.Tensor]:
        image_bytes = tf.io.read_file(path)
        image = tf.io.decode_image(image_bytes, channels=3, expand_animations=False)
        image = tf.image.resize(image, image_size)
        image = tf.cast(image, tf.float32)
        return image, label

    return ds.map(load_image, num_parallel_calls=AUTOTUNE).batch(batch_size)


def load_split_image_datasets(
    dataset_dir: Path,
    *,
    image_size: tuple[int, int] = IMAGE_SIZE,
    batch_size: int = 32,
    validation_split: float = 0.2,
    test_split: float = 0.1,
    seed: int = 42,
) -> tuple[tf.data.Dataset, tf.data.Dataset, tf.data.Dataset, list[str]]:
    """Create deterministic training, validation, and test datasets.

    The split is stratified by class so every class with enough images appears
    in all three subsets. This avoids evaluating on images seen during training.
    """

    validate_dataset(dataset_dir)
    paths, labels, class_names = _image_files(dataset_dir)
    rng = random.Random(seed)
    by_class: dict[int, list[Path]] = {}
    for path, label in zip(paths, labels, strict=True):
        by_class.setdefault(label, []).append(path)

    split_paths = {"train": [], "val": [], "test": []}
    split_labels = {"train": [], "val": [], "test": []}
    for label, class_paths in by_class.items():
        rng.shuffle(class_paths)
        total = len(class_paths)
        test_count = max(1, round(total * test_split)) if total >= 3 else 0
        val_count = max(1, round(total * validation_split)) if total - test_count >= 2 else 0
        test_items = class_paths[:test_count]
        val_items = class_paths[test_count : test_count + val_count]
        train_items = class_paths[test_count + val_count :]
        for split_name, items in (
            ("train", train_items),
            ("val", val_items),
            ("test", test_items),
        ):
            split_paths[split_name].extend(items)
            split_labels[split_name].extend([label] * len(items))

    train_ds = _dataset_from_paths(
        split_paths["train"],
        split_labels["train"],
        image_size=image_size,
        batch_size=batch_size,
        shuffle=True,
        seed=seed,
    )
    val_ds = _dataset_from_paths(
        split_paths["val"],
        split_labels["val"],
        image_size=image_size,
        batch_size=batch_size,
        shuffle=False,
        seed=seed,
    )
    test_ds = _dataset_from_paths(
        split_paths["test"],
        split_labels["test"],
        image_size=image_size,
        batch_size=batch_size,
        shuffle=False,
        seed=seed,
    )
    return train_ds, val_ds, test_ds, class_names


def save_class_names(class_names: list[str], output_path: Path) -> None:
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(class_names, indent=2), encoding="utf-8")


def load_class_names(path: Path) -> list[str]:
    return json.loads(path.read_text(encoding="utf-8"))


def load_food_database(path: Path) -> dict[str, dict[str, Any]]:
    """Load calories and optional macros keyed by normalized food label."""

    raw = json.loads(path.read_text(encoding="utf-8"))
    return {normalize_label(key): value for key, value in raw.items()}


def food_metadata(label: str, database: dict[str, dict[str, Any]]) -> dict[str, Any]:
    default = {
        "calories": None,
        "protein_g": None,
        "carbs_g": None,
        "fat_g": None,
        "serving": "per serving",
    }
    return {**default, **database.get(normalize_label(label), {})}
