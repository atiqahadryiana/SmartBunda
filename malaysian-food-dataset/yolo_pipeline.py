"""
YOLOv8n Multi-Food Detection Pipeline
======================================
Migrates from single-food classification to multi-food detection with
bounding boxes. Supports detecting multiple Malaysian dishes in one image.

Requirements:
    pip install ultralytics>=8.0  opencv-python  pyyaml

Usage — Phase A: Prepare dataset from existing classification images:
    python yolo_pipeline.py prepare --dataset-dir dataset --output-dir yolo_dataset

Usage — Phase B: Train YOLOv8n classification (no bbox labels needed):
    python yolo_pipeline.py train-cls --dataset-dir dataset --epochs 100

Usage — Phase C: Train YOLOv8n detection (requires bbox annotation):
    python yolo_pipeline.py train-det --data yolo_dataset/data.yaml --epochs 100

Usage — Phase D: Export to TFLite:
    python yolo_pipeline.py export --model runs/detect/train/weights/best.pt

Architecture decision:
    Classification (single food) → YOLOv8n-cls  → EfficientNetB0 level accuracy, ~6 MB
    Detection (multi-food + bbox) → YOLOv8n-det → requires bbox annotations
"""

from __future__ import annotations

import argparse
import json
import os
import random
import shutil
from pathlib import Path

# ── Constants ─────────────────────────────────────────────────────────────────
SCRIPT_DIR   = Path(__file__).resolve().parent
DEFAULT_DATA = SCRIPT_DIR / "dataset"
YOLO_DIR     = SCRIPT_DIR / "yolo_dataset"
ARTIFACTS    = SCRIPT_DIR / "artifacts"
IMAGE_SIZE   = 640   # YOLO standard


# ── Helpers ───────────────────────────────────────────────────────────────────

def _copy_images(src_dir: Path, dst_dir: Path, max_images: int = 500) -> list[Path]:
    """Copy up to max_images from src_dir to dst_dir, return copied paths."""
    dst_dir.mkdir(parents=True, exist_ok=True)
    suffixes = {".jpg", ".jpeg", ".png", ".webp", ".bmp"}
    images = [p for p in src_dir.iterdir()
              if p.is_file() and p.suffix.lower() in suffixes]
    random.shuffle(images)
    copied = []
    for p in images[:max_images]:
        target = dst_dir / p.name
        shutil.copy2(p, target)
        copied.append(target)
    return copied


# ── Phase A: Prepare classification dataset for YOLOv8-cls ───────────────────

def prepare_cls_dataset(
    dataset_dir: Path,
    output_dir: Path,
    val_split: float = 0.15,
    min_images: int = 40,
) -> None:
    """Reorganise flat class dirs into YOLO classification layout:
       output_dir/
           train/<class_name>/<images>
           val/<class_name>/<images>
    """
    print(f"\n── Preparing YOLO classification dataset ──")
    print(f"Source: {dataset_dir}")
    print(f"Output: {output_dir}\n")

    class_dirs = [d for d in sorted(dataset_dir.iterdir()) if d.is_dir()]
    eligible = []
    for d in class_dirs:
        count = sum(1 for f in d.iterdir()
                    if f.is_file() and f.suffix.lower() in {".jpg",".jpeg",".png",".webp"})
        if count >= min_images:
            eligible.append((d, count))
        else:
            print(f"  SKIP  {d.name:40s} ({count} images < {min_images})")

    print(f"\nEligible classes: {len(eligible)}")
    class_names = []

    for class_dir, _ in eligible:
        name = class_dir.name
        class_names.append(name)
        suffixes = {".jpg", ".jpeg", ".png", ".webp", ".bmp"}
        images = [p for p in class_dir.iterdir()
                  if p.is_file() and p.suffix.lower() in suffixes]
        random.shuffle(images)
        split = max(1, int(len(images) * val_split))
        val_imgs   = images[:split]
        train_imgs = images[split:]

        for subset, imgs in [("train", train_imgs), ("val", val_imgs)]:
            dst = output_dir / subset / name
            dst.mkdir(parents=True, exist_ok=True)
            for p in imgs:
                shutil.copy2(p, dst / p.name)

        print(f"  {name:40s} train={len(train_imgs):3d}  val={len(val_imgs):3d}")

    # Write data.yaml (classification mode)
    yaml_content = (
        f"path: {output_dir.resolve()}\n"
        f"train: train\n"
        f"val: val\n"
        f"nc: {len(class_names)}\n"
        f"names: {json.dumps(class_names)}\n"
    )
    (output_dir / "data.yaml").write_text(yaml_content)
    print(f"\n✅ Dataset ready: {len(class_names)} classes → {output_dir}")


# ── Phase B: Train YOLOv8n classification ─────────────────────────────────────

