import 'dart:typed_data';
import 'dart:math';
import 'package:image/image.dart' as img;
import 'ml_prefilter_interface.dart';
/// Computer vision-powered screenshot prefilter service (Web Implementation)
/// This version doesn't use tflite_flutter to avoid dart:ffi compatibility issues on web
class MLPrefilterServiceMobile implements MLPrefilterService {
  static final MLPrefilterServiceMobile _instance = MLPrefilterServiceMobile._internal();
  factory MLPrefilterServiceMobile() => _instance;

  MLPrefilterServiceMobile._internal();

  bool _initialized = false;

  /// Initialize computer vision service (no-op for web)
  @override
  Future<void> initializeModels() async {
    if (_initialized) return;
    _initialized = true;
    print('✅ Computer Vision Detection initialized (Web stub - no ML model)');
  }

  /// Analyze screenshot for sensitive content using computer vision fallback only
  @override
  Future<MLDetectionResult> analyzeImage(Uint8List imageBytes, PrefilterMode mode) async {
    if (!_initialized) {
      await initializeModels();
    }

    if (mode == PrefilterMode.none) {
      return MLDetectionResult(
        containsSensitiveContent: false,
        confidence: 0.0,
        detectedCategories: [],
        confidenceScores: {},
      );
    }

    try {
      final Map<String, double> scores = {};

      // Computer vision fallback - no ML model on web
      print('🔍 Computer vision fallback (Web): Analyzing for credit cards...');
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        return MLDetectionResult(
          containsSensitiveContent: false,
          confidence: 0.0,
          detectedCategories: [],
          confidenceScores: {},
        );
      }

      // Run credit card detection using computer vision only
      final creditCardConfidence = await _detectCreditCard(image);
      print('📊 Computer vision confidence: ${(creditCardConfidence * 100).toInt()}%');

      if (creditCardConfidence > 0.3) { // More aggressive threshold
        scores['credit_card'] = creditCardConfidence;
        print('🚫 COMPUTER VISION: CREDIT CARD DETECTED! Blocking screenshot from Gemini');
        print('💳 Confidence: ${(creditCardConfidence * 100).toInt()}%');
        print('🛡️ Privacy Protection: Screenshot will NOT be sent to AI');
      } else {
        print('✅ Computer vision: No credit card detected (${(creditCardConfidence * 100).toInt()}%)');
      }

      final overallConfidence = scores.values.isNotEmpty
          ? scores.values.reduce(max)
          : 0.0;

      // Map back to expected categories for UI
      final List<DetectionCategory> detectedCategories = scores.keys.map((categoryName) {
        return _mapTrainedCategoryToEnum(categoryName);
      }).whereType<DetectionCategory>().toList();

      return MLDetectionResult(
        containsSensitiveContent: scores.containsKey('credit_card'),
        confidence: overallConfidence,
        detectedCategories: detectedCategories,
        confidenceScores: scores,
      );
    } catch (e) {
      print('Prefilter: Error during analysis: $e');
      // Fail-safe: allow content if analysis fails
      return MLDetectionResult(
        containsSensitiveContent: false,
        confidence: 0.0,
        detectedCategories: [],
        confidenceScores: {},
      );
    }
  }

  /// Computer vision-based credit card detection (same implementation as the original)
  Future<double> _detectCreditCard(img.Image image) async {
    // Credit card detection using multiple visual cues

    // 1. Aspect ratio check (credit cards are typically ~1.586:1 ratio)
    final aspectRatio = image.width / image.height;
    final aspectScore = _evaluateAspectRatio(aspectRatio);

    // 2. Color analysis (credit cards often have plastic-like appearance)
    final colorScore = _analyzeCardColors(image);

    // 3. Edge detection (looking for sharp boundaries typical of cards)
    final edgeScore = _detectCardEdges(image);

    // 4. Shape analysis (rectangular shape with smooth gradients)
    final shapeScore = _analyzeCardShape(image);

    // 5. Size analysis (credit cards are typically held at certain distances)
    final sizeScore = _analyzeCardSize(image);

    // Combine scores with weighted average
    final combinedScore = (aspectScore * 0.25) + (colorScore * 0.25) + (edgeScore * 0.2) + (shapeScore * 0.15) + (sizeScore * 0.15);

    return combinedScore;
  }

  /// Evaluate if aspect ratio matches credit card proportions
  double _evaluateAspectRatio(double aspectRatio) {
    // Standard credit card ratio is approximately 1.586:1 (85.6mm x 53.98mm)
    const targetRatio = 1.586;
    const tolerance = 0.3; // Allow 30% variation for different photos

    final difference = (aspectRatio - targetRatio).abs();
    final normalizedDifference = difference / targetRatio;

    // Return score between 0 and 1 (1 = perfect match, 0 = no match)
    return max(0.0, 1.0 - (normalizedDifference / tolerance));
  }

  /// Analyze colors common to credit cards
  double _analyzeCardColors(img.Image image) {
    int totalPixels = image.width * image.height;
    int plasticLikePixels = 0;

    // Sample pixels to check for credit card-like colors
    int sampleStep = max(1, totalPixels ~/ 1000); // Sample ~1000 pixels

    for (int y = 0; y < image.height; y += sampleStep) {
      for (int x = 0; x < image.width; x += sampleStep) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();

        // Check for plastic-like colors (whites, blues, blacks common on cards)
        // Also look for glossy/shiny appearances that plastic has
        if (_isCardColor(r, g, b) || _isPlasticGloss(r, g, b)) {
          plasticLikePixels++;
        }
      }
    }

    double colorRatio = plasticLikePixels / (totalPixels / (sampleStep * sampleStep));
    return min(1.0, colorRatio * 1.5); // Amplify the signal
  }

  /// Check if RGB values represent typical credit card colors
  bool _isCardColor(int r, int g, int b) {
    // Common credit card colors: white, black, blue, silver, gold
    // Also holographic/shimmer colors

    // Very light or very dark (common backgrounds)
    if ((r + g + b < 50) || (r + g + b > 680)) return true;

    // Blues (very common on Visa/Mastercard)
    if (b > r + 30 && b > g + 30) return true;

    // Metallic colors (gold, silver)
    if (((r > 180 && g > 120 && b < 150)) || // Gold-ish
        (r > 160 && g > 160 && b > 160 && r - g < 20)) { // Silver
      return true;
    }

    // Holographic/iridescent (modern cards)
    if ((r - g).abs() < 50 && (g - b).abs() < 50 && r > 100) return true;

    return false;
  }

  /// Check for plastic-like glossy/shiny appearance
  bool _isPlasticGloss(int r, int g, int b) {
    // Plastic surfaces often have subtle color variations
    final brightness = (r + g + b) / 3;
    return brightness > 120 && brightness < 240;
  }

  /// Simple edge detection to find card boundaries
  double _detectCardEdges(img.Image image) {
    // Look for clean, sharp edges characteristic of card borders
    int edgePixels = 0;
    int totalSamples = 0;

    // Sample edges around the border
    int borderWidth = 10; // Check 10 pixels from edge

    // Top and bottom edges
    for (int x = borderWidth; x < image.width - borderWidth; x += 5) {
      // Top edge
      final topPixel = image.getPixel(x, borderWidth);
      final innerTopPixel = image.getPixel(x, borderWidth + 20);
      if (_isSharpEdge(topPixel, innerTopPixel)) {
        edgePixels++;
      }
      totalSamples++;

      // Bottom edge
      final bottomPixel = image.getPixel(x, image.height - borderWidth);
      final innerBottomPixel = image.getPixel(x, image.height - borderWidth - 20);
      if (_isSharpEdge(bottomPixel, innerBottomPixel)) {
        edgePixels++;
      }
      totalSamples++;
    }

    // Left and right edges
    for (int y = borderWidth; y < image.height - borderWidth; y += 5) {
      // Left edge
      final leftPixel = image.getPixel(borderWidth, y);
      final innerLeftPixel = image.getPixel(borderWidth + 20, y);
      if (_isSharpEdge(leftPixel, innerLeftPixel)) {
        edgePixels++;
      }
      totalSamples++;

      // Right edge
      final rightPixel = image.getPixel(image.width - borderWidth, y);
      final innerRightPixel = image.getPixel(image.width - borderWidth - 20, y);
      if (_isSharpEdge(rightPixel, innerRightPixel)) {
        edgePixels++;
      }
      totalSamples++;
    }

    if (totalSamples == 0) return 0.0;
    return min(1.0, edgePixels / totalSamples * 2.0); // 2x multiplier for stronger signal
  }

  /// Check if pixels represent a sharp edge (typical of card borders)
  bool _isSharpEdge(img.Pixel pixel1, img.Pixel pixel2) {
    const threshold = 30;
    final r1 = pixel1.r.toInt(), g1 = pixel1.g.toInt(), b1 = pixel1.b.toInt();
    final r2 = pixel2.r.toInt(), g2 = pixel2.g.toInt(), b2 = pixel2.b.toInt();

    // Calculate color difference
    final diffR = (r1 - r2).abs();
    final diffG = (g1 - g2).abs();
    final diffB = (b1 - b2).abs();
    final totalDiff = diffR + diffG + diffB;

    // Sharp edges have significant color differences
    return totalDiff > 100; // Threshold for edge detection
  }

  /// Analyze card shape and proportions
  double _analyzeCardShape(img.Image image) {
    // Credit cards have specific proportions and look more manufactured

    // Check if image looks like a well-composed photo (not random)
    final compositionScore = _analyzeComposition(image);

    // Check for symmetry (cards are often centered)
    final symmetryScore = _analyzeSymmetry(image);

    // Combine for shape analysis
    return (compositionScore + symmetryScore) / 2.0;
  }

  /// Analyze if image looks well-composed (common for card photos)
  double _analyzeComposition(img.Image image) {
    // Simple composition check - avoid images that are mostly one color
    int uniqueColors = 0;
    Set<int> colorSet = {};

    int sampleStep = max(1, sqrt(image.width * image.height) ~/ 20); // Sample ~400 pixels

    for (int y = sampleStep; y < image.height; y += sampleStep) {
      for (int x = sampleStep; x < image.width; x += sampleStep) {
        final pixel = image.getPixel(x, y);
        final color = (pixel.r.toInt() << 16) | (pixel.g.toInt() << 8) | pixel.b.toInt();

        // Round to reduce noise but preserve main colors
        final roundedColor = color & 0xF0F0F0;
        colorSet.add(roundedColor);

        if (colorSet.length > 100) break; // Reasonable number of unique colors
      }
    }

    // Credit card photos usually have 10-50 distinct colors
    if (colorSet.length >= 8 && colorSet.length <= 60) {
      return min(1.0, colorSet.length / 35.0); // Normalize to 0-1 range
    }

    return 0.0;
  }

  /// Analyze symmetry (cards are often photographed centered)
  double _analyzeSymmetry(img.Image image) {
    // Simple horizontal symmetry check
    double symmetryScore = 0.0;
    int checks = 0;

    for (int y = 10; y < image.height - 10; y += 20) {
      for (int x = 0; x < image.width ~/ 4; x += 10) {
        final leftPixel = image.getPixel(x, y);
        final rightPixel = image.getPixel(image.width - 1 - x, y);

        if (_pixelsSimilar(leftPixel, rightPixel)) {
          symmetryScore += 1.0;
        }
        checks++;
      }
    }

    if (checks == 0) return 0.0;
    return symmetryScore / checks;
  }

  /// Check if two pixels are similar in color
  bool _pixelsSimilar(img.Pixel pixel1, img.Pixel pixel2) {
    const threshold = 30;
    final r1 = pixel1.r.toInt(), g1 = pixel1.g.toInt(), b1 = pixel1.b.toInt();
    final r2 = pixel2.r.toInt(), g2 = pixel2.g.toInt(), b2 = pixel2.b.toInt();

    return (r1 - r2).abs() < threshold &&
           (g1 - g2).abs() < threshold &&
           (b1 - b2).abs() < threshold;
  }

  /// Analyze if image size is typical for credit card photos
  double _analyzeCardSize(img.Image image) {
    // Credit cards are about 3.375" x 2.125" (ratio 1.586:1)
    // Held at typical arm's length, they appear ~200-600 pixels in longest dimension

    final maxDimension = max(image.width, image.height);
    const minCardSize = 150;   // Minimum reasonable card size in pixels
    const maxCardSize = 800;   // Maximum reasonable card size in pixels

    if (maxDimension >= minCardSize && maxDimension <= maxCardSize) {
      // Good size range, score based on how ideal the size is
      const idealSize = 350;
      final sizeDiff = (maxDimension - idealSize).abs();
      return max(0.0, 1.0 - (sizeDiff / idealSize));
    }

    return 0.3; // Some score even for non-ideal sizes
  }

  /// Map trained category names to UI enum categories (stub implementation)
  DetectionCategory? _mapTrainedCategoryToEnum(String trainedCategory) {
    switch (trainedCategory) {
      case 'credit_card': return DetectionCategory.creditCard;
      case 'api_keys': return DetectionCategory.apiKeys;
      case 'ui_pattern': return DetectionCategory.uiPattern;
      case 'secure_document': return DetectionCategory.secureDocument;
      default: return null;
    }
  }

  /// Get service status for debugging
  @override
  Future<Map<String, dynamic>> getServiceStatus() async {
    return {
      'services_initialized': _initialized,
      'available_analyses': ['credit_card'],
      'platform': 'web',
      'note': 'ML model not available on web platform',
    };
  }

  /// Clean up resources
  @override
  void dispose() {
    _initialized = false;
  }
}
