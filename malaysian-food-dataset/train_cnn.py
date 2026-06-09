"""Train and export the Smartbunda Malaysian food classifier.

Run from this directory:

    python train_cnn.py --dataset-dir dataset --epochs 60

The script writes:
    artifacts/food_cnn.keras
    artifacts/food_cnn.tflite
    artifacts/labels.json
    artifacts/training_history.csv
"""

from __future__ import annotations

import argparse
import csv
import json
import shutil
from pathlib import Path

import tensorflow as tf

from food_cnn import IMAGE_SIZE, build_food_cnn, list_backbones


AUTOTUNE = tf.data.AUTOTUNE
SCRIPT_DIR = Path(__file__).resolve().parent
DEFAULT_DATASET_DIR = SCRIPT_DIR / "dataset"
DEFAULT_OUTPUT_DIR = SCRIPT_DIR / "artifacts"

IMAGE_SUFFIXES = frozenset({".jpg", ".jpeg", ".png", ".webp", ".bmp"})


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Train the Smartbunda food classifier."
    )
    parser.add_argument(
        "--dataset-dir",
        type=Path,
        default=DEFAULT_DATASET_DIR,
        help="Directory containing one subdirectory per food class.",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=DEFAULT_OUTPUT_DIR,
        help="Directory where model artifacts will be written.",
    )
    parser.add_argument("--epochs", type=int, default=60)
    parser.add_argument(
        "--frozen-epochs",
        type=int,
        default=15,
        help="Epochs to train only the classifier head before fine-tuning.",
    )
    parser.add_argument("--batch-size", type=int, default=32)
    parser.add_argument("--learning-rate", type=float, default=1e-3)
    parser.add_argument(
        "--fine-tune-learning-rate",
        type=float,
        default=1e-5,
        help="Lower learning rate used after unfreezing part of the backbone.",
    )
    parser.add_argument(
        "--validation-split",
        type=float,
        default=0.2,
        help="Fraction of images reserved for validation.",
    )
    parser.add_argument("--seed", type=int, default=42)
    parser.add_argument(
        "--dropout",
        type=float,
        default=0.3,
        help="Dropout rate used in the classifier head.",
    )
    parser.add_argument(
        "--backbone",
        choices=list_backbones(),
        default="efficientnet_b0",
        help="Pretrained image backbone used for transfer learning.",
    )
    parser.add_argument(
        "--backbone-weights",
        choices=["imagenet", "none"],
        default="imagenet",
        help="Weight source for the backbone. Use 'none' for offline/random init.",
    )
    parser.add_argument(
        "--unfreeze-layers",
        type=int,
        default=20,
        help="Number of trailing backbone layers to unfreeze for fine-tuning.",
    )
    parser.add_argument(
        "--l2-weight",
        type=float,
        default=1e-4,
        help="L2 regularization strength applied to the dense head.",
    )
    parser.add_argument(
        "--min-images-per-class",
        type=int,
        default=40,
        help="Exclude classes with fewer images than this threshold.",
    )
    parser.add_argument(
        "--no-tflite",
        action="store_true",
        help="Skip TensorFlow Lite export.",
    )
    parser.add_argument(
        "--app-assets-dir",
        type=Path,
        help="Optional Flutter asset directory to receive food_cnn.tflite and labels.json.",
    )
    return parser.parse_args()


def validate_dataset(dataset_dir: Path) -> None:
    if not dataset_dir.exists():
        raise FileNotFoundError(f"Dataset directory not found: {dataset_dir}")
    class_dirs = [path for path in dataset_dir.iterdir() if path.is_dir()]
    if len(class_dirs) < 2:
        raise ValueError("Dataset must contain at least two class directories.")


def resolve_backbone_weights(value: str) -> str | None:
    return None if value == "none" else value


def get_filtered_classes(dataset_dir: Path, min_images: int) -> list[str]:
    """Return sorted class names that meet the minimum image count threshold."""
    eligible: list[tuple[str, int]] = []
    excluded: list[tuple[str, int]] = []
    for d in sorted(dataset_dir.iterdir()):
        if not d.is_dir():
            continue
        count = sum(
            1 for f in d.iterdir()
            if f.is_file() and f.suffix.lower() in IMAGE_SUFFIXES
        )
        (eligible if count >= min_images else excluded).append((d.name, count))

    if excluded:
        print(f"\nExcluding {len(excluded)} classes below {min_images} images:")
        for name, count in excluded:
            print(f"  {count:4d}  {name}")

    print(
        f"\nTraining on {len(eligible)} classes "
        f"(filtered from {len(eligible) + len(excluded)} total).\n"
    )
    return [name for name, _ in eligible]


def _color_jitter(
    images: tf.Tensor, labels: tf.Tensor
) -> tuple[tf.Tensor, tf.Tensor]:
    images = tf.image.random_saturation(images, lower=0.8, upper=1.2)
    images = tf.image.random_hue(images, max_delta=0.04)
    images = tf.clip_by_value(images, 0.0, 255.0)
    return images, labels


