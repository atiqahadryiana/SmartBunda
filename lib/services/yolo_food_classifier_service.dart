/// SmartBunda — on-device YOLOv8n-cls food classifier (TFLite).
///
/// This is the FIRST stage of the meal-scanner chain (the "smart split"): it
/// runs entirely on-device, so when it is confident it gives an instant,
/// offline, zero-cost result. When it is NOT confident (top score below the
/// configured threshold) the caller falls through to the Gemini cloud scanners,
/// which know the long tail of Malaysian dishes the on-device model may miss.
///
/// The model + labels are produced by
/// `malaysian-food-dataset/yolo_pipeline.py export` and shipped as Flutter
/// assets:
///   • assets/ml/food_cnn.tflite   — YOLOv8n-cls, input [1,224,224,3] float32
///   • assets/ml/labels.json       — `[{ "index": 0, "label": "nasi lemak" }, …]`
///
/// Both assets are OPTIONAL: until the model has been trained and dropped in,
/// [isReady] is false and [classifyBytes] throws [FoodImageClassifierException]
/// so the scanner chain skips straight to Gemini. The app therefore builds and
/// runs unchanged before the model exists.
///
/// PLATFORM SPLIT: the real implementation uses `tflite_flutter`, which imports
/// `dart:ffi` and therefore cannot COMPILE on Flutter web. We select the impl
/// at build time via a conditional import — native gets the TFLite-backed
/// `YoloFoodClassifier`, web gets a no-op stub — so the web bundle never pulls
/// in `dart:ffi`. The cloud scanners cover web.
///
/// YOLOv8n-cls is a single-label classifier (one dominant dish per image). True
/// multi-food detection (bounding boxes) would need an annotated detection
/// model; that long tail / multi-dish case is intentionally left to the Gemini
/// scanners and their multi-select verify UI.
library smartbunda.yolo_food_classifier_service;

import 'dart:typed_data';

import 'package:smartbunda/services/food_vision_shared.dart';
// Compile-time platform selection: web gets the stub (no dart:ffi), every other
// platform gets the TFLite-backed native implementation.
import 'package:smartbunda/services/yolo_food_classifier_stub.dart'
    if (dart.library.ffi) 'package:smartbunda/services/yolo_food_classifier_native.dart';

/// Public food-classifier used by the scanner chain. Delegates to the
/// platform-appropriate [YoloFoodClassifier] selected by the conditional import
/// above, so callers never need to branch on platform.
class YoloFoodClassifierService {
  YoloFoodClassifierService() : _impl = YoloFoodClassifier();

  final YoloFoodClassifier _impl;

  /// True once the model + labels have loaded and the classifier can run.
  /// Always false on web.
  bool get isReady => _impl.isReady;

  /// Loads the TFLite model + labels from assets, once. Never throws — failure
  /// just leaves [isReady] false. No-op on web.
  Future<void> ensureLoaded() => _impl.ensureLoaded();

  /// Runs the on-device classifier on [bytes] and returns up to [topK] foods,
  /// highest confidence first. Throws [FoodImageClassifierException] when the
  /// model isn't available or the image can't be decoded, so the scanner chain
  /// falls through to the next stage.
  Future<List<FoodImagePrediction>> classifyBytes(
    Uint8List bytes, {
    int topK = 5,
  }) =>
      _impl.classifyBytes(bytes, topK: topK);

  void dispose() => _impl.dispose();
}
