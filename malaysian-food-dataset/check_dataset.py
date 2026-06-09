"""Dataset health diagnostic for the Smartbunda food classifier.

Usage
-----
    python check_dataset.py
    python check_dataset.py --dataset-dir dataset --min-images 40
"""

from __future__ import annotations

import argparse
import statistics
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
IMAGE_SUFFIXES = frozenset({".jpg", ".jpeg", ".png", ".webp", ".bmp"})


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Report per-class image counts and flag potential issues."
    )
    parser.add_argument(
        "--dataset-dir",
        type=Path,
        default=SCRIPT_DIR / "dataset",
        help="Root directory containing one subdirectory per food class.",
    )
    parser.add_argument(
        "--min-images",
        type=int,
        default=40,
        help="Classes below this count are listed and flagged.",
    )
    return parser.parse_args()


def count_images(class_dir: Path) -> int:
    return sum(
        1 for f in class_dir.iterdir()
        if f.is_file() and f.suffix.lower() in IMAGE_SUFFIXES
    )


def main() -> None:
    args = parse_args()

    if not args.dataset_dir.exists():
        print(f"ERROR: dataset directory not found: {args.dataset_dir}")
        return

    class_dirs = sorted(p for p in args.dataset_dir.iterdir() if p.is_dir())
    if not class_dirs:
        print("No class subdirectories found.")
        return

    counts: dict[str, int] = {d.name: count_images(d) for d in class_dirs}
    values = list(counts.values())
    total = sum(values)

    # ── Summary statistics ────────────────────────────────────────────────────
    print("\n=== Dataset Summary ===")
    print(f"  Classes        : {len(values)}")
    print(f"  Total images   : {total}")
    print(f"  Mean / class   : {statistics.mean(values):.1f}")
    print(f"  Median / class : {statistics.median(values):.0f}")
    print(f"  Min            : {min(values):4d}  ({min(counts, key=counts.get)})")
    print(f"  Max            : {max(values):4d}  ({max(counts, key=counts.get)})")
    if len(values) > 1:
        print(f"  Std dev        : {statistics.stdev(values):.1f}")

    # ── Distribution histogram ────────────────────────────────────────────────
    buckets = [
        ("<20",   lambda n: n < 20),
        ("20–39", lambda n: 20 <= n < 40),
        ("40–99", lambda n: 40 <= n < 100),
        ("100+",  lambda n: n >= 100),
    ]
    print("\n=== Distribution ===")
    for label, predicate in buckets:
        count = sum(1 for v in values if predicate(v))
        bar = "#" * count
        print(f"  {label:6s}  {count:4d}  {bar}")

    # ── Classes below threshold ───────────────────────────────────────────────
    below = [(name, cnt) for name, cnt in sorted(counts.items()) if cnt < args.min_images]
    if below:
        print(f"\n=== Classes below {args.min_images} images "
              f"({len(below)} of {len(values)}) ===")
        for name, cnt in sorted(below, key=lambda x: x[1]):
            danger = "  *** DANGEROUS: too few for val split ***" if cnt < 10 else ""
            print(f"  {cnt:4d}  {name}{danger}")
    else:
        print(f"\nAll {len(values)} classes meet the {args.min_images}-image threshold.")

    # ── Training viability estimate ───────────────────────────────────────────
    eligible = [v for v in values if v >= args.min_images]
    print(f"\n=== Training Viability (threshold={args.min_images}) ===")
    print(f"  Eligible classes : {len(eligible)}")
    if eligible:
        train_imgs = int(sum(eligible) * 0.8)
        avg_train = train_imgs // len(eligible)
        random_chance = 100.0 / len(eligible)
        print(f"  Training images  : ~{train_imgs} (80% split)")
        print(f"  Avg train/class  : ~{avg_train}")
        print(f"  Random-guess acc : {random_chance:.2f}%")
        if avg_train < 30:
            print("  WARNING: < 30 training images per class — model will likely "
                  "fail to learn. Run dataset_builder.py to collect more data.")
        elif avg_train < 80:
            print("  CAUTION: < 80 training images per class — expect low accuracy "
                  "(40-55%). Consider collecting more data.")
        else:
            print("  OK: dataset size is sufficient for initial training.")


if __name__ == "__main__":
    main()
