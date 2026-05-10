import 'dart:typed_data';

import 'food_image_classifier_api.dart';

class FoodImageClassifier {
  Future<List<FoodImagePrediction>> classifyBytes(
    Uint8List bytes, {
    int topK = 5,
  }) async {
    throw const FoodImageClassifierException(
      'Food image scanner is not available on web. Use Android, iOS, or desktop support for TensorFlow Lite scanning.',
    );
  }

  void dispose() {}
}
