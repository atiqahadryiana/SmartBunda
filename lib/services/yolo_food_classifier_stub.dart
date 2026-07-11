/// SmartBunda — WEB stub for the on-device YOLOv8n-cls classifier.
///
/// `tflite_flutter` imports `dart:ffi`, which does not exist on Flutter web and
/// fails to COMPILE there (not just at runtime). To keep the web build green we
/// select this stub via the conditional import in
/// `yolo_food_classifier_service.dart` — it pulls in no native code, is always
/// [isReady] == false, and throwing from [classifyBytes] makes the scanner chain
/// fall straight through to the Gemini cloud scanners (which cover web).
library smartbunda.yolo_food_classifier_stub;

import 'dart:typed_data';

import 'package:smartbunda/services/food_vision_shared.dart';

/// No-op classifier used on web. Mirrors the native API surface so the public
/// `YoloFoodClassifierService` can delegate to either without branching.
class YoloFoodClassifier {
  YoloFoodClassifier();

  /// Always false on web — there is no TFLite runtime here.
  bool get isReady => false;

  /// No-op: nothing to load on web.
  Future<void> ensureLoaded() async {}

  /// Always throws so the caller skips to the cloud scanners.
  Future<List<FoodImagePrediction>> classifyBytes(
    Uint8List bytes, {
    int topK = 5,
  }) async {
    throw const FoodImageClassifierException(
      'On-device food model is not available on web.',
    );
  }

  void dispose() {}
}
