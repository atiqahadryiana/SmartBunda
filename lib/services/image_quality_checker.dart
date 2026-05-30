import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

enum ImageQualityTier { good, fair, poor }

class ImageQualityResult {
  const ImageQualityResult({
    required this.tier,
    required this.confidence,
    required this.issues,
    required this.blurScore,
    required this.brightnessScore,
  });

  final ImageQualityTier tier;

  /// 0–100: how confident we are the image is usable.
  final int confidence;

  /// Human-readable list of issues found.
  final List<String> issues;

  final double blurScore;
  final double brightnessScore;

  String get tierLabel {
    switch (tier) {
      case ImageQualityTier.good: return 'Good';
      case ImageQualityTier.fair: return 'Fair';
      case ImageQualityTier.poor: return 'Poor';
    }
  }

  bool get isUsable => tier != ImageQualityTier.poor || issues.isEmpty;
}

class ImageQualityChecker {
  /// Assess image quality using blur and brightness heuristics.
  /// Returns a [ImageQualityResult] indicating how suitable the image is
  /// for food recognition.
  ImageQualityResult assess(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      return const ImageQualityResult(
        tier: ImageQualityTier.poor,
        confidence: 0,
        issues: ['Could not decode image.'],
        blurScore: 0,
        brightnessScore: 0,
      );
    }

    // Downsample to a small thumbnail for fast analysis
    final thumb = img.copyResize(decoded, width: 160, height: 160);

    final blurScore = _laplacianVariance(thumb);
    final brightnessScore = _meanBrightness(thumb);

    final issues = <String>[];

    // Blur threshold: < 80 is noticeably blurry on a 160-px thumbnail
    if (blurScore < 80) {
      issues.add(
        blurScore < 30
            ? 'Image is very blurry. Hold the camera steady and tap to focus.'
            : 'Image is slightly blurry. Try moving closer or re-focusing.',
      );
    }

    // Brightness thresholds: 0–255 mean luminance
    if (brightnessScore < 40) {
      issues.add('Image is too dark. Move to better lighting or turn on the flash.');
    } else if (brightnessScore > 220) {
      issues.add('Image is overexposed. Avoid bright backgrounds or direct sunlight.');
    }

    // Derive quality tier
    final ImageQualityTier tier;
    final int confidence;

    if (issues.isEmpty) {
      tier = ImageQualityTier.good;
      confidence = math.min(95, 60 + (blurScore / 5).clamp(0, 35).toInt());
    } else if (issues.length == 1 && blurScore >= 40 && brightnessScore >= 30) {
      tier = ImageQualityTier.fair;
      confidence = 55;
    } else {
      tier = ImageQualityTier.poor;
      confidence = 20;
    }

    return ImageQualityResult(
      tier: tier,
      confidence: confidence,
      issues: issues,
      blurScore: blurScore,
      brightnessScore: brightnessScore,
    );
  }

  /// Approximates blur level via Laplacian variance on grayscale pixels.
  /// Higher = sharper.
  double _laplacianVariance(img.Image image) {
    final w = image.width;
    final h = image.height;

    if (w < 3 || h < 3) return 0;

    // 3×3 Laplacian kernel: [0,1,0,1,-4,1,0,1,0]
    final greys = List<double>.generate(w * h, (i) {
      final pixel = image.getPixel(i % w, i ~/ w);
      return 0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b;
    });

    double sum = 0;
    double sumSq = 0;
    int count = 0;

    for (int y = 1; y < h - 1; y++) {
      for (int x = 1; x < w - 1; x++) {
        final lap = -4 * greys[y * w + x] +
            greys[(y - 1) * w + x] +
            greys[(y + 1) * w + x] +
            greys[y * w + (x - 1)] +
            greys[y * w + (x + 1)];
        sum += lap;
        sumSq += lap * lap;
        count++;
      }
    }

    if (count == 0) return 0;
    final mean = sum / count;
    return (sumSq / count) - mean * mean;
  }

  /// Mean luminance of the image (0–255).
  double _meanBrightness(img.Image image) {
    double total = 0;
    final n = image.width * image.height;
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final p = image.getPixel(x, y);
        total += 0.299 * p.r + 0.587 * p.g + 0.114 * p.b;
      }
    }
    return n > 0 ? total / n : 0;
  }
}
