/// SmartBunda — Image Quality Assessment (IQA)
///
/// Offline, pre-classification check that scores a food photo on blur,
/// brightness, contrast, and resolution and produces an overall 0–100 quality
/// score. Used to warn or block before running TFLite recognition so blurry /
/// dark / low-resolution images don't yield unreliable nutrition estimates.
library smartbunda.image_quality_service;

import 'dart:typed_data';

import 'package:flutter/foundation.dart' show compute;
import 'package:image/image.dart' as img;

enum ImageQualityLevel { good, fair, poor, invalid }

extension ImageQualityLevelX on ImageQualityLevel {
  String get label {
    switch (this) {
      case ImageQualityLevel.good:
        return 'Good';
      case ImageQualityLevel.fair:
        return 'Fair';
      case ImageQualityLevel.poor:
        return 'Poor';
      case ImageQualityLevel.invalid:
        return 'Invalid';
    }
  }
}

class ImageQualityResult {
  const ImageQualityResult({
    required this.score,
    required this.level,
    required this.blurScore,
    required this.brightnessScore,
    required this.contrastScore,
    required this.resolutionOk,
    this.reason,
  });

  /// Overall quality 0–100.
  final int score;
  final ImageQualityLevel level;

  /// Sub-scores (0–100) for user-facing diagnostics.
  final int blurScore;
  final int brightnessScore;
  final int contrastScore;
  final bool resolutionOk;

  /// Short human-readable explanation of the main issue (when not good).
  final String? reason;

  bool get isInvalid => level == ImageQualityLevel.invalid;
  bool get shouldBlock => level == ImageQualityLevel.poor || isInvalid;
  bool get shouldWarn => level == ImageQualityLevel.fair;

  static const ImageQualityResult invalid = ImageQualityResult(
    score: 0,
    level: ImageQualityLevel.invalid,
    blurScore: 0,
    brightnessScore: 0,
    contrastScore: 0,
    resolutionOk: false,
    reason: 'The image could not be read.',
  );
}

class ImageQualityService {
  const ImageQualityService();

  static const int _minDimension = 224; // matches the model input size
  static const int _workingMax = 512; // downscale longest side for speed

  /// Assess [bytes] off the UI thread.
  Future<ImageQualityResult> assess(Uint8List bytes) {
    return compute(_assessIsolate, bytes);
  }

  /// Synchronous assessment (used by [assess] inside an isolate; exposed for
  /// tests).
  static ImageQualityResult assessSync(Uint8List bytes) =>
      _assessIsolate(bytes);
}

ImageQualityResult _assessIsolate(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return ImageQualityResult.invalid;

  final origW = decoded.width;
  final origH = decoded.height;
  final resolutionOk =
      origW >= ImageQualityService._minDimension &&
          origH >= ImageQualityService._minDimension;

  // Downscale a working copy for the pixel math (perf on mid-range devices).
  final longest = origW > origH ? origW : origH;
  final work = longest > ImageQualityService._workingMax
      ? img.copyResize(
          decoded,
          width: origW >= origH ? ImageQualityService._workingMax : null,
          height: origH > origW ? ImageQualityService._workingMax : null,
          interpolation: img.Interpolation.average,
        )
      : decoded;

  final w = work.width;
  final h = work.height;

  // Grayscale luminance buffer (0–255).
  final lum = Float64List(w * h);
  var sum = 0.0;
  var i = 0;
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final l = work.getPixel(x, y).luminance.toDouble();
      lum[i++] = l;
      sum += l;
    }
  }
  final mean = sum / lum.length;

  // Contrast = stddev of luminance.
  var varSum = 0.0;
  for (final l in lum) {
    final d = l - mean;
    varSum += d * d;
  }
  final stdDev = (varSum / lum.length);
  final contrast = stdDev <= 0 ? 0.0 : _sqrt(stdDev);

  // Blur = variance of the Laplacian (3x3) over luminance. Low ⇒ blurry.
  final lapVar = _laplacianVariance(lum, w, h, mean: mean);

  // ── Map raw metrics to 0–100 sub-scores ──────────────────────────────────
  // Blur: lapVar ~ <60 very blurry, >600 sharp (empirical for downscaled food).
  final blurScore = _clamp01((lapVar - 40) / (600 - 40)) * 100;

  // Brightness: best around 110–170; penalise too dark / too bright.
  final double brightnessScore;
  if (mean < 40 || mean > 225) {
    brightnessScore = 10;
  } else if (mean < 70) {
    brightnessScore = _lerp(20, 90, (mean - 40) / 30);
  } else if (mean > 190) {
    brightnessScore = _lerp(90, 20, (mean - 190) / 35);
  } else {
    brightnessScore = 95;
  }

  // Contrast: stddev <20 flat, >55 good.
  final contrastScore = _clamp01((contrast - 18) / (55 - 18)) * 100;

  final resolutionScore = resolutionOk ? 100.0 : 35.0;

  // Weighted overall score.
  final overall = (blurScore * 0.40 +
          brightnessScore * 0.25 +
          contrastScore * 0.20 +
          resolutionScore * 0.15)
      .round()
      .clamp(0, 100);

  final level = overall >= 70
      ? ImageQualityLevel.good
      : overall >= 50
          ? ImageQualityLevel.fair
          : ImageQualityLevel.poor;

  String? reason;
  if (level != ImageQualityLevel.good) {
    // Surface the weakest dimension.
    final entries = <String, double>{
      'The photo looks blurry — hold steady and tap to focus.': blurScore,
      'Lighting looks off — use brighter, even light.': brightnessScore,
      'The photo looks flat/washed out — improve contrast.': contrastScore,
      'Resolution is too low — move closer or use a higher-quality photo.':
          resolutionScore,
    };
    reason = entries.entries.reduce((a, b) => a.value <= b.value ? a : b).key;
  }

  return ImageQualityResult(
    score: overall,
    level: level,
    blurScore: blurScore.round(),
    brightnessScore: brightnessScore.round(),
    contrastScore: contrastScore.round(),
    resolutionOk: resolutionOk,
    reason: reason,
  );
}

/// Variance of the 3x3 Laplacian over a luminance buffer.
double _laplacianVariance(
  Float64List lum,
  int w,
  int h, {
  required double mean,
}) {
  if (w < 3 || h < 3) return 0;
  var sum = 0.0;
  var sumSq = 0.0;
  var count = 0;
  for (var y = 1; y < h - 1; y++) {
    for (var x = 1; x < w - 1; x++) {
      final c = lum[y * w + x];
      final lap = (lum[(y - 1) * w + x] +
              lum[(y + 1) * w + x] +
              lum[y * w + (x - 1)] +
              lum[y * w + (x + 1)]) -
          4 * c;
      sum += lap;
      sumSq += lap * lap;
      count++;
    }
  }
  if (count == 0) return 0;
  final m = sum / count;
  return (sumSq / count) - (m * m);
}

double _sqrt(double v) {
  // Newton's method (avoids importing dart:math in the isolate for one call).
  if (v <= 0) return 0;
  var x = v;
  for (var i = 0; i < 20; i++) {
    x = 0.5 * (x + v / x);
  }
  return x;
}

double _clamp01(double v) => v < 0 ? 0 : (v > 1 ? 1 : v);

double _lerp(double a, double b, double t) => a + (b - a) * _clamp01(t);
