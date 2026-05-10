"""Shared configuration values for training and inference."""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[2]
IMAGE_SIZE = (224, 224)
DEFAULT_CLASSES = (
    "pizza",
    "burger",
    "salad",
    "nasi_lemak",
    "fried_rice",
    "spaghetti",
)


@dataclass(frozen=True)
class TrainingConfig:
    dataset_dir: Path = PROJECT_ROOT / "dataset"
    output_dir: Path = PROJECT_ROOT / "models"
    model_name: str = "food_calorie_model.h5"
    backbone: str = "mobilenet_v2"
    image_size: tuple[int, int] = IMAGE_SIZE
    batch_size: int = 32
    epochs: int = 20
    fine_tune_epochs: int = 10
    validation_split: float = 0.2
    test_split: float = 0.1
    seed: int = 42
    learning_rate: float = 1e-3
    fine_tune_learning_rate: float = 1e-5
    dropout: float = 0.35
    unfreeze_layers: int = 30
    min_test_accuracy: float = 0.95


def normalize_label(label: str) -> str:
    """Use one stable label format across folders, models, and calorie JSON."""

    return label.strip().lower().replace(" ", "_").replace("-", "_")