def build_datasets(
    dataset_dir: Path,
    batch_size: int,
    validation_split: float,
    seed: int,
    min_images: int = 40,
) -> tuple[tf.data.Dataset, tf.data.Dataset, list[str]]:
    filtered_classes = get_filtered_classes(dataset_dir, min_images)
    if len(filtered_classes) < 2:
        raise ValueError(
            f"Only {len(filtered_classes)} class(es) meet the "
            f"--min-images-per-class={min_images} threshold. "
            "Lower the threshold or add more images."
        )

    common_kwargs = {
        "directory": dataset_dir,
        "labels": "inferred",
        "label_mode": "categorical",
        "color_mode": "rgb",
        "batch_size": batch_size,
        "image_size": IMAGE_SIZE,
        "validation_split": validation_split,
        "class_names": filtered_classes,
        "seed": seed,
    }

    train_ds = tf.keras.utils.image_dataset_from_directory(
        subset="training",
        shuffle=True,
        **common_kwargs,
    )
    val_ds = tf.keras.utils.image_dataset_from_directory(
        subset="validation",
        shuffle=False,
        **common_kwargs,
    )

    class_names = list(train_ds.class_names)
    augmentation = tf.keras.Sequential(
        [
            tf.keras.layers.RandomFlip("horizontal"),
            tf.keras.layers.RandomRotation(0.08),
            tf.keras.layers.RandomZoom(0.15),
            tf.keras.layers.RandomContrast(0.15),
            tf.keras.layers.RandomBrightness(0.2),
            tf.keras.layers.RandomTranslation(0.05, 0.05),
        ],
        name="training_augmentation",
    )
    train_ds = (
        train_ds
        .map(
            lambda images, labels: (augmentation(images, training=True), labels),
            num_parallel_calls=AUTOTUNE,
        )
        .map(_color_jitter, num_parallel_calls=AUTOTUNE)
        .prefetch(AUTOTUNE)
    )
    val_ds = val_ds.prefetch(AUTOTUNE)
    return train_ds, val_ds, class_names


def compute_class_weights(dataset_dir: Path, class_names: list[str]) -> dict[int, float]:
    counts = []
    for class_name in class_names:
        class_dir = dataset_dir / class_name
        image_count = sum(
            1 for path in class_dir.iterdir()
            if path.is_file() and path.suffix.lower() in IMAGE_SUFFIXES
        )
        counts.append(max(image_count, 1))

    total = sum(counts)
    class_count = len(counts)
    return {
        index: total / (class_count * count)
        for index, count in enumerate(counts)
    }


def write_labels(output_dir: Path, class_names: list[str]) -> None:
    labels_path = output_dir / "labels.json"
    labels = [
        {"index": index, "label": label}
        for index, label in enumerate(class_names)
    ]
    labels_path.write_text(json.dumps(labels, indent=2), encoding="utf-8")


def write_history(output_dir: Path, history: tf.keras.callbacks.History) -> None:
    history_path = output_dir / "training_history.csv"
    rows = history.history
    if not rows:
        return

    fieldnames = ["epoch", *rows.keys()]
    with history_path.open("w", newline="", encoding="utf-8") as file:
        writer = csv.DictWriter(file, fieldnames=fieldnames)
        writer.writeheader()
        for epoch in range(len(next(iter(rows.values())))):
            row = {"epoch": epoch + 1}
            row.update({metric: values[epoch] for metric, values in rows.items()})
            writer.writerow(row)


def merge_histories(
    histories: list[tf.keras.callbacks.History],
) -> dict[str, list[float]]:
    merged: dict[str, list[float]] = {}
    for history in histories:
        for metric, values in history.history.items():
            merged.setdefault(metric, []).extend(values)
    return merged


def build_callbacks(checkpoint_path: Path) -> list[tf.keras.callbacks.Callback]:
    return [
        tf.keras.callbacks.ModelCheckpoint(
            filepath=checkpoint_path,
            monitor="val_accuracy",
            mode="max",
            save_best_only=True,
        ),
        tf.keras.callbacks.EarlyStopping(
            monitor="val_accuracy",
            mode="max",
            patience=10,
            restore_best_weights=True,
        ),
        tf.keras.callbacks.ReduceLROnPlateau(
            monitor="val_loss",
            factor=0.5,
            patience=4,
            min_lr=1e-7,
        ),
    ]


def compile_model(
    model: tf.keras.Model,
    *,
    learning_rate: float,
    top_k: int,
    label_smoothing: float = 0.0,
) -> str:
    top_k_metric_name = f"top_{top_k}_accuracy"
    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=learning_rate),
        loss=tf.keras.losses.CategoricalCrossentropy(label_smoothing=label_smoothing),
        metrics=[
            tf.keras.metrics.CategoricalAccuracy(name="accuracy"),
            tf.keras.metrics.TopKCategoricalAccuracy(k=top_k, name=top_k_metric_name),
        ],
    )
    return top_k_metric_name


