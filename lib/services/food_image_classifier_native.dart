import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import 'package:smartbunda/services/food_image_classifier_api.dart';

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
        'Could not read the selected image. '
        'Try a different photo (JPEG or PNG, clear lighting recommended).',
      );
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
    final modelOutputSize =
        outputShape.isNotEmpty ? outputShape.last : _labels!.length;
    final labelCount = _labels!.length;
    final outputSize = modelOutputSize < labelCount ? modelOutputSize : labelCount;
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
      _interpreter!.allocateTensors();
      _labels = await _loadLabels();
    } on FoodImageClassifierException {
      rethrow;
    } catch (error) {
      final msg = error.toString().toLowerCase();
      if (msg.contains('unable to open') || msg.contains('not found')) {
        throw FoodImageClassifierException(
          'Food image scanner is not ready. '
          'The model file (food_cnn.tflite) is missing from app assets.',
          cause: error,
        );
      }
      if (msg.contains('precondition') || msg.contains('failed')) {
        throw FoodImageClassifierException(
          'TFLite model initialisation failed (failed precondition). '
          'This usually means the model was exported with incompatible '
          'quantisation. Re-export using float16 quantisation and replace '
          'assets/ml/food_cnn.tflite.',
          cause: error,
        );
      }
      throw FoodImageClassifierException(
        'Food image scanner failed to load.',
        cause: error,
      );
    }
  }

  Future<List<String>> _loadLabels() async {
    final rawLabels = jsonDecode(await rootBundle.loadString(labelsAsset));
    if (rawLabels is! List) {
      throw const FormatException('labels.json must contain a list.');
    }

    final labels = <String>[];
    for (final item in rawLabels) {
      if (item is String) {
        labels.add(item);
      } else if (item is Map && item['label'] is String) {
        labels.add(item['label'] as String);
      } else {
        throw FormatException('Unexpected label entry: $item');
      }
    }

    if (labels.isEmpty) {
      throw const FormatException('labels.json is empty.');
    }
    return labels;
  }

  Float32List _imageToInput(img.Image image) {
    final input = Float32List(_inputSize * _inputSize * 3);
    var bufferIndex = 0;
    for (var y = 0; y < _inputSize; y++) {
      for (var x = 0; x < _inputSize; x++) {
        final pixel = image.getPixel(x, y);
        input[bufferIndex++] = pixel.rNormalized * 255.0;
        input[bufferIndex++] = pixel.gNormalized * 255.0;
        input[bufferIndex++] = pixel.bNormalized * 255.0;
      }
    }
    return input;
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
