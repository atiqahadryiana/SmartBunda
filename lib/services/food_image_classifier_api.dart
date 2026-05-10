class FoodImagePrediction {
  const FoodImagePrediction({
    required this.label,
    required this.confidence,
  });

  final String label;
  final double confidence;

  String get confidenceLabel => '${(confidence * 100).toStringAsFixed(1)}%';
}

class FoodImageClassifierException implements Exception {
  const FoodImageClassifierException(this.message);

  final String message;

  @override
  String toString() => message;
}
