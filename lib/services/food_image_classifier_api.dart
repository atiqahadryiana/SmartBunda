class FoodImagePrediction {
  const FoodImagePrediction({
    required this.label,
    required this.confidence,
  });

  final String label;
  final double confidence;

  String get confidenceLabel => '${(confidence * 100).toStringAsFixed(1)}%';

  /// Human-readable display name (underscores → spaces, title case).
  String get displayName {
    return label
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  /// Qualitative confidence tier used for UI badge colour.
  ConfidenceTier get tier {
    if (confidence >= 0.70) return ConfidenceTier.high;
    if (confidence >= 0.40) return ConfidenceTier.medium;
    return ConfidenceTier.low;
  }
}

enum ConfidenceTier { high, medium, low }

class FoodImageClassifierException implements Exception {
  const FoodImageClassifierException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => cause != null ? '$message\nCause: $cause' : message;

  /// Returns a short user-facing error that does not expose internals.
  String get userMessage {
    final m = message.toLowerCase();
    if (m.contains('not ready') || m.contains('asset')) {
      return 'Food scanner is not ready yet. '
          'Please contact support or check for an app update.';
    }
    if (m.contains('precondition') || m.contains('failed')) {
      return 'Scanner encountered a model error. '
          'Try restarting the app or contact support.';
    }
    if (m.contains('image') || m.contains('decode')) {
      return 'Could not read the image. '
          'Try a different photo (JPEG or PNG recommended).';
    }
    return 'Scanner failed. Please try again with a different image.';
  }
}
