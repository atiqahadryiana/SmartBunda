"""Optional computer-vision utilities for multi-food and camera workflows."""

from __future__ import annotations

import cv2
import numpy as np


def detect_candidate_food_regions(
    image_bgr: np.ndarray,
    *,
    min_area_ratio: float = 0.03,
) -> list[tuple[int, int, int, int]]:
    """Return rough bounding boxes for prominent food-like regions.

    This is a lightweight baseline for bonus multi-food detection. Production
    systems should replace it with an object detector such as YOLO, EfficientDet,
    or MediaPipe object detection when accurate localization is required.
    """

    height, width = image_bgr.shape[:2]
    min_area = height * width * min_area_ratio
    gray = cv2.cvtColor(image_bgr, cv2.COLOR_BGR2GRAY)
    blur = cv2.GaussianBlur(gray, (7, 7), 0)
    edges = cv2.Canny(blur, 50, 150)
    contours, _ = cv2.findContours(edges, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

    boxes: list[tuple[int, int, int, int]] = []
    for contour in contours:
        x, y, w, h = cv2.boundingRect(contour)
        if w * h >= min_area:
            boxes.append((x, y, w, h))

    if not boxes:
        boxes.append((0, 0, width, height))
    return boxes


def estimate_portion_multiplier(box: tuple[int, int, int, int], image_shape: tuple[int, ...]) -> float:
    """Approximate serving multiplier from image area when no depth data exists."""

    _, _, w, h = box
    image_h, image_w = image_shape[:2]
    area_ratio = (w * h) / float(image_w * image_h)
    return max(0.5, min(2.5, area_ratio / 0.35))
