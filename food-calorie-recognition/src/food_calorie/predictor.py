"""Reusable prediction service for scripts and the API."""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

import cv2
import numpy as np
import tensorflow as tf

from food_calorie.config import IMAGE_SIZE, normalize_label
from food_calorie.data import load_class_names
from food_calorie.database import NutritionDatabase
from food_calorie.myfcd import MyFCDClient
from food_calorie.nutrition import NutritionInfo


@dataclass(frozen=True)
class Prediction:
    food_name: str
    confidence: float
    nutrition: NutritionInfo | None

    @property
    def calories(self) -> float | None:
        return self.nutrition.calories if self.nutrition else None

    def to_api_dict(self) -> dict[str, object]:
        nutrition = self.nutrition.to_api_dict() if self.nutrition else {}
        return {
            "food_name": self.food_name.replace("_", " ").title(),
            "confidence": f"{self.confidence * 100:.0f}%",
            "confidence_score": round(self.confidence * 100, 2),
            "calories": nutrition.get("calories", "unknown"),
            "protein": nutrition.get("protein", "unknown"),
            "carbohydrates": nutrition.get("carbohydrates", "unknown"),
            "fat": nutrition.get("fat", "unknown"),
            "sugar": nutrition.get("sugar", "unknown"),
            "sodium": nutrition.get("sodium", "unknown"),
            "nutrition": nutrition,
        }


def read_image_rgb(image_path: Path, image_size: tuple[int, int] = IMAGE_SIZE) -> np.ndarray:
    image = cv2.imread(str(image_path))
    if image is None:
        raise ValueError(f"Could not read image: {image_path}")
    image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
    image = cv2.resize(image, image_size, interpolation=cv2.INTER_AREA)
    return image.astype(np.float32)


class FoodPredictor:
    def __init__(
        self,
        model_path: Path,
        labels_path: Path,
        nutrition_db_path: Path,
        seed_food_db_path: Path | None = None,
        image_size: tuple[int, int] = IMAGE_SIZE,
        enable_live_myfcd: bool = True,
    ) -> None:
        self.model = tf.keras.models.load_model(model_path)
        self.labels = [normalize_label(label) for label in load_class_names(labels_path)]
        self.nutrition_db = NutritionDatabase(nutrition_db_path)
        if seed_food_db_path is not None and seed_food_db_path.exists():
            from food_calorie.myfcd import seed_database_from_json

            seed_database_from_json(self.nutrition_db, seed_food_db_path)
        self.myfcd = (
            MyFCDClient(database=self.nutrition_db) if enable_live_myfcd else None
        )
        self.image_size = image_size

    def predict_array(self, image_rgb: np.ndarray) -> Prediction:
        image = cv2.resize(image_rgb, self.image_size, interpolation=cv2.INTER_AREA)
        batch = np.expand_dims(image.astype(np.float32), axis=0)
        probabilities = self.model.predict(batch, verbose=0)[0]
        class_index = int(np.argmax(probabilities))
        label = self.labels[class_index]
        confidence = float(probabilities[class_index])
        nutrition = (
            self.myfcd.lookup(label) if self.myfcd else self.nutrition_db.get(label)
        )
        return Prediction(
            food_name=label,
            confidence=confidence,
            nutrition=nutrition,
        )

    def predict_file(self, image_path: Path) -> Prediction:
        return self.predict_array(read_image_rgb(image_path, self.image_size))
