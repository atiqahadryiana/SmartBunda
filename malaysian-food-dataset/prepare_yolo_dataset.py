"""
Prepare YOLO Dataset for SmartBunda Food Detection
==================================================

Prepares the Malaysian food dataset for YOLOv8 training by:
1. Checking dataset structure
2. Creating train/val/test splits
3. Generating data.yaml configuration
4. Validating image formats

Usage:
    python prepare_yolo_dataset.py
"""

import argparse
import json
import os
import random
import shutil
from pathlib import Path
from typing import List, Tuple

# Constants
SCRIPT_DIR = Path(__file__).resolve().parent
DATASET_DIR = SCRIPT_DIR / "dataset"
YOLO_OUTPUT_DIR = SCRIPT_DIR / "yolo_dataset"

# SmartBunda food classes to include
SMARTBUNDA_CLASSES = [
    # Core Malaysian dishes
    "nasi lemak", "rendang", "satay", "laksa", "char kuey teow", 
    "hokkien mee", "roti canai", "murtabak", "teh tarik", "cendol",
    "nasi kerabu", "nasi dagang", "ayam percik", "ikan bakar",
    "otak otak", "lemang", "ketupat", "kuih lapis", "kuih seri muka",
    
    # Chinese dishes
    "wantan mee", "yong tau foo", "bak kut teh", "hainanese chicken rice",
    "curry mee", "loh mee", "pan mee", "mee bandung",
    
    # Indian dishes  
    "roti telur", "roti tisu", "roti naan", "tosai", "vadai", 
    "capati", "putu mayam", "masala dosa",
    
    # Western foods
    "burger", "pizza", "fries", "fried chicken", "spaghetti",
    "sandwich", "hot dog", "steak", "salad", "ice cream",
    
    # Beverages
    "teh ais", "kopi o", "milo ais", "sirap bandung", "limau ais",
    "barley drink"
]

def get_valid_classes(dataset_dir: Path) -> List[str]:
    """Get list of valid class directories that match SmartBunda classes."""
    class_dirs = [d for d in dataset_dir.iterdir() if d.is_dir()]
    valid_classes = []
    
    for class_dir in class_dirs:
        class_name = class_dir.name.lower()
        
        # Check if this class matches any SmartBunda food
        for food_class in SMARTBUNDA_CLASSES:
            if food_class in class_name:
                valid_classes.append(class_dir.name)
                break
    
    return sorted(valid_classes)

def count_images_per_class(dataset_dir: Path, class_names: List[str]) -> dict:
    """Count number of images in each class directory."""
    counts = {}
    
    for class_name in class_names:
        class_dir = dataset_dir / class_name
        if class_dir.exists():
            images = list(class_dir.glob("*.jpg")) + list(class_dir.glob("*.jpeg")) + \
                     list(class_dir.glob("*.png")) + list(class_dir.glob("*.webp"))
            counts[class_name] = len(images)
    
    return counts

def create_yolo_dataset_structure(
    source_dir: Path, 
    output_dir: Path, 
    class_names: List[str],
    val_split: float = 0.15,
    test_split: float = 0.10,
    min_images: int = 30
) -> dict:
    """Create YOLO dataset structure with train/val/test splits."""
    
    # Create output directories
    train_dir = output_dir / "images" / "train"
    val_dir = output_dir / "images" / "val"
    test_dir = output_dir / "images" / "test"
    
    for dir_path in [train_dir, val_dir, test_dir]:
        dir_path.mkdir(parents=True, exist_ok=True)
    
    stats = {"total_images": 0, "classes": {}}
    
    for class_name in class_names:
        source_class_dir = source_dir / class_name
        
        # Get all images
        images = list(source_class_dir.glob("*.jpg")) + list(source_class_dir.glob("*.jpeg")) + \
                 list(source_class_dir.glob("*.png")) + list(source_class_dir.glob("*.webp"))
        
        if len(images) < min_images:
            print(f"Skipping {class_name}: only {len(images)} images (min {min_images})")
            continue
        
        # Shuffle and split
        random.shuffle(images)
        
        test_count = max(1, int(len(images) * test_split))
        val_count = max(1, int(len(images) * val_split))
        train_count = len(images) - val_count - test_count
        
        train_images = images[:train_count]
        val_images = images[train_count:train_count + val_count]
        test_images = images[train_count + val_count:]
        
        # Copy images to respective directories
        for subset, subset_images in [("train", train_images), ("val", val_images), ("test", test_images)]:
            subset_dir = output_dir / "images" / subset / class_name
            subset_dir.mkdir(parents=True, exist_ok=True)
            
            for img_path in subset_images:
                shutil.copy2(img_path, subset_dir / img_path.name)
        
        # Record statistics
        stats["classes"][class_name] = {
            "total": len(images),
            "train": len(train_images),
            "val": len(val_images),
            "test": len(test_images)
        }
        stats["total_images"] += len(images)
        
        print(f"OK {class_name:20s} | Total: {len(images):3d} | Train: {len(train_images):3d} | Val: {len(val_images):3d} | Test: {len(test_images):3d}")
    
    return stats

