import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:shots_studio/models/screenshot_model.dart';
import 'ml_prefilter_interface.dart';
import 'package:shots_studio/services/ml_prefilter_service.dart';

// Constants for screenshot tags
const String sensitiveTag = 'sensitive';
const String privacyBlockedTag = 'privacy-blocked';

/// Result of prefilter analysis
class PrefilterResult {
  final bool allowSend;
  final List<String> detectedCategories;
  final double confidence;
  final String? extractedText;

  PrefilterResult({
    required this.allowSend,
    required this.detectedCategories,
    this.confidence = 0.0,
    this.extractedText,
  });

  bool get hasDetections => detectedCategories.isNotEmpty;

  String get categoriesDisplay {
    if (detectedCategories.isEmpty) return '';
    return detectedCategories.map((cat) => _formatCategoryName(cat)).join(', ');
  }

  String _formatCategoryName(String category) {
    // Convert snake_case to Title Case
    return category
        .split('_')
        .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}

/// Complete result of screenshot analysis including updated screenshot with tags
class AnalysisResult {
  final PrefilterResult prefilterResult;
  final Screenshot updatedScreenshot;

  AnalysisResult({
    required this.prefilterResult,
    required this.updatedScreenshot,
  });

  bool get isSensitive => !prefilterResult.allowSend;
  bool get hasSensitiveTags => updatedScreenshot.tags.contains(sensitiveTag);
}

/// Service for local privacy prefiltering using ML-based detection
class PrefilterService {
  static final PrefilterService _instance = PrefilterService._internal();
  factory PrefilterService() => _instance;
  PrefilterService._internal();

  static const String _prefilterModePrefKey = 'prefilter_mode';
  static const String _defaultMode = 'light';

  late MLPrefilterService _mlPreilterService;
  bool _isInitialized = false;