def configure_fine_tuning(
    backbone: tf.keras.Model,
    *,
    unfreeze_layers: int,
) -> None:
    if unfreeze_layers <= 0:
        backbone.trainable = False
        return

    backbone.trainable = True
    total_layers = len(backbone.layers)
    cutoff = max(total_layers - unfreeze_layers, 0)
    for index, layer in enumerate(backbone.layers):
        layer.trainable = index >= cutoff
        if isinstance(layer, tf.keras.layers.BatchNormalization):
            layer.trainable = False


def export_tflite(model: tf.keras.Model, output_dir: Path) -> None:
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    # Use float16 weights instead of the default INT8 dynamic-range quant.
    # Dynamic-range (INT8) quant causes XNNPACK "failed preconditions" on Android
    # because XNNPACK rejects hybrid INT8-weight + FP32-activation graphs.
    # Float16 keeps weights as FP16 (2x compression, no Android compatibility issues).
    converter.target_spec.supported_types = [tf.float16]
    tflite_model = converter.convert()
    (output_dir / "food_cnn.tflite").write_bytes(tflite_model)


def copy_mobile_assets(
    output_dir: Path,
    app_assets_dir: Path,
    include_tflite: bool,
) -> None:
    app_assets_dir.mkdir(parents=True, exist_ok=True)
    shutil.copy2(output_dir / "labels.json", app_assets_dir / "labels.json")
    if include_tflite:
        shutil.copy2(output_dir / "food_cnn.tflite", app_assets_dir / "food_cnn.tflite")


def main() -> None:
    args = parse_args()
    validate_dataset(args.dataset_dir)
    args.output_dir.mkdir(parents=True, exist_ok=True)

    train_ds, val_ds, class_names = build_datasets(
        dataset_dir=args.dataset_dir,
        batch_size=args.batch_size,
        validation_split=args.validation_split,
        seed=args.seed,
        min_images=args.min_images_per_class,
    )

    model, backbone = build_food_cnn(
        num_classes=len(class_names),
        dropout_rate=args.dropout,
        backbone_name=args.backbone,
        backbone_weights=resolve_backbone_weights(args.backbone_weights),
        l2_weight=args.l2_weight,
    )
    top_k = min(5, len(class_names))
    histories: list[tf.keras.callbacks.History] = []
    checkpoint_path = args.output_dir / "food_cnn_best.keras"
    class_weights = compute_class_weights(args.dataset_dir, class_names)
    frozen_epochs = min(args.frozen_epochs, args.epochs)

    if frozen_epochs > 0:
        print(
            f"Stage 1/2: training classifier head for {frozen_epochs} epochs "
            f"with backbone '{args.backbone}' frozen."
        )
        top_k_metric_name = compile_model(
            model,
            learning_rate=args.learning_rate,
            top_k=top_k,
            label_smoothing=0.0,
        )
        histories.append(
            model.fit(
                train_ds,
                validation_data=val_ds,
                epochs=frozen_epochs,
                callbacks=build_callbacks(checkpoint_path),
                class_weight=class_weights,
            )
        )

    remaining_epochs = max(args.epochs - frozen_epochs, 0)
    if remaining_epochs > 0:
        configure_fine_tuning(backbone, unfreeze_layers=args.unfreeze_layers)
        top_k_metric_name = compile_model(
            model,
            learning_rate=args.fine_tune_learning_rate,
            top_k=top_k,
            label_smoothing=0.02,
        )
        print(
            f"Stage 2/2: fine-tuning last {max(args.unfreeze_layers, 0)} "
            f"backbone layers for {remaining_epochs} epochs."
        )
        histories.append(
            model.fit(
                train_ds,
                validation_data=val_ds,
                epochs=args.epochs,
                initial_epoch=frozen_epochs,
                callbacks=build_callbacks(checkpoint_path),
                class_weight=class_weights,
            )
        )

    model_path = args.output_dir / "food_cnn.keras"
    model.save(model_path)
    write_labels(args.output_dir, class_names)
    combined_history = tf.keras.callbacks.History()
    combined_history.history = merge_histories(histories)
    write_history(args.output_dir, combined_history)
    if not args.no_tflite:
        export_tflite(model, args.output_dir)
    if args.app_assets_dir is not None:
        copy_mobile_assets(
            output_dir=args.output_dir,
            app_assets_dir=args.app_assets_dir,
            include_tflite=not args.no_tflite,
        )

    val_metrics = model.evaluate(val_ds, verbose=0, return_dict=True)
    print(f"\nSaved Keras model  : {model_path}")
    if not args.no_tflite:
        print(f"Saved TFLite model : {args.output_dir / 'food_cnn.tflite'}")
    print(f"Saved labels       : {args.output_dir / 'labels.json'}")
    if args.app_assets_dir is not None:
        print(f"Copied mobile assets to: {args.app_assets_dir}")
    print(
        f"Training config    : backbone={args.backbone}, "
        f"weights={args.backbone_weights}, "
        f"frozen_epochs={frozen_epochs}, "
        f"unfreeze_layers={args.unfreeze_layers}"
    )
    print(
        f"Validation accuracy: {val_metrics['accuracy']:.4f}, "
        f"top-{top_k}: {val_metrics[top_k_metric_name]:.4f}"
    )


if __name__ == "__main__":
    main()