def train_classification(
    data_dir: Path,
    epochs: int = 100,
    imgsz: int = 224,
    batch: int = 32,
    lr0: float = 1e-3,
    device: str = "0",
) -> None:
    """Train YOLOv8n-cls on the prepared classification dataset."""
    try:
        from ultralytics import YOLO
    except ImportError:
        raise SystemExit("Install ultralytics: pip install ultralytics>=8.0")

    print("\n── YOLOv8n Classification Training ──")
    print(f"Data: {data_dir}  |  Epochs: {epochs}  |  imgsz: {imgsz}")

    model = YOLO("yolov8n-cls.pt")   # pretrained on ImageNet
    results = model.train(
        data=str(data_dir),
        epochs=epochs,
        imgsz=imgsz,
        batch=batch,
        lr0=lr0,
        device=device,
        patience=15,
        augment=True,
        flipud=0.0,
        fliplr=0.5,
        hsv_h=0.015,
        hsv_s=0.7,
        hsv_v=0.4,
        degrees=10.0,
        translate=0.1,
        scale=0.5,
        project="runs/classify",
        name="smartbunda_cls",
        save=True,
        plots=True,
    )
    print(f"\n✅ Training complete → runs/classify/smartbunda_cls/weights/best.pt")
    return results


# ── Phase C: Annotate + train detection model ─────────────────────────────────

ANNOTATION_GUIDE = """
╔══════════════════════════════════════════════════════════════╗
║        ANNOTATION GUIDE FOR MULTI-FOOD DETECTION            ║
╠══════════════════════════════════════════════════════════════╣
║                                                              ║
║  Tools (choose one):                                         ║
║  • Roboflow (web) — https://roboflow.com  [RECOMMENDED]      ║
║  • LabelImg (desktop) — pip install labelImg                 ║
║  • CVAT (web) — https://cvat.ai                              ║
║                                                              ║
║  Annotation format: YOLO (class_id cx cy w h — normalised)  ║
║                                                              ║
║  Steps:                                                      ║
║  1. Upload 500–1000 meal images to Roboflow                  ║
║  2. Draw bounding boxes around each food item                ║
║  3. Label with class names matching your labels.json         ║
║  4. Export in YOLO format → download dataset                 ║
║  5. Run:  python yolo_pipeline.py train-det                  ║
║            --data /path/to/exported/data.yaml                ║
║                                                              ║
║  Target: 50+ annotated images per class, 2–4 foods/image    ║
╚══════════════════════════════════════════════════════════════╝
"""


def train_detection(
    data_yaml: Path,
    epochs: int = 100,
    imgsz: int = 640,
    batch: int = 16,
    device: str = "0",
) -> None:
    """Train YOLOv8n detection model — requires annotated dataset."""
    try:
        from ultralytics import YOLO
    except ImportError:
        raise SystemExit("Install ultralytics: pip install ultralytics>=8.0")

    if not data_yaml.exists():
        print(ANNOTATION_GUIDE)
        raise FileNotFoundError(
            f"data.yaml not found: {data_yaml}\n"
            "Follow the annotation guide above first."
        )

    print("\n── YOLOv8n Detection Training ──")
    print(f"Data: {data_yaml}  |  Epochs: {epochs}  |  imgsz: {imgsz}")

    model = YOLO("yolov8n.pt")  # pretrained on COCO
    results = model.train(
        data=str(data_yaml),
        epochs=epochs,
        imgsz=imgsz,
        batch=batch,
        device=device,
        patience=20,
        augment=True,
        mosaic=1.0,
        mixup=0.1,
        copy_paste=0.1,
        hsv_h=0.015,
        hsv_s=0.7,
        hsv_v=0.4,
        fliplr=0.5,
        degrees=5.0,
        project="runs/detect",
        name="smartbunda_det",
        save=True,
        plots=True,
        val=True,
        # Optimizer tuning for food detection
        optimizer="AdamW",
        lr0=1e-3,
        lrf=0.01,
        warmup_epochs=3,
        box=7.5,    # box loss weight
        cls=0.5,    # class loss weight
        dfl=1.5,    # distribution focal loss weight
    )
    print(f"\n✅ Detection training complete → runs/detect/smartbunda_det/")
    return results


# ── Phase D: Export to TFLite ─────────────────────────────────────────────────

def export_tflite(
    model_path: Path,
    output_dir: Path = ARTIFACTS,
    imgsz: int = 224,
    int8: bool = False,
) -> None:
    """Export YOLO model to TFLite for Flutter deployment.

    For mobile XNNPACK compatibility:
      - Use int8=False  → float16 TFLite (safest, no need for representative dataset)
      - Use int8=True   → full INT8 (smaller, needs representative dataset)

    IMPORTANT: int8=False uses float16 quantisation which avoids the
    XNNPACK 'failed preconditions' issue with hybrid INT8/FP32 graphs.
    """
    try:
        from ultralytics import YOLO
    except ImportError:
        raise SystemExit("Install ultralytics: pip install ultralytics>=8.0")

    print(f"\n── Exporting to TFLite ──")
    print(f"Model: {model_path}  |  INT8: {int8}  |  imgsz: {imgsz}")

    model = YOLO(str(model_path))
    export_path = model.export(
        format="tflite",
        imgsz=imgsz,
        half=not int8,   # FP16 if not INT8
        int8=int8,
        data=None,       # provide calibration data path if int8=True
        simplify=True,
    )
    print(f"Exported: {export_path}")

    # Copy to Flutter assets
    tflite_name = "food_detect.tflite" if "detect" in str(model_path).lower() else "food_cnn.tflite"
    app_assets = SCRIPT_DIR.parent / "assets" / "ml"
    app_assets.mkdir(parents=True, exist_ok=True)
    dest = app_assets / tflite_name
    shutil.copy2(export_path, dest)
    print(f"Copied to Flutter assets: {dest}")

    # Write YOLO-compatible labels.json
    label_path = app_assets / "labels.json"
    if hasattr(model, "names"):
        labels = [{"index": i, "label": name}
                  for i, name in model.names.items()]
        label_path.write_text(json.dumps(labels, indent=2, ensure_ascii=False))
        print(f"Labels written: {label_path}  ({len(labels)} classes)")


