"""
Quick Test Training for SmartBunda YOLOv8
===========================================

Quick test with fewer epochs to verify the training pipeline works.
"""

from ultralytics import YOLO
from pathlib import Path

# Paths
SCRIPT_DIR = Path(__file__).resolve().parent
DATA_YAML = SCRIPT_DIR / "yolo_dataset" / "data.yaml"

print("Starting quick YOLOv8 training test...")
print(f"Data YAML: {DATA_YAML}")

# Check if data.yaml exists
if not DATA_YAML.exists():
    print(f"Error: data.yaml not found at {DATA_YAML}")
    exit(1)

# Load pretrained model
model = YOLO("yolov8n.pt")

# Quick training with fewer epochs
results = model.train(
    data=str(DATA_YAML),
    epochs=5,           # Just 5 epochs for quick test
    imgsz=320,         # Smaller image size for faster training
    batch=8,           # Smaller batch size
    device="cpu",      # Use CPU for quick test (change to "0" for GPU)
    patience=2,        # Early stopping patience
    augment=True,      # Enable augmentation
    project=str(SCRIPT_DIR / "runs"),
    name="smartbunda_quick_test",
    save=True,
    plots=True,
    val=True,
)

print("Quick training test completed!")
print("Check the runs directory for results.")