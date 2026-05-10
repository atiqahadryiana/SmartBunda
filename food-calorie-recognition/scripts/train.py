from __future__ import annotations

import argparse
from pathlib import Path

import matplotlib.pyplot as plt
import tensorflow as tf

from food_calorie.config import TrainingConfig
from food_calorie.data import load_split_image_datasets, save_class_names
from food_calorie.evaluation import evaluate_classifier
from food_calorie.model import build_augmentation, build_food_model, compile_model, unfreeze_for_fine_tuning
from food_calorie.tflite import convert_to_tflite


def parse_args() -> argparse.Namespace:
    defaults = TrainingConfig()
    parser = argparse.ArgumentParser(description="Train food recognition CNN.")
    parser.add_argument("--dataset-dir", type=Path, default=defaults.dataset_dir)
    parser.add_argument("--output-dir", type=Path, default=defaults.output_dir)
    parser.add_argument("--backbone", choices=["mobilenet_v2", "efficientnet_b0"], default=defaults.backbone)
    parser.add_argument("--epochs", type=int, default=defaults.epochs)
    parser.add_argument("--fine-tune-epochs", type=int, default=defaults.fine_tune_epochs)
    parser.add_argument("--batch-size", type=int, default=defaults.batch_size)
    parser.add_argument("--validation-split", type=float, default=defaults.validation_split)
    parser.add_argument("--test-split", type=float, default=defaults.test_split)
    parser.add_argument("--learning-rate", type=float, default=defaults.learning_rate)
    parser.add_argument("--fine-tune-learning-rate", type=float, default=defaults.fine_tune_learning_rate)
    parser.add_argument("--dropout", type=float, default=defaults.dropout)
    parser.add_argument("--unfreeze-layers", type=int, default=defaults.unfreeze_layers)
    parser.add_argument("--seed", type=int, default=defaults.seed)
    parser.add_argument("--min-test-accuracy", type=float, default=defaults.min_test_accuracy)
    parser.add_argument("--skip-tflite", action="store_true")
    return parser.parse_args()


def plot_history(history, fine_tune_history, output_path: Path) -> None:
    accuracy = history.history.get("accuracy", [])
    val_accuracy = history.history.get("val_accuracy", [])
    loss = history.history.get("loss", [])
    val_loss = history.history.get("val_loss", [])

    if fine_tune_history is not None:
        accuracy += fine_tune_history.history.get("accuracy", [])
        val_accuracy += fine_tune_history.history.get("val_accuracy", [])
        loss += fine_tune_history.history.get("loss", [])
        val_loss += fine_tune_history.history.get("val_loss", [])

    epochs = range(1, len(accuracy) + 1)
    plt.figure(figsize=(12, 5))
    plt.subplot(1, 2, 1)
    plt.plot(epochs, accuracy, label="Training accuracy")
    plt.plot(epochs, val_accuracy, label="Validation accuracy")
    plt.xlabel("Epoch")
    plt.ylabel("Accuracy")
    plt.legend()

    plt.subplot(1, 2, 2)
    plt.plot(epochs, loss, label="Training loss")
    plt.plot(epochs, val_loss, label="Validation loss")
    plt.xlabel("Epoch")
    plt.ylabel("Loss")
    plt.legend()

    output_path.parent.mkdir(parents=True, exist_ok=True)
    plt.tight_layout()
    plt.savefig(output_path, dpi=160)
    plt.close()


def main() -> None:
    args = parse_args()
    args.output_dir.mkdir(parents=True, exist_ok=True)

    train_ds, val_ds, test_ds, class_names = load_split_image_datasets(
        args.dataset_dir,
        batch_size=args.batch_size,
        validation_split=args.validation_split,
        test_split=args.test_split,
        seed=args.seed,
    )
    augmentation = build_augmentation()
    train_ds = train_ds.map(
        lambda images, labels: (augmentation(images, training=True), labels),
        num_parallel_calls=tf.data.AUTOTUNE,
    ).prefetch(tf.data.AUTOTUNE)
    val_ds = val_ds.prefetch(tf.data.AUTOTUNE)
    test_ds = test_ds.prefetch(tf.data.AUTOTUNE)
    labels_path = args.output_dir / "class_names.json"
    save_class_names(class_names, labels_path)

    model, base_model = build_food_model(
        num_classes=len(class_names),
        backbone=args.backbone,
        dropout=args.dropout,
    )
    compile_model(model, args.learning_rate)

    callbacks = [
        # Keep the best validation model and stop when improvement stalls.
        # The final saved .h5 remains the requested deployment artifact.
        tf.keras.callbacks.ModelCheckpoint(
            filepath=args.output_dir / "best_food_calorie_model.keras",
            monitor="val_accuracy",
            save_best_only=True,
            mode="max",
        ),
        tf.keras.callbacks.EarlyStopping(
            monitor="val_accuracy",
            patience=5,
            mode="max",
            restore_best_weights=True,
        ),
        tf.keras.callbacks.ReduceLROnPlateau(
            monitor="val_loss",
            factor=0.5,
            patience=3,
            min_lr=1e-6,
        ),
    ]

    history = model.fit(
        train_ds,
        validation_data=val_ds,
        epochs=args.epochs,
        callbacks=callbacks,
    )

    fine_tune_history = None
    if args.fine_tune_epochs > 0:
        unfreeze_for_fine_tuning(base_model, args.unfreeze_layers)
        compile_model(model, args.fine_tune_learning_rate)
        fine_tune_history = model.fit(
            train_ds,
            validation_data=val_ds,
            epochs=args.epochs + args.fine_tune_epochs,
            initial_epoch=args.epochs,
            callbacks=callbacks,
        )

    model_path = args.output_dir / "food_calorie_model.h5"
    model.save(model_path)
    plot_history(history, fine_tune_history, args.output_dir / "training_curves.png")

    val_loss, val_accuracy = model.evaluate(val_ds, verbose=0)
    test_metrics = evaluate_classifier(model, test_ds, class_names, args.output_dir)
    test_accuracy = float(test_metrics["accuracy"])
    if test_accuracy >= args.min_test_accuracy and not args.skip_tflite:
        convert_to_tflite(model_path, args.output_dir / "food_calorie_model.tflite")
        print("Model passed accuracy gate; exported TensorFlow Lite model.")
    else:
        print(
            "Model did not pass accuracy gate or TFLite export was skipped; "
            "mobile integration should wait."
        )
    print(f"Saved model: {model_path}")
    print(f"Saved labels: {labels_path}")
    print(f"Validation accuracy: {val_accuracy:.4f}")
    print(f"Validation loss: {val_loss:.4f}")
    print(f"Test accuracy: {test_accuracy:.4f}")
    print(f"Test precision: {test_metrics['precision']:.4f}")
    print(f"Test recall: {test_metrics['recall']:.4f}")
    print(f"Test F1-score: {test_metrics['f1_score']:.4f}")


if __name__ == "__main__":
    main()
