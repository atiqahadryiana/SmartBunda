"""Nutrition data model and formatting helpers."""

from __future__ import annotations

from dataclasses import asdict, dataclass

from food_calorie.config import normalize_label


@dataclass(frozen=True)
class NutritionInfo:
    food_name: str
    calories: float | None = None
    protein: float | None = None
    carbohydrates: float | None = None
    fat: float | None = None
    sugar: float | None = None
    sodium: float | None = None
    serving_size: str = "per 100g"
    source: str = "offline"

    @property
    def key(self) -> str:
        return normalize_label(self.food_name)

    def to_dict(self) -> dict[str, str | float | None]:
        return asdict(self)

    def to_api_dict(self) -> dict[str, str]:
        return {
            "food_name": self.food_name,
            "calories": _format(self.calories, "kcal"),
            "protein": _format(self.protein, "g"),
            "carbohydrates": _format(self.carbohydrates, "g"),
            "fat": _format(self.fat, "g"),
            "sugar": _format(self.sugar, "g"),
            "sodium": _format(self.sodium, "mg"),
            "serving_size": self.serving_size,
            "source": self.source,
        }


def _format(value: float | None, unit: str) -> str:
    if value is None:
        return "unknown"
    if float(value).is_integer():
        return f"{int(value)} {unit}"
    return f"{value:.2f} {unit}"