def create_data_yaml(output_dir: Path, class_names: List[str]) -> Path:
    """Create YOLO data.yaml configuration file."""
    
    yaml_content = f"""# SmartBunda YOLOv8 Dataset Configuration
path: {output_dir.resolve()}
train: images/train
val: images/val
test: images/test

# Number of classes
nc: {len(class_names)}

# Class names
names: {json.dumps(class_names)}
"""
    
    yaml_path = output_dir / "data.yaml"
    yaml_path.write_text(yaml_content)
    
    return yaml_path

def main():
    parser = argparse.ArgumentParser(description="Prepare YOLO dataset for SmartBunda")
    parser.add_argument("--val-split", type=float, default=0.15, help="Validation split ratio")
    parser.add_argument("--test-split", type=float, default=0.10, help="Test split ratio")
    parser.add_argument("--min-images", type=int, default=30, help="Minimum images per class")
    parser.add_argument("--output-dir", type=Path, default=YOLO_OUTPUT_DIR, help="Output directory")
    
    args = parser.parse_args()
    
    print("Preparing YOLO Dataset for SmartBunda Food Detection")
    print("=" * 60)
    
    # Check if source dataset exists
    if not DATASET_DIR.exists():
        print(f"❌ Dataset directory not found: {DATASET_DIR}")
        print("Please ensure the dataset directory exists with class subdirectories.")
        return
    
    # Get valid classes
    valid_classes = get_valid_classes(DATASET_DIR)
    print(f"\nFound {len(valid_classes)} valid food classes:")
    for i, cls in enumerate(valid_classes):
        print(f"  {i+1:2d}. {cls}")
    
    # Count images
    print(f"\nCounting images per class...")
    counts = count_images_per_class(DATASET_DIR, valid_classes)
    
    total_images = sum(counts.values())
    print(f"Total images: {total_images}")
    
    # Create YOLO dataset structure
    print(f"\nCreating YOLO dataset structure...")
    print(f"Output directory: {args.output_dir}")
    print(f"Validation split: {args.val_split}")
    print(f"Test split: {args.test_split}")
    print(f"Min images per class: {args.min_images}")
    
    stats = create_yolo_dataset_structure(
        DATASET_DIR, 
        args.output_dir, 
        valid_classes,
        args.val_split, 
        args.test_split,
        args.min_images
    )
    
    # Create data.yaml
    yaml_path = create_data_yaml(args.output_dir, valid_classes)
    
    print(f"\nDataset preparation complete!")
    print(f"Total images processed: {stats['total_images']}")
    print(f"Classes included: {len(stats['classes'])}")
    print(f"YAML config: {yaml_path}")
    
    # Print summary
    print(f"\nDataset Summary:")
    print("-" * 50)
    print(f"{'Class':20s} {'Total':6s} {'Train':6s} {'Val':6s} {'Test':6s}")
    print("-" * 50)
    
    for class_name, class_stats in stats["classes"].items():
        print(f"{class_name:20s} {class_stats['total']:6d} {class_stats['train']:6d} {class_stats['val']:6d} {class_stats['test']:6d}")
    
    print("-" * 50)
    print(f"{'TOTAL':20s} {stats['total_images']:6d}")
    
    print(f"\nReady for YOLOv8 training!")
    print(f"\nNext steps:")
    print(f"1. Run training: python train_yolov8_smartbunda.py --data {yaml_path}")
    print(f"2. Or use: yolo train data={yaml_path} model=yolov8n.pt epochs=100 imgsz=640")

if __name__ == "__main__":
    main()