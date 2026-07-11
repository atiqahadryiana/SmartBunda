"""
YOLOv8 Training Script for SmartBunda Malaysian Food Detection
===============================================================

Trains YOLOv8 model to detect multiple Malaysian foods including:
- Malay dishes (Nasi Lemak, Rendang, Satay)
- Chinese dishes (Char Kuey Teow, Hokkien Mee)  
- Indian dishes (Roti Canai, Murtabak)
- Western foods (Burger, Pizza, Fries)

Usage:
    python train_yolov8_smartbunda.py --epochs 100 --imgsz 640 --batch 16

Requirements:
    pip install ultralytics>=8.0 opencv-python pyyaml
"""

import argparse
import os
import json
from pathlib import Path
from datetime import datetime

try:
    from ultralytics import YOLO
    from ultralytics.utils.plotting import Annotator
    import cv2
    import yaml
except ImportError:
    print("Please install required packages:")
    print("pip install ultralytics>=8.0 opencv-python pyyaml")
    exit(1)

# Constants
SCRIPT_DIR = Path(__file__).resolve().parent
DATASET_DIR = SCRIPT_DIR / "dataset"
OUTPUT_DIR = SCRIPT_DIR / "yolo_output"
ARTIFACTS_DIR = SCRIPT_DIR / "artifacts"

# SmartBunda food classes (based on seed_fooddb.py and dataset structure)
SMARTBUNDA_FOOD_CLASSES = [
    # Malay Cuisine
    "nasi lemak", "rendang", "satay", "laksa", "mee rebus", "nasi kerabu",
    "nasi dagang", "ayam percik", "ikan bakar", "otak otak", "lemang",
    "ketupat", "pulut kuning", "kuih lapis", "kuih seri muka", "cendol",
    
    # Chinese Cuisine  
    "char kuey teow", "hokkien mee", "wantan mee", "yong tau foo", 
    "bak kut teh", "hainanese chicken rice", "roti canai", "curry mee",
    "loh mee", "pan mee", "mee bandung",
    
    # Indian Cuisine
    "roti canai", "roti telur", "roti tisu", "roti naan", "murtabak",
    "tosai", "vadai", "capati", "putu mayam", "masala dosa",
    
    # Western & Popular
    "burger", "pizza", "fries", "fried chicken", "spaghetti",
    "sandwich", "hot dog", "steak", "salad", "ice cream",
    
    # Beverages
    "teh tarik", "teh ais", "kopi o", "milo ais", "sirap bandung",
    "limau ais", "barley drink"
]

def create_data_yaml(dataset_dir: Path, output_dir: Path):
    """Create YOLO data.yaml configuration file."""
    # Get all class directories
    class_dirs = [d for d in dataset_dir.iterdir() if d.is_dir()]
    class_names = [d.name for d in class_dirs]
    
    # Filter to only include SmartBunda classes
    valid_classes = []
    for cls in class_names:
        if any(food_class in cls.lower() for food_class in SMARTBUNDA_FOOD_CLASSES):
            valid_classes.append(cls)
    
    print(f"Found {len(valid_classes)} valid SmartBunda food classes:")
    for i, cls in enumerate(valid_classes):
        print(f"  {i}: {cls}")
    
    # Create data.yaml
    data_yaml_content = f"""
# SmartBunda YOLOv8 Dataset Configuration
path: {dataset_dir.resolve()}
train: dataset/images/train
val: dataset/images/val
test: dataset/images/test

# Number of classes
nc: {len(valid_classes)}

# Class names
names: {json.dumps(valid_classes)}

# Additional training parameters
# imgsz: 640
# batch: 16
# epochs: 100
# device: 0
# workers: 8
"""
    
    output_dir.mkdir(parents=True, exist_ok=True)
    yaml_path = output_dir / "data.yaml"
    yaml_path.write_text(data_yaml_content)
    
    print(f"✅ Created data.yaml at: {yaml_path}")
    return yaml_path, valid_classes

def train_yolov8_model(data_yaml_path: Path, epochs: int = 100, imgsz: int = 640, 
                      batch: int = 16, device: str = "0", project: str = "smartbunda_yolov8"):
    """Train YOLOv8 model for food detection."""
    
    print(f"\n── Training YOLOv8 Model for SmartBunda ──")
    print(f"Dataset: {data_yaml_path}")
    print(f"Epochs: {epochs} | Image Size: {imgsz} | Batch: {batch}")
    print(f"Device: {device}")
    
    # Load pretrained YOLOv8 model
    model = YOLO("yolov8n.pt")  # You can also use yolov8s.pt, yolov8m.pt for better accuracy
    
    # Training parameters optimized for food detection
    results = model.train(
        data=str(data_yaml_path),
        epochs=epochs,
        imgsz=imgsz,
        batch=batch,
        device=device,
        patience=20,           # Early stopping patience
        augment=True,          # Enable data augmentation
        
        # Augmentation parameters optimized for food
        mosaic=1.0,           # Mosaic augmentation
        mixup=0.1,            # Mixup augmentation
        copy_paste=0.1,       # Copy-paste augmentation
        hsv_h=0.015,           # Hue augmentation
        hsv_s=0.7,            # Saturation augmentation  
        hsv_v=0.4,            # Value augmentation
        fliplr=0.5,           # Horizontal flip
        degrees=5.0,          # Rotation degrees
        translate=0.1,         # Translation
        scale=0.5,            # Scaling
        shear=0.0,            # Shear
        
        # Optimizer tuning
        optimizer="AdamW",    # AdamW optimizer
        lr0=1e-3,             # Initial learning rate
        lrf=0.01,             # Final learning rate
        warmup_epochs=3,      # Warmup epochs
        
        # Loss weights
        box=7.5,              # Box loss weight
        cls=0.5,              # Class loss weight  
        dfl=1.5,              # Distribution focal loss weight
        
        # Project settings
        project=str(SCRIPT_DIR / "runs"),
        name=project,
        save=True,
        plots=True,
        val=True,
        visualize=True,
        
        # Food-specific settings
        single_cls=False,     # Multiple classes
        rect=False,           # Rectangular training
        cos_lr=False,         # Cosine learning rate scheduler
        label_smoothing=0.0, # No label smoothing
        nbs=64,              # Nominal batch size
    )
    
    print(f"\n✅ Training complete!")
    print(f"Best model saved to: runs/{project}/weights/best.pt")
    print(f"Last model saved to: runs/{project}/weights/last.pt")
    
    return results

