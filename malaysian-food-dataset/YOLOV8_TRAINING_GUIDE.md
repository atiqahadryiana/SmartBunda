# SmartBunda YOLOv8 Training Guide (on-device meal scanner)

This guide produces the **on-device food model** the SmartBunda app loads as the
first stage of its meal scanner. The app runs it FIRST (instant, offline, free);
when it is not confident, the scan falls through to the Gemini cloud scanners.

## What we train and why

We train **YOLOv8n-cls** (classification), **not** YOLOv8 detection.

| | YOLOv8n-cls (what we use) | YOLOv8 detection |
|---|---|---|
| Output | one dominant dish per photo | bounding boxes, multi-food |
| Labels needed | **folder-per-class only** (we have this) | hand-drawn bbox annotations (we don't) |
| Data ready? | ✅ 172 classes, ~16.6k images in `dataset/` | ❌ would need Roboflow/LabelImg annotation |
| Size | ~6 MB TFLite | ~6–12 MB TFLite |

Our dataset is organised as `dataset/<class_name>/<images>` — that's exactly the
input YOLOv8n-cls needs, so **no bounding-box annotation is required**. True
multi-food photos (a plate with several distinct dishes) are intentionally left
to the **Gemini cloud scanners**, which already handle them with the multi-select
verify checklist. The on-device model's job is the fast, common, single-dish case.

The whole pipeline is in **`yolo_pipeline.py`**. The Flutter side is already wired
(`lib/services/yolo_food_classifier_service.dart`) and expects exactly two assets:

```
assets/ml/food_cnn.tflite   # YOLOv8n-cls, input [1,224,224,3] float32 (0–1)
assets/ml/labels.json       # [{ "index": 0, "label": "nasi lemak" }, …]
```

Until those exist the app builds and runs fine — it just skips straight to Gemini.

---

## Recommended: train on Google Colab (free GPU)

CPU training on this laptop would take many hours. Colab's free T4 GPU does the
full run in ~20–40 min.

### Step 1 — Zip the dataset and upload to Google Drive

On your machine, zip the `dataset/` folder (the 172 class subfolders), then upload
`dataset.zip` to your Google Drive (e.g. `MyDrive/smartbunda/dataset.zip`).

```powershell
# from malaysian-food-dataset/
Compress-Archive -Path dataset -DestinationPath dataset.zip
```

> Tip: the zip is large. If Drive upload is slow, you can instead point the
> notebook at a Roboflow/Kaggle copy — but the local zip is the simplest.

### Step 2 — New Colab notebook → set Runtime → GPU

`Runtime ▸ Change runtime type ▸ T4 GPU`.

### Step 3 — Paste and run these cells

```python
# Cell 1 — install + mount Drive
!pip -q install ultralytics
from google.colab import drive
drive.mount('/content/drive')

# Cell 2 — unzip the dataset
!cp "/content/drive/MyDrive/smartbunda/dataset.zip" /content/dataset.zip
!cd /content && unzip -q dataset.zip       # → /content/dataset/<class>/<imgs>

# Cell 3 — prepare the YOLO-cls split (train/val), min 40 imgs/class
#   (this is exactly `yolo_pipeline.py prepare`, inlined for Colab)
import json, random, shutil
from pathlib import Path
SRC = Path('/content/dataset'); OUT = Path('/content/yolo_cls')
EXT = {'.jpg','.jpeg','.png','.webp','.bmp'}
classes = []
for d in sorted(p for p in SRC.iterdir() if p.is_dir()):
    imgs = [p for p in d.iterdir() if p.suffix.lower() in EXT]
    if len(imgs) < 40:
        continue
    classes.append(d.name); random.shuffle(imgs)
    k = max(1, int(len(imgs)*0.15))
    for sub, group in [('val', imgs[:k]), ('train', imgs[k:])]:
        dst = OUT/sub/d.name; dst.mkdir(parents=True, exist_ok=True)
        for p in group: shutil.copy2(p, dst/p.name)
print('classes:', len(classes))

# Cell 4 — train YOLOv8n-cls (imgsz 224 = the app's input size)
#   ⚠️ Run this to COMPLETION before Cell 5. It prints a metrics table and
#   creates best.pt when done (~20–40 min on T4). Don't skip ahead.
from ultralytics import YOLO
model = YOLO('yolov8n-cls.pt')             # pretrained on ImageNet
model.train(data='/content/yolo_cls', epochs=100, imgsz=224,
            batch=64, device=0, patience=15,
            fliplr=0.5, hsv_h=0.015, hsv_s=0.7, hsv_v=0.4,
            degrees=10, translate=0.1, scale=0.5,
            project='runs/classify', name='smartbunda_cls')

# Cell 5 — export to FP16 TFLite + write labels.json + copy both to Drive.
#   Auto-finds the newest best.pt (handles re-runs that create _cls2, _cls3, …)
#   so a wrong hardcoded path can't FileNotFoundError on you.
import glob, json, shutil, os
from pathlib import Path
from ultralytics import YOLO

cands = glob.glob('runs/classify/**/weights/best.pt', recursive=True)
assert cands, "No best.pt found — run the TRAINING cell (Cell 4) to completion first."
best = max(cands, key=os.path.getmtime)
print("Using weights:", best)

# Export to FP16 TFLite (half=True avoids the XNNPACK INT8 issue)
YOLO(best).export(format='tflite', imgsz=224, half=True, simplify=True)

# labels.json in the shape the Flutter service expects ([{index,label}, …])
m = YOLO(best)
labels = [{'index': i, 'label': n} for i, n in m.names.items()]
Path('/content/labels.json').write_text(
    json.dumps(labels, indent=2, ensure_ascii=False))

# Locate the exported tflite (export dir sits beside best.pt)
wdir = str(Path(best).parent)
tfl = (glob.glob(f'{wdir}/**/*float16.tflite', recursive=True)
       or glob.glob(f'{wdir}/**/*.tflite', recursive=True))
assert tfl, "Export produced no .tflite — check the export output above."
print("Exported tflite:", tfl[0])

# Copy both to Drive for download
os.makedirs('/content/drive/MyDrive/smartbunda', exist_ok=True)
shutil.copy2(tfl[0], '/content/drive/MyDrive/smartbunda/food_cnn.tflite')
shutil.copy2('/content/labels.json', '/content/drive/MyDrive/smartbunda/labels.json')
print(f'Done → MyDrive/smartbunda/food_cnn.tflite ({len(labels)} classes) + labels.json')
```

### Step 4 — Drop the two files into the app

Download `food_cnn.tflite` and `labels.json` from your Drive and place them at:

```
Smartbunda/assets/ml/food_cnn.tflite
Smartbunda/assets/ml/labels.json     # replaces the empty placeholder []
```

Then:

```powershell
flutter pub get
flutter run        # scan a meal — the on-device model now runs first
```

That's it. No Flutter code changes are needed — the service auto-loads the model
on first scan and reads the input size + class list from the files you dropped in.

---

## Alternative: train locally (this machine, CPU)

Slower, but fully offline. From `malaysian-food-dataset/`:

```powershell
# one-time: install into the ML venv
.\.venv\Scripts\pip install ultralytics

# prepare → train → export (all via the same pipeline the Colab cells inline)
.\.venv\Scripts\python yolo_pipeline.py prepare --dataset-dir dataset --output-dir yolo_cls --min-images 40
.\.venv\Scripts\python yolo_pipeline.py train-cls --data-dir yolo_cls --epochs 30 --imgsz 224 --batch 16 --device cpu
.\.venv\Scripts\python yolo_pipeline.py export --model runs/classify/smartbunda_cls/weights/best.pt --imgsz 224
```

`export` writes `../assets/ml/food_cnn.tflite` and `../assets/ml/labels.json`
directly. (Reduce `--epochs` to keep CPU time tractable; accuracy will be lower
than the Colab run — re-train on GPU when you can.)

---

## Tuning the smart-split threshold

The app uses the on-device result only when its top-1 confidence clears a
threshold, otherwise it escalates to Gemini. That threshold is:

```dart
// lib/config/ai_config.dart
static const double yoloConfidenceThreshold = 0.60;
```

- **Raise it** (e.g. 0.75) if the on-device model confidently returns wrong dishes
  — more scans go to the more capable cloud models.
- **Lower it** (e.g. 0.45) once the model is well-trained — more scans resolve
  instantly on-device, fewer cloud calls.

Validate on real meal photos and pick the value that keeps wrong on-device
shortcuts rare.

---

## How it fits together (data + control flow)

```
camera/gallery photo
      │
      ▼
ImageQualityService  ── too blurry/dark ──▶ retake / manual
      │ ok
      ▼
compressForVision (≤768px)
      │
      ▼
YoloFoodClassifierService  (assets/ml/food_cnn.tflite)   ◀── THIS GUIDE
      │ top-1 ≥ yoloConfidenceThreshold?
      ├── yes ─────────────────────────────▶ use on-device predictions
      │ no / model absent / low confidence
      ▼
Gemini chain (Firebase AI Logic, 5 attempts across 3 Flash models)
      │ all fail
      ▼
manual food picker
      │
      ▼
FoodAnalysisResultScreen → nutrition lookup → save
```

## Troubleshooting

- **App still always uses Gemini** → check `assets/ml/labels.json` isn't the empty
  placeholder `[]`, and that `food_cnn.tflite` exists. The service logs
  `[YoloFoodClassifierService] model not loaded …` to the console when it can't
  load either file.
- **Wrong/garbage on-device predictions** → the TFLite input normalization must be
  0–1. The `half=True` export above produces that; the Flutter service feeds
  `rNormalized` (0–1) pixels to match. If you export differently, keep the two in sync.
- **`labels.json` order** → the service orders labels by their `index` field to line
  up with the model's output logits. Keep the `{index,label}` shape the export writes.
- **Class count mismatch** → labels length must equal the model's output classes.
  Re-export `labels.json` from the same `best.pt` you exported the `.tflite` from.
```

> True multi-food *detection* (boxes) is a future upgrade: annotate ~50+ images
> per class in Roboflow, export YOLO format, then
> `python yolo_pipeline.py train-det --data <exported>/data.yaml`. Until then,
> Gemini handles multi-dish plates.
