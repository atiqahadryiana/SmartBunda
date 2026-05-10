import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import 'food_image_classifier_api.dart';

class FoodImageClassifier {
  static const modelAsset = 'assets/ml/food_cnn.tflite';
  static const labelsAsset = 'assets/ml/labels.json';
  static const _inputSize = 224;

  Interpreter? _interpreter;
  List<String>? _labels;
  Future<void>? _loadFuture;

  Future<List<FoodImagePrediction>> classifyBytes(
    Uint8List bytes, {
    int topK = 5,
  }) async {
    await _ensureLoaded();

    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw const FoodImageClassifierException(
          'Could not read selected image.');
    }

    final oriented = img.bakeOrientation(decoded);
    final resized = img.copyResize(
      oriented,
      width: _inputSize,
      height: _inputSize,
      interpolation: img.Interpolation.linear,
    );

    final interpreter = _interpreter!;
    final outputShape = interpreter.getOutputTensor(0).shape;
    final outputSize = outputShape.isEmpty ? _labels!.length : outputShape.last;
    final output = List.generate(
      1,
      (_) => List<double>.filled(outputSize, 0),
    );

    interpreter.run(_imageToInput(resized), output);
    return _rankPredictions(output.first, topK);
  }

  Future<void> _ensureLoaded() {
    return _loadFuture ??= _load();
  }

  Future<void> _load() async {
    try {
      _interpreter = await Interpreter.fromAsset(modelAsset);
      _labels = await _loadLabels();
    } catch (error) {
      throw FoodImageClassifierException(
        'Food image scanner is not ready. Train the CNN and copy food_cnn.tflite plus labels.json to assets/ml. Details: $error',
      );
    }
  }

  Future<List<String>> _loadLabels() async {
    final rawLabels = jsonDecode(await rootBundle.loadString(labelsAsset));
    if (rawLabels is! List) {
      throw const FormatException('labels.json must contain a list.');
    }

    final labels = rawLabels.map((item) {
      if (item is String) return item;
      if (item is Map && item['label'] is String) {
        return item['label'] as String;
      }
      throw const FormatException('Each label must be a string or label map.');
    }).toList();

    if (labels.isEmpty) {
      throw const FormatException('labels.json does not contain labels.');
    }
    return labels;
  }

  List<List<List<List<double>>>> _imageToInput(img.Image image) {
    return [
      List.generate(
        _inputSize,
        (y) => List.generate(
          _inputSize,
          (x) {
            final pixel = image.getPixel(x, y);
            return [
              pixel.r.toDouble(),
              pixel.g.toDouble(),
              pixel.b.toDouble(),
            ];
          },
        ),
      ),
    ];
  }

  List<FoodImagePrediction> _rankPredictions(
    List<double> probabilities,
    int topK,
  ) {
    final labels = _labels!;
    final count = probabilities.length < labels.length
        ? probabilities.length
        : labels.length;
    final ranked = List<int>.generate(count, (index) => index)
      ..sort((a, b) => probabilities[b].compareTo(probabilities[a]));

    return ranked.take(topK).map((index) {
      return FoodImagePrediction(
        label: labels[index],
        confidence: probabilities[index],
      );
    }).toList();
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _labels = null;
    _loadFuture = null;
  }
}
