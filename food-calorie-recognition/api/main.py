from __future__ import annotations

import tempfile
from pathlib import Path

from fastapi import FastAPI, File, HTTPException, UploadFile

from food_calorie.config import PROJECT_ROOT
from food_calorie.database import NutritionDatabase
from food_calorie.myfcd import MyFCDClient, seed_database_from_json
from food_calorie.predictor import FoodPredictor


MODEL_PATH = PROJECT_ROOT / "models" / "food_calorie_model.h5"
LABELS_PATH = PROJECT_ROOT / "models" / "class_names.json"
SEED_FOOD_DB_PATH = PROJECT_ROOT / "data" / "food_database.json"
NUTRITION_DB_PATH = PROJECT_ROOT / "data" / "myfcd_cache.sqlite"

app = FastAPI(title="SMARTBUNDA Food Recognition and Nutrition API")
predictor: FoodPredictor | None = None
nutrition_db = NutritionDatabase(NUTRITION_DB_PATH)
myfcd = MyFCDClient(database=nutrition_db)


@app.on_event("startup")
def load_predictor() -> None:
    global predictor
    if SEED_FOOD_DB_PATH.exists():
        seed_database_from_json(nutrition_db, SEED_FOOD_DB_PATH)
    if MODEL_PATH.exists() and LABELS_PATH.exists():
        predictor = FoodPredictor(
            MODEL_PATH,
            LABELS_PATH,
            NUTRITION_DB_PATH,
            seed_food_db_path=SEED_FOOD_DB_PATH,
        )


@app.get("/health")
def health() -> dict[str, bool | str]:
    return {
        "ok": True,
        "model_loaded": predictor is not None,
        "model_path": str(MODEL_PATH),
    }


@app.get("/nutrition/{food_name}")
def nutrition(food_name: str, refresh: bool = False) -> dict[str, object]:
    result = myfcd.lookup(food_name, refresh=refresh)
    if result is None:
        raise HTTPException(status_code=404, detail="Nutrition data not found.")
    return result.to_api_dict()


@app.post("/predict")
async def predict(
    file: UploadFile = File(...),
    user_id: str | None = None,
    portion_multiplier: float = 1.0,
) -> dict[str, object]:
    if predictor is None:
        raise HTTPException(
            status_code=503,
            detail="Model is not loaded. Train the model before using /predict.",
        )
    suffix = Path(file.filename or "upload.jpg").suffix or ".jpg"
    with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as tmp:
        tmp.write(await file.read())
        tmp_path = Path(tmp.name)

    try:
        result = predictor.predict_file(tmp_path)
    finally:
        tmp_path.unlink(missing_ok=True)

    nutrition_db.record_history(
        food_name=result.food_name,
        confidence=result.confidence,
        calories=(result.calories or 0) * portion_multiplier,
        portion_multiplier=portion_multiplier,
        user_id=user_id,
    )
    response = result.to_api_dict()
    response["portion_multiplier"] = portion_multiplier
    response["estimated_total_calories"] = f"{((result.calories or 0) * portion_multiplier):.0f} kcal"
    return response


@app.get("/history")
def history(user_id: str | None = None, limit: int = 50) -> list[dict[str, object]]:
    return nutrition_db.recent_history(user_id=user_id, limit=limit)


@app.get("/daily-calories")
def daily_calories(user_id: str | None = None) -> list[dict[str, object]]:
    return nutrition_db.daily_calories(user_id=user_id)