# ── Phase E: Validate exported TFLite ────────────────────────────────────────

def validate_tflite(tflite_path: Path) -> None:
    """Run a quick inference test to verify the exported model."""
    import numpy as np
    try:
        import tensorflow as tf
    except ImportError:
        raise SystemExit("pip install tensorflow")

    print(f"\n── Validating TFLite model ──")
    interp = tf.lite.Interpreter(str(tflite_path))
    interp.allocate_tensors()
    inp = interp.get_input_details()[0]
    out = interp.get_output_details()[0]

    print(f"  Input : {inp['shape']}  dtype={inp['dtype'].__name__}")
    print(f"  Output: {out['shape']}  dtype={out['dtype'].__name__}")

    # Dummy inference
    h, w = inp["shape"][1], inp["shape"][2]
    dummy = np.random.uniform(0, 255, size=inp["shape"]).astype(np.float32)
    interp.set_tensor(inp["index"], dummy)
    interp.invoke()
    result = interp.get_tensor(out["index"])
    print(f"  Result: shape={result.shape}  sum={result.sum():.4f}  NaN={np.isnan(result).any()}")
    print("  ✅ TFLite inference OK")


# ── CLI ───────────────────────────────────────────────────────────────────────

def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="YOLOv8 multi-food detection pipeline for SmartBunda."
    )
    sub = parser.add_subparsers(dest="command", required=True)

    # prepare
    p_prep = sub.add_parser("prepare", help="Prepare dataset for YOLO-cls training.")
    p_prep.add_argument("--dataset-dir", type=Path, default=DEFAULT_DATA)
    p_prep.add_argument("--output-dir",  type=Path, default=YOLO_DIR)
    p_prep.add_argument("--val-split",   type=float, default=0.15)
    p_prep.add_argument("--min-images",  type=int,   default=40)

    # train-cls
    p_cls = sub.add_parser("train-cls", help="Train YOLOv8n classification model.")
    p_cls.add_argument("--data-dir", type=Path, default=YOLO_DIR)
    p_cls.add_argument("--epochs",   type=int,   default=100)
    p_cls.add_argument("--imgsz",    type=int,   default=224)
    p_cls.add_argument("--batch",    type=int,   default=32)
    p_cls.add_argument("--device",   type=str,   default="0")

    # train-det
    p_det = sub.add_parser("train-det", help="Train YOLOv8n detection (requires bbox annotations).")
    p_det.add_argument("--data",    type=Path, required=True)
    p_det.add_argument("--epochs",  type=int,  default=100)
    p_det.add_argument("--imgsz",   type=int,  default=640)
    p_det.add_argument("--batch",   type=int,  default=16)
    p_det.add_argument("--device",  type=str,  default="0")

    # export
    p_exp = sub.add_parser("export", help="Export YOLO model to TFLite.")
    p_exp.add_argument("--model",  type=Path, required=True)
    p_exp.add_argument("--imgsz",  type=int,  default=224)
    p_exp.add_argument("--int8",   action="store_true", help="Use INT8 (needs calibration data).")

    # validate
    p_val = sub.add_parser("validate", help="Validate exported TFLite model.")
    p_val.add_argument("--model", type=Path, default=ARTIFACTS / "food_cnn.tflite")

    # print guide
    sub.add_parser("annotation-guide", help="Print the bounding box annotation guide.")

    return parser


def main():
    parser = build_parser()
    args   = parser.parse_args()

    if args.command == "prepare":
        prepare_cls_dataset(
            args.dataset_dir, args.output_dir,
            val_split=args.val_split, min_images=args.min_images,
        )

    elif args.command == "train-cls":
        train_classification(
            args.data_dir, epochs=args.epochs,
            imgsz=args.imgsz, batch=args.batch, device=args.device,
        )

    elif args.command == "train-det":
        train_detection(
            args.data, epochs=args.epochs,
            imgsz=args.imgsz, batch=args.batch, device=args.device,
        )

    elif args.command == "export":
        export_tflite(args.model, imgsz=args.imgsz, int8=args.int8)

    elif args.command == "validate":
        validate_tflite(args.model)

    elif args.command == "annotation-guide":
        print(ANNOTATION_GUIDE)


if __name__ == "__main__":
    main()
