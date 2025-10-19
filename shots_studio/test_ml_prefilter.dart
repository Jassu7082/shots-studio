import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shots_studio/services/ml_prefilter_service.dart';
import 'package:shots_studio/services/prefilter_service.dart';
import 'package:shots_studio/models/screenshot_model.dart';

/// Simple test app for computer vision-based credit card detection
class MLPrefilterTestApp extends StatefulWidget {
  const MLPrefilterTestApp({super.key});

  @override
  State<MLPrefilterTestApp> createState() => _MLPrefilterTestAppState();
}

class _MLPrefilterTestAppState extends State<MLPrefilterTestApp> {
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  String _resultText = 'Select an image to analyze';
  bool _isAnalyzing = false;

  final MLPrefilterService _mlService = MLPrefilterService();
  final PrefilterService _prefilterService = PrefilterService();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = image;
        _resultText = 'Image selected. Tap "Analyze" to test computer vision detection.';
      });
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isAnalyzing = true;
      _resultText = 'Analyzing image...';
    });

    try {
      // Read image bytes
      final bytes = await _selectedImage!.readAsBytes();

      // Create proper Screenshot model
      final screenshot = Screenshot.fromBytes(
        id: 'test_credit_card_detection',
        bytes: bytes,
        fileName: 'test_image.jpg',
        filePath: _selectedImage!.path,
        initialTags: [],
        aiProcessed: false,
      );

      // Test prefilter service (which now uses computer vision)
      final result = await _prefilterService.analyzeScreenshot(
        screenshot,
        mode: PrefilterMode.light, // This will trigger credit card detection
      );

      final mlStats = await _mlService.getServiceStatus();

      setState(() {
        _resultText = '''
COMPUTER VISION ANALYSIS COMPLETE:

✅ NO EXTERNAL MODELS - Pure Algorithm-Based Detection
Available Analyses: ${mlStats['available_analyses'].join(', ')}

DETECTION RESULTS:
${result.hasDetections ? '🚨 SENSITIVE CONTENT DETECTED!' : '✅ Content appears safe'}

Detected Categories:
${result.detectedCategories.isNotEmpty
    ? result.detectedCategories.map((cat) => '• $cat').join('\n')
    : 'None detected'}

Confidence: ${(result.confidence * 100).round()}%
Allow Send: ${result.allowSend ? 'Yes' : 'BLOCKED'}

WHAT WE ANALYZED:
• Aspect Ratio (credit cards: ~1.586:1)
• Plastic Colors (blue, white, metallic)
• Boundary Edge Sharpness
• Image Composition & Symmetry
• Size validation (200-600px typical)
          ''';
      });

    } catch (e) {
      setState(() {
        _resultText = 'Error analyzing image: $e';
      });
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Computer Vision Prefilter Test'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_selectedImage != null)
                  Container(
                    height: 200,
                    width: 300,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(_selectedImage!.path),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _pickImage,
                  child: const Text('Select Image'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _selectedImage != null && !_isAnalyzing ? _analyzeImage : null,
                  child: _isAnalyzing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(),
                        )
                      : const Text('Analyze for Credit Cards'),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _resultText,
                    style: const TextStyle(fontFamily: 'monospace'),
                    textAlign: TextAlign.left,
                  ),
                ),
                const SizedBox(height: 20),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '🤖 NO ML MODELS USED - Pure Computer Vision Algorithms\n📱 Upload a photo of your physical credit card to test detection!',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// To run this test app, replace your main.dart content with:
// import 'test_ml_prefilter.dart';
// void main() => runApp(const MLPrefilterTestApp());
