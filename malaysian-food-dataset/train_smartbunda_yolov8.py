"""
SmartBunda YOLOv8 Training Script
=================================

Complete training script for SmartBunda Malaysian food detection using YOLOv8.
This script trains on the prepared dataset and exports to TFLite for mobile deployment.

Usage:
    python train_smartbunda_yolov8.py --epochs 50 --imgsz 640 --batch 16 --device 0
"""

import argparse
import json
import shutil
from pathlib import Path
from datetime import datetime

try:
    from ultralytics import YOLO
    import cv2
except ImportError:
    print("Please install required packages:")
    print("pip install ultralytics>=8.0 opencv-python")
    exit(1)

# Constants
SCRIPT_DIR = Path(__file__).resolve().parent
DATA_YAML = SCRIPT_DIR / "yolo_dataset" / "data.yaml"
ARTIFACTS_DIR = SCRIPT_DIR / "artifacts"
FLUTTER_ASSETS = SCRIPT_DIR.parent / "assets" / "ml"

def train_yolov8(
    data_yaml: Path,
    epochs: int = 50,
    imgsz: int = 640,
    batch: int = 16,
    device: str = "0",
    project_name: str = "smartbunda_yolov8"
):
    """Train YOLOv8 model for food detection."""
    
    print(f"🚀 Starting YOLOv8 Training for SmartBunda")
    print(f"📊 Dataset: {data_yaml}")
    print(f"⚙️  Epochs: {epochs} | Image Size: {imgsz} | Batch: {batch}")
    print(f"💻 Device: {device}")
    
    # Load pretrained YOLOv8 model
    model = YOLO("yolov8n.pt")
    
    # Training parameters optimized for food detection
    results = model.train(
        data=str(data_yaml),
        epochs=epochs,
        imgsz=imgsz,
        batch=batch,
        device=device,
        patience=15,
        augment=True,
        
        # Augmentation parameters
        mosaic=1.0,
        mixup=0.1,
        copy_paste=0.1,
        hsv_h=0.015,
        hsv_s=0.7,
        hsv_v=0.4,
        fliplr=0.5,
        degrees=5.0,
        translate=0.1,
        scale=0.5,
        
        # Optimizer tuning
        optimizer="AdamW",
        lr0=1e-3,
        lrf=0.01,
        warmup_epochs=3,
        
        # Loss weights
        box=7.5,
        cls=0.5,
        dfl=1.5,
        
        # Project settings
        project=str(SCRIPT_DIR / "runs"),
        name=project_name,
        save=True,
        plots=True,
        val=True,
        visualize=True,
    )
    
    print(f"✅ Training complete!")
    return results

def export_to_tflite(model_path: Path, output_dir: Path = ARTIFACTS_DIR, imgsz: int = 224):
    """Export YOLO model to TFLite for mobile deployment."""
    
    print(f"📦 Exporting to TFLite...")
    print(f"📁 Model: {model_path}")
    
    model = YOLO(str(model_path))
    
    # Export to TFLite (FP16 for mobile compatibility)
    export_path = model.export(
        format="tflite",
        imgsz=imgsz,
        half=True,        # Use FP16 quantization
        int8=False,       # Don't use INT8 (requires calibration dataset)
        simplify=True,    # Simplify model
    )
    
    print(f"📤 Exported TFLite model: {export_path}")
    
    # Copy to Flutter assets directory
    FLUTTER_ASSETS.mkdir(parents=True, exist_ok=True)
    
    tflite_dest = FLUTTER_ASSETS / "smartbunda_food_detector.tflite"
    shutil.copy2(export_path, tflite_dest)
    
    print(f"📱 Copied to Flutter assets: {tflite_dest}")
    
    # Save class labels
    if hasattr(model, "names"):
        labels = [{"index": i, "label": name} for i, name in model.names.items()]
        labels_path = FLUTTER_ASSETS / "food_labels.json"
        labels_path.write_text(json.dumps(labels, indent=2, ensure_ascii=False))
        print(f"🏷️  Labels saved: {labels_path}")
        print(f"📋 Classes: {len(labels)} food items")
    
    return export_path

