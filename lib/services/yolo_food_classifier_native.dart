/// SmartBunda — NATIVE implementation of the on-device YOLOv8n-cls classifier.
///
/// This file is only compiled on platforms that have `dart:ffi` (Android, iOS,
/// desktop). It is selected via the conditional import in
/// `yolo_food_classifier_service.dart`; the web build gets the no-op stub in
/// `yolo_food_classifier_stub.dart` instead, so `tflite_flutter` (which imports
/// `dart:ffi`) is never compiled for web.
library smartbunda.yolo_food_classifier_native;

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import 'package:smartbunda/services/food_vision_shared.dart';

/// Concrete classifier backed by a TFLite interpreter. See the doc comment on
/// the public `YoloFoodClassifierService` for behaviour and the asset contract.
class YoloFoodClassifier {
  YoloFoodClassifier();

  static const String _modelAsset = 'assets/ml/food_cnn.tflite';
  static const String _labelsAsset = 'assets/ml/labels.json';
  static const int _defaultInputSize = 224;

  Interpreter? _interpreter;
  List<String> _labels = const [];
  int _inputSize = _defaultInputSize;
  bool _loadAttempted = false;

  bool get isReady => _interpreter != null && _labels.isNotEmpty;

  Future<void> ensureLoaded() async {
    if (_loadAttempted) return;
    _loadAttempted = true;

    try {
      // Labels first — a model with no labels is unusable, and the placeholder
      // labels.json shipped before training is an empty array.
      final labelsRaw = await rootBundle.loadString(_labelsAsset);
      _labels = _parseLabels(labelsRaw);
      if (_labels.isEmpty) {
        // Model not trained yet (placeholder labels). Stay unready, quietly.
        return;
      }

      final interpreter = await Interpreter.fromAsset(_modelAsset);
      // YOLOv8-cls input is [1, H, W, 3]; pull H back out so preprocessing
      // matches whatever imgsz the model was exported at.
      final inputShape = interpreter.getInputTensor(0).shape;
      if (inputShape.length == 4 && inputShape[1] > 0) {
        _inputSize = inputShape[1];
      }
      _interpreter = interpreter;
    } catch (error, stack) {
      // Missing asset / incompatible model → degrade to the cloud scanners.
      debugPrint('[YoloFoodClassifier] model not loaded '
          '(falling back to cloud scanners): $error');
      debugPrint('$stack');
    }
  }

  Future<List<FoodImagePrediction>> classifyBytes(
    Uint8List bytes, {
    int topK = 5,
  }) async {
    await ensureLoaded();
    final interpreter = _interpreter;
    if (interpreter == null || _labels.isEmpty) {
      throw const FoodImageClassifierException(
        'On-device food model is not available.',
      );
    }
    if (bytes.isEmpty) {
      throw const FoodImageClassifierException(
        'Could not read the selected image. Try a different photo.',
      );
    }

    final input = _preprocess(bytes);
    if (input == null) {
      throw const FoodImageClassifierException(
        'Could not decode the image for on-device analysis.',
      );
    }

    // Output is [1, numClasses] softmax probabilities for YOLOv8-cls.
    final numClasses = _labels.length;
    final output = List.generate(1, (_) => List<double>.filled(numClasses, 0));

    try {
      interpreter.run(input, output);
    } catch (error) {
      throw FoodImageClassifierException(
        'On-device food analysis failed.',
        cause: error,
      );
    }

    final scores = output.first;
    final predictions = <FoodImagePrediction>[];
    for (var i = 0; i < numClasses && i < scores.length; i++) {
      predictions.add(
        FoodImagePrediction(
          label: _labels[i],
          confidence: scores[i].clamp(0.0, 1.0),
        ),
      );
    }
    predictions.sort((a, b) => b.confidence.compareTo(a.confidence));

    if (predictions.isEmpty) {
      throw const FoodImageClassifierException(
        "Couldn't identify any food in this photo.",
      );
    }
    return predictions.take(topK).toList();
  }

  /// Decodes [bytes], center-crops to square, resizes to the model input size,
  /// and normalises to 0–1 float32 in NHWC layout — the format YOLOv8-cls
  /// TFLite exports expect. Returns null when the image can't be decoded.
  List<List<List<List<double>>>>? _preprocess(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return null;

    // Center-crop to square so the resize doesn't distort the dish, matching
    // Ultralytics' classification preprocessing (center crop + resize).
    final side = decoded.width < decoded.height ? decoded.width : decoded.height;
    final offsetX = (decoded.width - side) ~/ 2;
    final offsetY = (decoded.height - side) ~/ 2;
    final square = img.copyCrop(
      decoded,
      x: offsetX,
      y: offsetY,
      width: side,
      height: side,
    );
    final resized = img.copyResize(
      square,
      width: _inputSize,
      height: _inputSize,
      interpolation: img.Interpolation.linear,
    );

    return [
      List.generate(_inputSize, (y) {
        return List.generate(_inputSize, (x) {
          final px = resized.getPixel(x, y);
          return [
            px.rNormalized.toDouble(),
            px.gNormalized.toDouble(),
            px.bNormalized.toDouble(),
          ];
        });
      }),
    ];
  }

  /// Parses the labels.json shape written by yolo_pipeline.py:
  /// `[{ "index": 0, "label": "nasi lemak" }, …]`, ordered by index. Falls back
  /// to a bare `["a","b"]` list if that's what's present.
  List<String> _parseLabels(String raw) {
    dynamic parsed;
    try {
      parsed = jsonDecode(raw);
    } catch (_) {
      return const [];
    }
    if (parsed is! List || parsed.isEmpty) return const [];

    // Bare list of strings.
    if (parsed.first is String) {
      return parsed.cast<String>();
    }

    // List of {index,label} objects — order by index so positions line up with
    // the model's output logits.
    final entries = <int, String>{};
    for (final item in parsed) {
      if (item is! Map) continue;
      final label = item['label'] ?? item['name'];
      final index = item['index'];
      if (label is! String || label.trim().isEmpty) continue;
      final i = index is int ? index : int.tryParse('$index') ?? entries.length;
      entries[i] = label.trim();
    }
    if (entries.isEmpty) return const [];
    final maxIndex = entries.keys.reduce((a, b) => a > b ? a : b);
    return List.generate(maxIndex + 1, (i) => entries[i] ?? 'class_$i');
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }
}
