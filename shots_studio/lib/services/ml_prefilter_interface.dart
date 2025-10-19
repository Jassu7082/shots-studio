import 'dart:typed_data';

/// Enum for prefilter modes
enum PrefilterMode {
  none,
  light,
  deep;

  String get displayName {
    switch (this) {
      case PrefilterMode.none:
        return 'None';
      case PrefilterMode.light:
        return 'Light (Recommended)';
      case PrefilterMode.deep:
        return 'Deep';
    }
  }

  static PrefilterMode fromString(String value) {
    switch (value.toLowerCase()) {
      case 'light':
        return PrefilterMode.light;
      case 'deep':
        return PrefilterMode.deep;
      case 'none':
      default:
        return PrefilterMode.none;
    }
  }
}

/// Categories that can be detected in screenshots
enum DetectionCategory {
  creditCard,
  apiKeys,
  uiPattern,
  secureDocument,
  bankStatement,
  apiDocumentation,
  passwordManager,
  cryptoWallet,
  loginScreen,
  receipt,
  bankApp,
}

/// Bounding box for object detection
class BoundingBox {
  final double x;
  final double y;
  final double width;
  final double height;
  final String label;
  final double confidence;

  BoundingBox({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.label,
    required this.confidence,
  });
}

/// Detection result from ML analysis
class MLDetectionResult {
  final bool containsSensitiveContent;
  final double confidence;
  final List<DetectionCategory> detectedCategories;
  final Map<String, double> confidenceScores;
  final List<BoundingBox>? boundingBoxes;

  MLDetectionResult({
    required this.containsSensitiveContent,
    required this.confidence,
    required this.detectedCategories,
    required this.confidenceScores,
    this.boundingBoxes,
  });
}

/// Interface for ML-based prefilter services
abstract class MLPrefilterService {
  Future<void> initializeModels();
  Future<MLDetectionResult> analyzeImage(Uint8List imageBytes, PrefilterMode mode);
  Future<Map<String, dynamic>> getServiceStatus();
  void dispose();
}
