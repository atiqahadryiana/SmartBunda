"""Download, deduplicate, and resize food images for training.

Usage
-----
Scrape everything from scratch:
    python dataset_builder.py

Skip classes that already have >= 60 images (resume after a partial run):
    python dataset_builder.py --skip-existing 60

Only report which classes would be excluded without touching files:
    python dataset_builder.py --dry-run --min-images 40
"""

from __future__ import annotations

import argparse
import shutil
import time
from pathlib import Path

import cv2
import imagehash
from PIL import Image

from foods import foods

SCRIPT_DIR = Path(__file__).resolve().parent
DATASET_DIR = SCRIPT_DIR / "dataset"
EXCLUDED_DIR = SCRIPT_DIR / "dataset_excluded"
SIZE = (224, 224)
IMAGE_SUFFIXES = frozenset({".jpg", ".jpeg", ".png", ".webp", ".bmp"})

# Hamming distance threshold for near-duplicate detection.
# Two images with hash distance <= this value are considered duplicates.
# Exact equality would be HAMMING_THRESHOLD = 0.
HAMMING_THRESHOLD = 8


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Build the food image dataset.")
    parser.add_argument(
        "--dataset-dir",
        type=Path,
        default=DATASET_DIR,
        help="Root directory for class subdirectories.",
    )
    parser.add_argument(
        "--max-bing",
        type=int,
        default=350,
        help="Maximum images to download per class from Bing.",
    )
    parser.add_argument(
        "--max-google",
        type=int,
        default=200,
        help="Maximum images to download per class from Google (used as fallback).",
    )
    parser.add_argument(
        "--google-fallback-threshold",
        type=int,
        default=60,
        help="If a class has fewer than this many images after Bing scraping, "
             "also scrape from Google.",
    )
    parser.add_argument(
        "--skip-existing",
        type=int,
        default=0,
        help="Skip scraping for classes that already have this many or more images. "
             "Use when resuming a failed run (e.g. --skip-existing 60).",
    )
    parser.add_argument(
        "--min-images",
        type=int,
        default=40,
        help="After scraping and deduplication, move classes below this count "
             "to dataset_excluded/.",
    )
    parser.add_argument(
        "--no-scrape",
        action="store_true",
        help="Skip scraping; only run dedup, resize, and exclusion steps.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Report what would be excluded without moving any files.",
    )
    return parser.parse_args()


def _count_images(directory: Path) -> int:
    if not directory.exists():
        return 0
    return sum(
        1 for f in directory.iterdir()
        if f.is_file() and f.suffix.lower() in IMAGE_SUFFIXES
    )


def scrape(
    food: str,
    output_dir: Path,
    max_bing: int,
    max_google: int,
    google_fallback_threshold: int,
    skip_existing: int,
) -> None:
    from icrawler.builtin import BingImageCrawler, GoogleImageCrawler

    output_dir.mkdir(parents=True, exist_ok=True)

    if skip_existing > 0 and _count_images(output_dir) >= skip_existing:
        print(f"  Skipping '{food}' (already has >= {skip_existing} images)")
        return

    print(f"  Bing: '{food}'")
    bing = BingImageCrawler(
        storage={"root_dir": str(output_dir)},
        downloader_threads=4,
        log_level=40,
    )
    bing.crawl(keyword=f"{food} malaysia food", max_num=max_bing)
    time.sleep(2)

    current = _count_images(output_dir)
    if current < google_fallback_threshold:
        print(f"  Google fallback: '{food}' (only {current} images after Bing)")
        google = GoogleImageCrawler(
            storage={"root_dir": str(output_dir)},
            downloader_threads=4,
            log_level=40,
        )
        google.crawl(keyword=f"{food} makanan malaysia", max_num=max_google)
        time.sleep(3)


def _is_near_duplicate(
    h: imagehash.ImageHash,
    seen: list[imagehash.ImageHash],
) -> bool:
    return any((h - existing) <= HAMMING_THRESHOLD for existing in seen)