def export_to_tflite(model_path: Path, output_dir: Path = ARTIFACTS_DIR, imgsz: int = 224):
    """Export YOLO model to TFLite for mobile deployment."""
    
    print(f"\n── Exporting to TFLite ──")
    print(f"Model: {model_path}")
    
    model = YOLO(str(model_path))
    
    # Export to TFLite (FP16 for mobile compatibility)
    export_path = model.export(
        format="tflite",
        imgsz=imgsz,
        half=True,        # Use FP16 quantization
        int8=False,       # Don't use INT8 (requires calibration dataset)
        simplify=True,    # Simplify model
    )
    
    print(f"Exported TFLite model: {export_path}")
    
    # Copy to Flutter assets directory
    flutter_assets = SCRIPT_DIR.parent / "assets" / "ml"
    flutter_assets.mkdir(parents=True, exist_ok=True)
    
    tflite_dest = flutter_assets / "smartbunda_yolov8.tflite"
    import shutil
    shutil.copy2(export_path, tflite_dest)
    
    print(f"Copied to Flutter assets: {tflite_dest}")
    
    # Save class labels
    if hasattr(model, "names"):
        labels = [{"index": i, "label": name} for i, name in model.names.items()]
        labels_path = flutter_assets / "yolo_labels.json"
        labels_path.write_text(json.dumps(labels, indent=2, ensure_ascii=False))
        print(f"Labels saved: {labels_path}")
    
    return export_path

def validate_model(model_path: Path, test_image_path: Path = None):
    """Validate the trained model on test images."""
    
    print(f"\n── Validating Model ──")
    print(f"Model: {model_path}")
    
    model = YOLO(str(model_path))
    
    # If no test image provided, use a sample from dataset
    if test_image_path is None:
        # Find a sample image
        sample_images = list(DATASET_DIR.glob("**/*.jpg")) + list(DATASET_DIR.glob("**/*.png"))
        if sample_images:
            test_image_path = sample_images[0]
        else:
            print("No test images found in dataset")
            return
    
    # Run inference
    results = model(test_image_path, conf=0.25, iou=0.45)
    
    # Display results
    for result in results:
        if result.boxes is not None:
            print(f"Detected {len(result.boxes)} food items:")
            for i, box in enumerate(result.boxes):
                cls = int(box.cls)
                conf = float(box.conf)
                print(f"  {i+1}: {model.names[cls]} (confidence: {conf:.3f})")
        
        # Save annotated image
        annotated = result.plot()
        output_path = ARTIFACTS_DIR / f"validation_{datetime.now().strftime('%Y%m%d_%H%M%S')}.jpg"
        ARTIFACTS_DIR.mkdir(parents=True, exist_ok=True)
        cv2.imwrite(str(output_path), annotated)
        print(f"Annotated image saved: {output_path}")

def main():
    parser = argparse.ArgumentParser(description="Train YOLOv8 for SmartBunda food detection")
    parser.add_argument("--epochs", type=int, default=100, help="Number of training epochs")
    parser.add_argument("--imgsz", type=int, default=640, help="Image size for training")
    parser.add_argument("--batch", type=int, default=16, help="Batch size")
    parser.add_argument("--device", type=str, default="0", help="Device to use (0 for GPU, cpu for CPU)")
    parser.add_argument("--project", type=str, default="smartbunda_yolov8", help="Project name")
    parser.add_argument("--export", action="store_true", help="Export to TFLite after training")
    parser.add_argument("--validate", action="store_true", help="Validate model after training")
    
    args = parser.parse_args()
    
    # Create output directory
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    ARTIFACTS_DIR.mkdir(parents=True, exist_ok=True)
    
    # Step 1: Create data.yaml
    data_yaml_path, classes = create_data_yaml(DATASET_DIR, OUTPUT_DIR)
    
    # Step 2: Train YOLOv8 model
    results = train_yolov8_model(
        data_yaml_path,
        epochs=args.epochs,
        imgsz=args.imgsz,
        batch=args.batch,
        device=args.device,
        project=args.project
    )
    
    # Step 3: Export to TFLite if requested
    if args.export:
        best_model_path = SCRIPT_DIR / "runs" / args.project / "weights" / "best.pt"
        if best_model_path.exists():
            export_to_tflite(best_model_path)
        else:
            print(f"Best model not found at: {best_model_path}")
    
    # Step 4: Validate model if requested
    if args.validate:
        best_model_path = SCRIPT_DIR / "runs" / args.project / "weights" / "best.pt"
        if best_model_path.exists():
            validate_model(best_model_path)
        else:
            print(f"Best model not found at: {best_model_path}")
    
    print(f"\n🎉 SmartBunda YOLOv8 Training Complete!")
    print(f"\nNext steps:")
    print(f"1. Use the model for inference: model = YOLO('runs/{args.project}/weights/best.pt')")
    print(f"2. Integrate with Flutter app using the TFLite model")
    print(f"3. Deploy to mobile devices for real-time food detection")

if __name__ == "__main__":
    main()