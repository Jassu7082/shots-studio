# 🚀 Deploying Your Trained ML Model to Shots Studio

## 📍 **Exact Location and Structure**

### **Required File Structure:**
```
shots_studio/
├── assets/
│   ├── ml_models/
│   │   └── sensitive_content_detector.tflite  ← YOUR TRAINED MODEL GOES HERE
│   ├── other assets...
└── lib/services/ml_prefilter_service.dart     ← Auto-loads your model
```

### **Model File Path:**
```
shots_studio/assets/ml_models/sensitive_content_detector.tflite
```

## 🛠️ **How Your Model Gets Loaded**

The app automatically loads your model at startup:

```dart
// In ml_prefilter_service.dart - Happens automatically
Future<void> initializeModels() async {
  try {
    _sensitiveContentDetector = await Interpreter.fromAsset(
      'assets/ml_models/sensitive_content_detector.tflite'  // ← YOUR MODEL
    );
    print('✅ Custom trained model loaded!');
  } catch (e) {
    print('⚠️ Model not found, using fallback...');
  }
}
```

## 📋 **Model Requirements Checklist**

### **Input Format:**
- **Shape:** `[1, 224, 224, 3]` (batch=1, height=224, width=224, RGB=3)
- **Data Type:** `Float32` (normalized 0-1)
- **Image Size:** 224x224 pixels (square)

### **Output Format:**
- **Shape:** `[1, 4]` (4 probabilities for your categories)
- **Data Type:** `Float32`
- **Activation:** None required (app handles sigmoid)
- **Order:** `[credit_card, api_keys, ui_pattern, secure_document]`

### **Example Model Output:**
```python
# Your model predictions (before sigmoid)
[-2.1, 1.5, -0.8, 0.2]  # Raw logits

# App applies sigmoid to get probabilities
[0.11, 0.82, 0.31, 0.55]  # Probabilities (0-1)
```

## 🎯 **Model Performance Targets**

| Metric | Target | Why |
|--------|--------|-----|
| **File Size** | <100KB | Mobile download/app size |
| **Inference** | <500ms | User experience |
| **Accuracy** | >90% | Privacy protection |
| **Memory** | <50MB | Mobile device limits |

## 📦 **Deployment Steps**

### **Step 1: Train Your Model**
Follow the `ML_TRAINING_GUIDE.md` to create your TFLite model.

### **Step 2: Export as TFLite**
```python
# Final step in training script
converter = tf.lite.TFLiteConverter.from_keras_model(final_model)
converter.optimizations = [tf.lite.Optimize.DEFAULT]
converter.target_spec.supported_types = [tf.int8]
converter.representative_dataset = representative_dataset_fn

tflite_model = converter.convert()
with open('sensitive_content_detector.tflite', 'wb') as f:
    f.write(tflite_model)

print(f"✅ Model saved: {len(tflite_model)} bytes")
```

### **Step 3: Place in App**
```bash
# Copy your trained model to this exact location:
cp sensitive_content_detector.tflite shots_studio/assets/ml_models/

# Verify file exists:
ls -la shots_studio/assets/ml_models/
# -rw-r--r-- 1 user group 45231 Oct 18 21:32 sensitive_content_detector.tflite
```

### **Step 4: Rebuild App**
```bash
cd shots_studio
flutter pub get
flutter build apk  # or flutter build ios
```

## 🔍 **Testing Your Model**

### **Debug Your Model:**
1. **Start the app** with your model in place
2. **Check logs** for "Custom trained model loaded!"
3. **Take screenshots** of sensitive content
4. **Verify blocking** behavior

### **What Happens if Model Missing:**
- App starts normally (no crash)
- Falls back to computer vision
- Credit card detection still works
- Logs: "Model not found, using fallback..."

## 🎨 **Model Input Processing**

The app preprocesses images exactly like this:

```dart
// Image preprocessing (matches your training)
Future<Float32List> _preprocessImageForML(Uint8List imageBytes) async {
  final image = img.decodeImage(imageBytes);
  final resized = img.copyResize(image, width: 224, height: 224);
  final normalized = Float32List(224 * 224 * 3);

  int idx = 0;
  for (int y = 0; y < 224; y++) {
    for (int x = 0; x < 224; x++) {
      final pixel = resized.getPixel(x, y);
      // RGB → 0-1 normalized
      normalized[idx++] = pixel.r / 255.0;
      normalized[idx++] = pixel.g / 255.0;
      normalized[idx++] = pixel.b / 255.0;
    }
  }
  return normalized;
}
```

## 🚨 **Troubleshooting**

### **Model Not Loading:**
```
❌ Error: "Interpreter.fromAsset failed"

✅ Check:
- File exists: assets/ml_models/sensitive_content_detector.tflite
- Pubspec.yaml includes: assets/ml_models/
- Model is valid TFLite format
- File size < 100MB
```

### **Wrong Predictions:**
```
❌ Cards not detected, everything else blocked

✅ Check:
- Input shape matches: [1,224,224,3]
- Output shape matches: [1,4]
- Quantization settings
- Training labels match app expectations
```

### **Performance Issues:**
```
❌ Inference too slow (>1 second)

✅ Solutions:
- Quantize to INT8
- Reduce model complexity
- Use MobileNetV2 backbone
- Test on target device
```

## 📊 **Model Versioning**

### **Naming Convention:**
```
sensitive_content_detector_v1.tflite    // Version 1
sensitive_content_detector_v2.tflite    // Version 2 (A/B testing)
```

### **Update Process:**
1. Train improved model
2. Export as `v2.tflite`
3. Update code to load new model
4. Test rollback capability

## consiguió **Complete Integration Example**

Here's exactly how your trained model integrates:

```dart
// When user takes screenshot
Future<void> analyzeScreenshot(Uint8List screenshotBytes) async {
  // 1. Try ML model first
  final mlResult = await _mlService.analyzeImage(screenshotBytes, mode);

  if (mlResult.detectedCategories.isNotEmpty) {
    // 2. Show UI warning
    showPrefilterBlockedDialog(mlResult.detectedCategories);

    // 3. Don't send to Gemini!
    return;
  }

  // 4. Safe - proceed to AI analysis
  sendToGemini(screenshotBytes);
}
```

---

## 🎯 **Summary**

**Your trained model goes here:**
```
📁 shots_studio/assets/ml_models/sensitive_content_detector.tflite
```

**App loads it automatically and uses for detection with computer vision fallback.**