  /// Initialize the service
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      try {
        _mlPreilterService = getMLPrefilterService();
        await _mlPreilterService.initializeModels();
        _isInitialized = true;
      } catch (e) {
        print('Error initializing ML prefilter service: $e');
        throw Exception('Failed to initialize prefilter service');
      }
    }
  }

  /// Get current prefilter mode from preferences
  Future<PrefilterMode> getPrefilterMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String modeString = prefs.getString(_prefilterModePrefKey) ?? _defaultMode;
      return PrefilterMode.fromString(modeString);
    } catch (e) {
      print('Error loading prefilter mode: $e');
      return PrefilterMode.light;
    }
  }

  /// Set prefilter mode in preferences
  Future<void> setPrefilterMode(PrefilterMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefilterModePrefKey, mode.name);
    } catch (e) {
      print('Error saving prefilter mode: $e');
    }
  }

  /// Analyze a screenshot for sensitive information using ML-based computer vision
  /// Returns both the analysis result and an updated screenshot with tags
  Future<AnalysisResult> analyzeScreenshot(
    Screenshot screenshot, {
    PrefilterMode? mode,
  }) async {
    // Ensure ML service is initialized
    await _ensureInitialized();

    // Use provided mode or get from preferences
    final PrefilterMode effectiveMode = mode ?? await getPrefilterMode();

    // If mode is NONE, allow immediately without analysis
    if (effectiveMode == PrefilterMode.none) {
      return AnalysisResult(
        prefilterResult: PrefilterResult(
          allowSend: true,
          detectedCategories: [],
        ),
        updatedScreenshot: screenshot,
      );
    }

    try {
      // Get image bytes for ML analysis
      final Uint8List? imageBytes = await _getScreenshotImageBytes(screenshot);
      if (imageBytes == null) {
        // No image data available, allow send (fail-open)
        return AnalysisResult(
          prefilterResult: PrefilterResult(
            allowSend: true,
            detectedCategories: [],
          ),
          updatedScreenshot: screenshot,
        );
      }

      // Perform ML-based analysis
      final mlResult = await _mlPreilterService.analyzeImage(imageBytes, effectiveMode);

      // Convert ML detection categories to display strings
      final detectedCategories = mlResult.detectedCategories.map((category) {
        return _convertDetectionCategoryToString(category);
      }).toList();

      // Check if sensitive content was detected and prepare updated screenshot
      Screenshot updatedScreenshot = screenshot;
      if (mlResult.containsSensitiveContent) {
        // Add sensitive tags to the screenshot
        final newTags = List<String>.from(screenshot.tags);
        if (!newTags.contains(sensitiveTag)) {
          newTags.add(sensitiveTag);
        }
        if (!newTags.contains(privacyBlockedTag)) {
          newTags.add(privacyBlockedTag);
        }

        updatedScreenshot = screenshot.copyWith(tags: newTags);
      }

      return AnalysisResult(
        prefilterResult: PrefilterResult(
          allowSend: mlResult.containsSensitiveContent ? false : true,
          detectedCategories: detectedCategories,
          confidence: mlResult.confidence,
        ),
        updatedScreenshot: updatedScreenshot,
      );
    } catch (e) {
      print('Error during prefilter analysis: $e');
      // Fail-open: allow send on any error
      return AnalysisResult(
        prefilterResult: PrefilterResult(
          allowSend: true,
          detectedCategories: [],
        ),
        updatedScreenshot: screenshot,
      );
    }
  }

  /// Get image bytes from screenshot for ML analysis
  Future<Uint8List?> _getScreenshotImageBytes(Screenshot screenshot) async {
    if (screenshot.bytes != null) {
      return screenshot.bytes;
    }

    if (screenshot.path != null) {
      try {
        final file = File(screenshot.path!);
        if (await file.exists()) {
          return await file.readAsBytes();
        }
      } catch (e) {
        print('Error reading screenshot file: $e');
      }
    }

    return null;
  }

  /// Convert ML detection category to display string
  String _convertDetectionCategoryToString(DetectionCategory category) {
    switch (category) {
      case DetectionCategory.creditCard:
        return 'Credit Card';
      case DetectionCategory.apiKeys:
        return 'API Keys';
      case DetectionCategory.uiPattern:
        return 'Login Form';
      case DetectionCategory.secureDocument:
        return 'Secure Document';
      case DetectionCategory.bankStatement:
        return 'Bank Statement';
      case DetectionCategory.apiDocumentation:
        return 'API Documentation';
      case DetectionCategory.passwordManager:
        return 'Password Manager';
      case DetectionCategory.cryptoWallet:
        return 'Crypto Wallet';
      case DetectionCategory.loginScreen:
        return 'Login Screen';
      case DetectionCategory.receipt:
        return 'Receipt';
      case DetectionCategory.bankApp:
        return 'Bank App';
    }
  }

  /// Analyze multiple screenshots
  Future<Map<String, AnalysisResult>> analyzeScreenshots(
    List<Screenshot> screenshots, {
    PrefilterMode? mode,
    Function(int current, int total)? onProgress,
  }) async {
    final results = <String, AnalysisResult>{};
    int current = 0;

    for (var screenshot in screenshots) {
      current++;
      onProgress?.call(current, screenshots.length);

      final result = await analyzeScreenshot(screenshot, mode: mode);
      results[screenshot.id] = result;
    }

    return results;
  }

  /// Check if prefilter is enabled
  Future<bool> isPrefilterEnabled() async {
    final mode = await getPrefilterMode();
    return mode != PrefilterMode.none;
  }

  /// Get statistics about ML models
  Future<Map<String, dynamic>> getDefinitionsStats() async {
    await _ensureInitialized();
    final mlStats = await _mlPreilterService.getServiceStatus();

    // For ML-based detection, we have different stats
    return {
      'detection_method': 'computer_vision_ml',
      'services_initializd': mlStats['services_initialized'],
      'available_analyses': mlStats['available_analyses'],
      'light_mode_categories': 1, // Credit card detection
      'deep_mode_categories': 3, // Credit card + receipt + bank interface
    };
  }
}
