"""Model evaluation metrics and plots."""

from __future__ import annotations

import json
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import tensorflow as tf
from sklearn.metrics import (
    accuracy_score,
    classification_report,
    confusion_matrix,
    precision_recall_fscore_support,
)


def evaluate_classifier(
    model: tf.keras.Model,
    test_ds: tf.data.Dataset,
    class_names: list[str],
    output_dir: Path,
) -> dict[str, object]:
    y_true: list[int] = []
    y_pred: list[int] = []
    for images, labels in test_ds:
        probabilities = model.predict(images, verbose=0)
        y_true.extend(labels.numpy().astype(int).tolist())
        y_pred.extend(np.argmax(probabilities, axis=1).astype(int).tolist())

    precision, recall, f1, _ = precision_recall_fscore_support(
        y_true,
        y_pred,
        average="weighted",
        zero_division=0,
    )
    accuracy = accuracy_score(y_true, y_pred)
    report = classification_report(
        y_true,
        y_pred,
        target_names=class_names,
        zero_division=0,
        output_dict=True,
    )
    matrix = confusion_matrix(y_true, y_pred).tolist()
    metrics: dict[str, object] = {
        "accuracy": float(accuracy),
        "precision": float(precision),
        "recall": float(recall),
        "f1_score": float(f1),
        "classification_report": report,
        "confusion_matrix": matrix,
    }

    output_dir.mkdir(parents=True, exist_ok=True)
    (output_dir / "evaluation_metrics.json").write_text(
        json.dumps(metrics, indent=2),
        encoding="utf-8",
    )
    plot_confusion_matrix(matrix, class_names, output_dir / "confusion_matrix.png")
    return metrics


def plot_confusion_matrix(
    matrix: list[list[int]],
    class_names: list[str],
    output_path: Path,
) -> None:
    plt.figure(figsize=(max(8, len(class_names) * 0.35), max(6, len(class_names) * 0.35)))
    plt.imshow(matrix, interpolation="nearest", cmap="Blues")
    plt.title("Confusion Matrix")
    plt.colorbar()
    tick_marks = np.arange(len(class_names))
    plt.xticks(tick_marks, class_names, rotation=90, fontsize=6)
    plt.yticks(tick_marks, class_names, fontsize=6)
    plt.ylabel("True label")
    plt.xlabel("Predicted label")
    plt.tight_layout()
    plt.savefig(output_path, dpi=180)
    plt.close()