def deduplicate(class_dir: Path) -> tuple[int, int]:
    """Remove near-duplicate images. Returns (kept, removed) counts."""
    seen: list[imagehash.ImageHash] = []
    kept = removed = 0
    for file in list(class_dir.iterdir()):
        if not file.is_file() or file.suffix.lower() not in IMAGE_SUFFIXES:
            continue
        try:
            with Image.open(file) as img:
                h = imagehash.average_hash(img)
            if _is_near_duplicate(h, seen):
                file.unlink()
                removed += 1
            else:
                seen.append(h)
                kept += 1
        except Exception:
            file.unlink(missing_ok=True)
            removed += 1
    return kept, removed


def resize_images(class_dir: Path) -> None:
    for file in list(class_dir.iterdir()):
        if not file.is_file() or file.suffix.lower() not in IMAGE_SUFFIXES:
            continue
        try:
            img = cv2.imread(str(file))
            if img is None:
                file.unlink()
                continue
            resized = cv2.resize(img, SIZE)
            cv2.imwrite(str(file), resized)
        except Exception:
            file.unlink(missing_ok=True)


def exclude_sparse_classes(
    dataset_dir: Path,
    min_images: int,
    dry_run: bool,
) -> None:
    below: list[tuple[str, int]] = []
    for d in sorted(dataset_dir.iterdir()):
        if not d.is_dir():
            continue
        count = _count_images(d)
        if count < min_images:
            below.append((d.name, count))

    if not below:
        print(f"All classes meet the {min_images}-image threshold.")
        return

    print(f"\n{'[DRY RUN] ' if dry_run else ''}Classes below {min_images} images "
          f"({'would be' if dry_run else 'being'} moved to dataset_excluded/):")
    for name, count in below:
        print(f"  {count:4d}  {name}")

    if dry_run:
        return

    EXCLUDED_DIR.mkdir(parents=True, exist_ok=True)
    for name, _ in below:
        src = dataset_dir / name
        dst = EXCLUDED_DIR / name
        if dst.exists():
            shutil.rmtree(dst)
        src.rename(dst)


def main() -> None:
    args = parse_args()
    args.dataset_dir.mkdir(parents=True, exist_ok=True)

    # ── Scrape ────────────────────────────────────────────────────────────────
    if not args.no_scrape:
        print(f"\n=== Scraping {len(foods)} food classes ===")
        for food in foods:
            scrape(
                food=food,
                output_dir=args.dataset_dir / food,
                max_bing=args.max_bing,
                max_google=args.max_google,
                google_fallback_threshold=args.google_fallback_threshold,
                skip_existing=args.skip_existing,
            )

    # ── Deduplicate ───────────────────────────────────────────────────────────
    print("\n=== Deduplicating ===")
    for class_dir in sorted(args.dataset_dir.iterdir()):
        if not class_dir.is_dir():
            continue
        kept, removed = deduplicate(class_dir)
        print(f"  {class_dir.name}: kept={kept}, removed={removed}")

    # ── Resize ────────────────────────────────────────────────────────────────
    if not args.dry_run:
        print("\n=== Resizing to 224×224 ===")
        for class_dir in sorted(args.dataset_dir.iterdir()):
            if class_dir.is_dir():
                resize_images(class_dir)

    # ── Exclude sparse classes ────────────────────────────────────────────────
    print(f"\n=== Excluding classes below {args.min_images} images ===")
    exclude_sparse_classes(args.dataset_dir, args.min_images, args.dry_run)

    # ── Summary ───────────────────────────────────────────────────────────────
    remaining = [d for d in args.dataset_dir.iterdir() if d.is_dir()]
    total = sum(_count_images(d) for d in remaining)
    print(
        f"\nDataset ready: {len(remaining)} classes, {total} images "
        f"({total // max(len(remaining), 1)} avg per class)"
    )


if __name__ == "__main__":
    main()
