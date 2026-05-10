"""SQLite/CSV/JSON cache for MyFCD nutrition data and tracking history."""

from __future__ import annotations

import csv
import json
import sqlite3
from pathlib import Path

from food_calorie.config import normalize_label
from food_calorie.nutrition import NutritionInfo


SCHEMA = """
CREATE TABLE IF NOT EXISTS nutrition (
    food_key TEXT PRIMARY KEY,
    food_name TEXT NOT NULL,
    calories REAL,
    protein REAL,
    carbohydrates REAL,
    fat REAL,
    sugar REAL,
    sodium REAL,
    serving_size TEXT,
    source TEXT,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS nutrition_history (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id TEXT,
    food_key TEXT NOT NULL,
    confidence REAL,
    portion_multiplier REAL DEFAULT 1.0,
    calories REAL,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
);
"""


class NutritionDatabase:
    def __init__(self, path: Path) -> None:
        self.path = path
        self.path.parent.mkdir(parents=True, exist_ok=True)
        with self._connect() as conn:
            conn.executescript(SCHEMA)

    def _connect(self) -> sqlite3.Connection:
        conn = sqlite3.connect(self.path)
        conn.row_factory = sqlite3.Row
        return conn

    def get(self, food_name: str) -> NutritionInfo | None:
        key = normalize_label(food_name)
        with self._connect() as conn:
            row = conn.execute("SELECT * FROM nutrition WHERE food_key = ?", (key,)).fetchone()
        return self._row_to_nutrition(row) if row else None

    def upsert(self, info: NutritionInfo) -> None:
        with self._connect() as conn:
            conn.execute(
                """
                INSERT INTO nutrition (
                    food_key, food_name, calories, protein, carbohydrates,
                    fat, sugar, sodium, serving_size, source, updated_at
                )
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
                ON CONFLICT(food_key) DO UPDATE SET
                    food_name=excluded.food_name,
                    calories=excluded.calories,
                    protein=excluded.protein,
                    carbohydrates=excluded.carbohydrates,
                    fat=excluded.fat,
                    sugar=excluded.sugar,
                    sodium=excluded.sodium,
                    serving_size=excluded.serving_size,
                    source=excluded.source,
                    updated_at=CURRENT_TIMESTAMP
                """,
                (
                    info.key,
                    info.food_name,
                    info.calories,
                    info.protein,
                    info.carbohydrates,
                    info.fat,
                    info.sugar,
                    info.sodium,
                    info.serving_size,
                    info.source,
                ),
            )

    def record_history(
        self,
        *,
        food_name: str,
        confidence: float,
        calories: float | None,
        portion_multiplier: float = 1.0,
        user_id: str | None = None,
    ) -> None:
        with self._connect() as conn:
            conn.execute(
                """
                INSERT INTO nutrition_history (
                    user_id, food_key, confidence, portion_multiplier, calories
                )
                VALUES (?, ?, ?, ?, ?)
                """,
                (user_id, normalize_label(food_name), confidence, portion_multiplier, calories),
            )

    def export_json(self, path: Path) -> None:
        rows = self._all_rows()
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(rows, indent=2), encoding="utf-8")

    def export_csv(self, path: Path) -> None:
        rows = self._all_rows()
        path.parent.mkdir(parents=True, exist_ok=True)
        with path.open("w", newline="", encoding="utf-8") as file:
            fieldnames = [
                "food_key",
                "food_name",
                "calories",
                "protein",
                "carbohydrates",
                "fat",
                "sugar",
                "sodium",
                "serving_size",
                "source",
                "updated_at",
            ]
            writer = csv.DictWriter(file, fieldnames=fieldnames)
            writer.writeheader()
            writer.writerows(rows)

    def recent_history(self, *, user_id: str | None = None, limit: int = 50) -> list[dict[str, object]]:
        query = """
            SELECT h.*, n.food_name
            FROM nutrition_history h
            LEFT JOIN nutrition n ON n.food_key = h.food_key
        """
        params: list[object] = []
        if user_id:
            query += " WHERE h.user_id = ?"
            params.append(user_id)
        query += " ORDER BY h.created_at DESC LIMIT ?"
        params.append(limit)
        with self._connect() as conn:
            rows = conn.execute(query, params).fetchall()
        return [dict(row) for row in rows]

    def daily_calories(self, *, user_id: str | None = None) -> list[dict[str, object]]:
        query = """
            SELECT date(created_at) AS date, SUM(calories) AS calories
            FROM nutrition_history
        """
        params: list[object] = []
        if user_id:
            query += " WHERE user_id = ?"
            params.append(user_id)
        query += " GROUP BY date(created_at) ORDER BY date DESC"
        with self._connect() as conn:
            rows = conn.execute(query, params).fetchall()
        return [dict(row) for row in rows]

    def _all_rows(self) -> list[dict[str, object]]:
        with self._connect() as conn:
            rows = conn.execute("SELECT * FROM nutrition ORDER BY food_name").fetchall()
        return [dict(row) for row in rows]

    @staticmethod
    def _row_to_nutrition(row: sqlite3.Row) -> NutritionInfo:
        return NutritionInfo(
            food_name=row["food_name"],
            calories=row["calories"],
            protein=row["protein"],
            carbohydrates=row["carbohydrates"],
            fat=row["fat"],
            sugar=row["sugar"],
            sodium=row["sodium"],
            serving_size=row["serving_size"] or "per 100g",
            source=row["source"] or "cache",
        )
