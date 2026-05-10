# Malaysian Food Classifier

This folder contains the image dataset utilities and TensorFlow training code
used for Smartbunda food image classification.

## Setup

Create a Python environment, then install the ML dependencies:

```bash
pip install -r requirements-ml.txt
```

On Windows in this repo, use the helper script to provision a workspace-local
Python 3.11 runtime, create `.venv`, install requirements, and start training:

```powershell
.\train_cnn.ps1
```

## Build or Refresh the Dataset

The existing `dataset/` folder is arranged as one directory per food class. To
download and preprocess images again:

```bash
python dataset_builder.py
```

## Train the Model

Run training from this folder:

```bash
python train_cnn.py --dataset-dir dataset --epochs 40
```

Or use the PowerShell wrapper:

```powershell
.\train_cnn.ps1 -Epochs 40
```

To export the trained model directly into the Flutter app assets:

```bash
python train_cnn.py --dataset-dir dataset --epochs 40 --app-assets-dir ../assets/ml
```

The wrapper exports to `..\assets\ml` by default, so the plain command is:

```powershell
.\train_cnn.ps1
```

The trainer now defaults to transfer learning with `MobileNetV3Small` and a
two-stage schedule:

1. Train only the classification head for `--frozen-epochs`.
2. Unfreeze the last `--unfreeze-layers` backbone layers and fine-tune at a
   lower `--fine-tune-learning-rate`.

Useful variants:

```bash
# Offline / no pretrained weights
python train_cnn.py --dataset-dir dataset --epochs 40 --backbone-weights none

# Alternate mobile backbone
python train_cnn.py --dataset-dir dataset --epochs 40 --backbone mobilenet_v2

# Longer head warmup and gentler fine-tuning
python train_cnn.py --dataset-dir dataset --epochs 50 --frozen-epochs 12 --fine-tune-learning-rate 5e-5
```

If you use `--backbone-weights imagenet`, TensorFlow may need to download the
pretrained checkpoint the first time unless it is already cached locally.

The trainer writes these generated artifacts to `artifacts/`:

- `food_cnn.keras`: TensorFlow/Keras model.
- `food_cnn_best.keras`: best checkpoint by validation accuracy.
- `food_cnn.tflite`: TensorFlow Lite export for app integration.
- `labels.json`: class index to food label mapping.
- `training_history.csv`: per-epoch metrics.

For a quick smoke run:

```bash
python train_cnn.py --dataset-dir dataset --epochs 1 --frozen-epochs 1 --batch-size 16 --no-tflite
```

Wrapper equivalent:

```powershell
.\train_cnn.ps1 -Epochs 1 -BatchSize 16 -NoTflite
```

## Predict a Single Image

After training:

```bash
python predict_food.py "dataset/nasi lemak/000001.jpg"
```

The command prints the top predicted labels and probabilities.