def validate_model(model_path: Path, test_image: Path = None):
    """Validate the trained model on a test image."""
    
    print(f"🔍 Validating model...")
    print(f"📁 Model: {model_path}")
    
    model = YOLO(str(model_path))
    
    # Use a sample image from dataset if none provided
    if test_image is None:
        # Find any image from the dataset
        sample_images = list((SCRIPT_DIR / "yolo_dataset" / "images" / "val").glob("**/*.jpg")) + \
                       list((SCRIPT_DIR / "yolo_dataset" / "images" / "val").glob("**/*.png"))
        if sample_images:
            test_image = sample_images[0]
        else:
            print("❌ No test images found")
            return
    
    print(f"🖼️  Test image: {test_image}")
    
    # Run inference
    results = model(test_image, conf=0.25, iou=0.45)
    
    # Display results
    for result in results:
        if result.boxes is not None:
            print(f"🎯 Detected {len(result.boxes)} food items:")
            for i, box in enumerate(result.boxes):
                cls = int(box.cls)
                conf = float(box.conf)
                print(f"   {i+1}: {model.names[cls]} (confidence: {conf:.3f})")
        else:
            print("❌ No food items detected")
        
        # Save annotated image
        annotated = result.plot()
        output_path = ARTIFACTS_DIR / f"validation_{datetime.now().strftime('%Y%m%d_%H%M%S')}.jpg"
        ARTIFACTS_DIR.mkdir(parents=True, exist_ok=True)
        cv2.imwrite(str(output_path), annotated)
        print(f"📸 Annotated image saved: {output_path}")

def main():
    parser = argparse.ArgumentParser(description="Train YOLOv8 for SmartBunda food detection")
    parser.add_argument("--epochs", type=int, default=50, help="Number of training epochs")
    parser.add_argument("--imgsz", type=int, default=640, help="Image size for training")
    parser.add_argument("--batch", type=int, default=16, help="Batch size")
    parser.add_argument("--device", type=str, default="0", help="Device to use (0 for GPU, cpu for CPU)")
    parser.add_argument("--project", type=str, default="smartbunda_yolov8", help="Project name")
    parser.add_argument("--export", action="store_true", help="Export to TFLite after training")
    parser.add_argument("--validate", action="store_true", help="Validate model after training")
    
    args = parser.parse_args()
    
    # Create output directories
    ARTIFACTS_DIR.mkdir(parents=True, exist_ok=True)
    
    # Check if data.yaml exists
    if not DATA_YAML.exists():
        print(f"❌ Error: data.yaml not found at {DATA_YAML}")
        print("Please run prepare_yolo_dataset.py first")
        exit(1)
    
    # Step 1: Train YOLOv8 model
    results = train_yolov8(
        DATA_YAML,
        epochs=args.epochs,
        imgsz=args.imgsz,
        batch=args.batch,
        device=args.device,
        project_name=args.project
    )
    
    # Step 2: Export to TFLite if requested
    if args.export:
        best_model_path = SCRIPT_DIR / "runs" / args.project / "weights" / "best.pt"
        if best_model_path.exists():
            export_to_tflite(best_model_path)
        else:
            print(f"❌ Best model not found at: {best_model_path}")
    
    # Step 3: Validate model if requested
    if args.validate:
        best_model_path = SCRIPT_DIR / "runs" / args.project / "weights" / "best.pt"
        if best_model_path.exists():
            validate_model(best_model_path)
        else:
            print(f"❌ Best model not found at: {best_model_path}")
    
    print(f"\n🎉 SmartBunda YOLOv8 Training Pipeline Complete!")
    print(f"\n📋 Summary:")
    print(f"   • Trained on {args.epochs} epochs")
    print(f"   • Image size: {args.imgsz}x{args.imgsz}")
    print(f"   • Batch size: {args.batch}")
    print(f"   • Device: {'GPU' if args.device != 'cpu' else 'CPU'}")
    
    if args.export:
        print(f"   • TFLite model exported to Flutter assets")
    
    print(f"\n🚀 Next steps:")
    print(f"   1. Use the model: model = YOLO('runs/{args.project}/weights/best.pt')")
    print(f"   2. Integrate TFLite model with Flutter app")
    print(f"   3. Deploy for real-time food detection on mobile")

if __name__ == "__main__":
    main()