# SMARTBUNDA Food Recognition and Nutrition Detection

AI food image recognition pipeline for SMARTBUNDA. It predicts food from an
uploaded/captured image, retrieves nutrition values from MyFCD or the offline
cache, and returns JSON that can be consumed by the Flutter mobile app.

References used:

- MyFCD: <https://myfcd.moh.gov.my/>
- TensorFlow: <https://www.tensorflow.org/>

## Workflow

```text
Food image
  -> TensorFlow CNN prediction
  -> Predicted food name
  -> MyFCD/cache nutrition lookup
  -> Calories and nutrients
  -> FastAPI JSON response
  -> SMARTBUNDA mobile integration
```

## Structure

```text
food-calorie-recognition/
  api/main.py                         # FastAPI backend
  data/food_database.json             # offline seed nutrition data
  data/myfcd_cache.sqlite             # generated SQLite cache
  dataset/README.md                   # dataset layout guide
  examples/                           # example JSON/CSV outputs
  mobile/flutter_integration.md       # Flutter notes
  models/                             # generated model artifacts
  outputs/                            # generated reports/exports
  scripts/
    train.py                          # train, evaluate, plot, gated TFLite export
    predict.py                        # image prediction CLI
    predict_regions.py                # experimental multi-food detection
    realtime_camera.py                # webcam prediction demo
    sync_myfcd.py                     # seed/refresh/export nutrition cache
    convert_tflite.py                 # manual TFLite conversion
    evaluate_and_promote.py           # copy assets to SMARTBUNDA only after pass
  src/food_calorie/
    config.py
    data.py                           # train/val/test split and image loading
    database.py                       # SQLite cache and tracking history
    evaluation.py                     # accuracy, precision, recall, F1, confusion matrix
    model.py                          # MobileNetV2/EfficientNetB0 transfer learning
    myfcd.py                          # reusable MyFCD scraper/client
    nutrition.py                      # nutrition response model
    predictor.py                      # CNN + nutrition lookup service
    tflite.py
    vision.py                         # portion/multi-food helper baselines
```

## Setup

Use Python 3.10 or 3.11 for TensorFlow compatibility.

```powershell
cd food-calorie-recognition
python -m venv .venv
.\.venv\Scripts\activate
pip install -r requirements.txt
$env:PYTHONPATH = "src"
```

## Dataset

Place images in class folders:

```text
dataset/
  nasi_lemak/
  burger/
  pizza/
  spaghetti/
  fried_rice/
  salad/
```

The code also supports larger Malaysian food datasets and Food-101 subsets.
Images are decoded as RGB, resized to `224x224`, and fed as `float32`.

## Train and Evaluate

```powershell
python scripts/train.py --dataset-dir dataset --backbone mobilenet_v2 --epochs 20 --fine-tune-epochs 10
```

Alternative backbone:

```powershell
python scripts/train.py --dataset-dir dataset --backbone efficientnet_b0
```

Training includes:

- deterministic train/validation/test split
- random rotation, zoom, horizontal flip, brightness adjustment
- pretrained base model
- global average pooling
- dense layer
- dropout
- softmax classifier
- Adam optimizer
- sparse categorical crossentropy

Generated outputs:

```text
models/food_calorie_model.h5
models/class_names.json
models/best_food_calorie_model.keras
models/training_curves.png
models/evaluation_metrics.json
models/confusion_matrix.png
models/food_calorie_model.tflite       # only when test accuracy passes gate
```

Metrics saved:

- test accuracy
- weighted precision
- weighted recall
- weighted F1-score
- classification report
- confusion matrix

## MyFCD Nutrition Cache

Seed the SQLite cache from the offline JSON and export CSV/JSON:

```powershell
python scripts/sync_myfcd.py --offline-seed-only
```

Refresh specific foods from MyFCD when the public site responds with parseable
nutrition data:

```powershell
python scripts/sync_myfcd.py "nasi lemak" "fried rice"
```

The scraper handles network errors and missing foods by returning cached data
when available. This gives SMARTBUNDA an offline nutrition database even when
MyFCD cannot be reached.

## Predict From Image

```powershell
python scripts/predict.py path\to\food.jpg --offline
```

Example response shape:

```json
{
  "food_name": "Nasi Lemak",
  "confidence": "96%",
  "calories": "644 kcal",
  "protein": "18 g",
  "carbohydrates": "80 g",
  "fat": "28 g",
  "sugar": "5 g",
  "sodium": "800 mg"
}
```

## FastAPI Backend

```powershell
uvicorn api.main:app --host 0.0.0.0 --port 8000
```

Endpoints:

- `GET /health`
- `POST /predict`
- `GET /nutrition/{food_name}`
- `GET /history`
- `GET /daily-calories`

Example:

```powershell
curl -X POST "http://localhost:8000/predict?user_id=test-user&portion_multiplier=1.25" -F "file=@food.jpg"
```

## SMARTBUNDA Mobile Integration Gate

Do not copy the model into the Flutter app unless test accuracy passes:

```powershell
python scripts/evaluate_and_promote.py --min-accuracy 0.95
```

When it passes, the script copies:

```text
assets/ml/food_calorie_model.tflite
assets/ml/class_names.json
assets/ml/myfcd_cache.sqlite
```

If accuracy is below threshold, no mobile assets are changed.

## Bonus Features

- Multi-food baseline: `python scripts/predict_regions.py food.jpg`
- Real-time webcam: `python scripts/realtime_camera.py`
- Portion multiplier: API query parameter `portion_multiplier`
- Nutrition history: SQLite `nutrition_history` table and `/history`
- Daily monitoring: `/daily-calories`
- Firebase-ready: API accepts `user_id`, which can be a Firebase Auth UID

## Production Notes

- The current MyFCD public pages may not expose all values in static HTML, so
  keep the SQLite cache as the reliable offline source.
- Use a held-out test set before mobile promotion.
- For accurate multi-food detection, replace OpenCV contour regions with a
  trained object detector.
- For accurate portion size, use user confirmation, depth sensing, or a known
  reference object.
- Version the model, labels, and nutrition database together.
