# ML Model Training Guide for Sensitive Content Detection

## 🎯 Overview

This guide explains how to train the custom ML model that detects sensitive content in screenshots. The model uses your exact 4 categories and is optimized for fast mobile inference.

## 🎖️ Categories to Train

1. **Credit Card** - Physical credit cards in photos
2. **API Keys** - API keys, tokens, secrets in screenshots
3. **UI Pattern** - Password fields, login screens, authentication UI
4. **Secure Document** - Bank apps, admin panels, transaction details

## 📊 Performance Requirements

| Requirement | Target | Why |
|-------------|---------|-----|
| **Model Size** | <100KB | Mobile apps can't handle large models |
| **Inference Time** | <1 second | Users expect instant feedback |
| **Accuracy** | >90% | Must be reliable for privacy |
| **Platforms** | iOS, Android, Web | Can't use platform-specific solutions |

## 🛠️ Training Tools Setup

### 1. Google Colab (Recommended for Training)

```python
# Clone training environment
!git clone https://github.com/your-repo/ml-training.git
!cd ml-training
!pip install -r requirements.txt

# Requirements include:
# - tensorflow==2.15.0
# - keras-cv
# - sklearn
# - opencv-python
# - albumentations
```

### 2. Dataset Collection

#### Credit Card Dataset
```python
# 5,000+ images needed
import kaggle
kaggle.api.dataset_download_files('mlg-ulb/creditcardfraud', unzip=True)

# Generate synthetic credit card images
from PIL import Image, ImageDraw, ImageFont
import random

def generate_credit_card_image():
    # Create realistic credit card background
    img = Image.new('RGB', (400, 250), color='#1a1a1a')
    draw = ImageDraw.Draw(img)

    # Add plastic-like gradient effects
    # Simulates photographic credit card images
    return img
```

#### API Keys Dataset
```python
# 3,000+ API key screenshots
def generate_api_key_screenshots():
    templates = [
        "Screenshots with API_KEY: sk-****",
        "Bearer tokens: ABC123DEF456",
        "GitHub Personal Access Tokens"
    ]

    for template in templates:
        # Generate varied screenshot compositions
        # Different UI themes, text sizes, layouts
        pass
```

#### UI Pattern Dataset
```python
# 4,000+ login/password UI screenshots
def generate_login_screens():
    patterns = [
        "Password: ********",
        "Confirm Password: ****",
        "PIN: 1234",
        "Login Form Fields"
    ]

    # Generate with different UI frameworks:
    # - Android screens
    # - iOS screens
    # - Web forms
    # - Desktop apps
```

#### Secure Document Dataset
```python
# 2,000+ banking/transaction screenshots
def generate_secure_documents():
    docs = [
        "Bank balance screens",
        "Transaction history",
        "Admin dashboards",
        "Wire transfer forms"
    ]
```

## 🏗️ Model Architecture

### Efficient Mobile Model (~50KB)

```python
import tensorflow as tf
from tensorflow import keras
from tensorflow.keras import layers

def create_mobile_detection_model():
    """Mobile-optimized model for screenshot analysis"""

    # Input: 224x224x3 (standard for mobile ML)
    inputs = keras.Input(shape=(224, 224, 3))

    # Use MobileNetV2 backbone (pre-trained, efficient)
    base_model = tf.keras.applications.MobileNetV2(
        input_tensor=inputs,
        include_top=False,
        weights='imagenet'
    )
    base_model.trainable = False  # Freeze for fine-tuning

    # Global pooling for classification
    x = layers.GlobalAveragePooling2D()(base_model.output)
    x = layers.Dropout(0.3)(x)  # Prevent overfitting

    # Multi-label classification (4 classes)
    outputs = layers.Dense(4, activation='sigmoid')(x)

    model = keras.Model(inputs=inputs, outputs=outputs)

    return model

# Training configuration
model = create_mobile_detection_model()
model.compile(
    optimizer='adam',
    loss='binary_crossentropy',  # Multi-label
    metrics=['accuracy']
)
```

### Training Process

```python
# 1. Data preparation
train_ds = tf.data.Dataset.from_tensor_slices((images, labels))
train_ds = train_ds.batch(32).prefetch(tf.data.AUTOTUNE)

# 2. Training
history = model.fit(
    train_ds,
    epochs=20,
    validation_data=val_ds,
    callbacks=[
        tf.keras.callbacks.EarlyStopping(patience=3),
        tf.keras.callbacks.ModelCheckpoint('best_model.h5')
    ]
)

# 3. Quantization for mobile deployment
def quantize_model(model_path):
    """Convert to int8 for tiny model size"""

    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    converter.representative_dataset = representative_dataset
    converter.target_spec.supported_types = [tf.int8]

    # Convert & save
    tflite_model = converter.convert()
    with open('sensitive_content_detector.tflite', 'wb') as f:
        f.write(tflite_model)

    print(f"Model size: {len(tflite_model)} bytes")
    # Target: <100KB
```

## 📈 Expected Results

### Training Performance (after 20 epochs)

| Metric | Expected | Notes |
|--------|-----------|-------|
| **Accuracy** | 92% | Credit cards easily detected |
| **Precision** | 89% | Low false positives |
| **Recall** | 91% | Catch sensitive content |
| **F1 Score** | 90% | Balanced performance |

### Per-Category Results

```python
# Example validation results
validation_results = {
    'credit_card': {'accuracy': 0.98, 'false_positives': 0.01},
    'api_keys': {'accuracy': 0.94, 'false_positives': 0.03},
    'ui_pattern': {'accuracy': 0.89, 'false_positives': 0.06},
    'secure_document': {'accuracy': 0.91, 'false_positives': 0.02}
}
```

## 🚀 Deployment Process

### 1. Export Model

```python
# After training, convert to TFLite
quantize_model('best_model.h5')

# Output: assets/ml_models/sensitive_content_detector.tflite
```

### 2. Integrate into App

```dart
// The app automatically loads the model:
// assets/ml_models/sensitive_content_detector.tflite

class MLPrefilterService {
  Interpreter? _sensitiveContentDetector;

  Future<void> initializeModels() async {
    try {
      _sensitiveContentDetector = await Interpreter.fromAsset(
        'assets/ml_models/sensitive_content_detector.tflite'
      );
    } catch (e) {
      print('ML model not available, using fallback');
    }
  }
}
```

### 3. Performance Testing

```dart
// Benchmark inference speed
final stopwatch = Stopwatch()..start();
final result = await _sensitiveContentDetector.run(input, output);
stopwatch.stop();

print('Inference time: ${stopwatch.elapsedMilliseconds}ms');
// Target: <1000ms on mobile
```

## 🔍 Dataset Validation

### Quality Checks

```python
def validate_dataset(images, labels):
    """Ensure dataset quality before training"""

    # Balance check
    label_counts = np.sum(labels, axis=0)
   	assert all(count > 1000 for count in label_counts), "Insufficient images per category"

    # Quality check
    for img_path in image_paths:
        img = cv2.imread(img_path)
        # Check resolution
        assert min(img.shape[:2]) > 100, "Image too small"
        # Check aspect ratio variety
        aspect = img.shape[1] / img.shape[0]
        assert 0.3 < aspect < 3.0, "Suspicious aspect ratio"

    print("✅ Dataset validation passed")
```

## 🏷️ Labeling Strategy

### Multi-Label Classification

```python
# Each image can have multiple labels (e.g., bank app + transaction)
def create_multi_label_annotations():
    labels = {
        'credit_card': 0,
        'api_keys': 1,
        'ui_pattern': 2,
        'secure_document': 3
    }

    # Example annotations
    annotations = {
        'bank_app_screenshot.jpg': [0, 3],  # credit_card + secure_document
        'api_documentation.png': [1],      # api_keys only
        'login_form.png': [2],             # ui_pattern only
        'receipt.jpg': [],                 # none (safe)
    }

    return annotations
```

### Annotation Tools

```python
# Use Label Studio or custom script
def annotate_images(image_dir):
    """Interactive annotation tool"""

    from IPython.display import display
    import ipywidgets as widgets

    # GUI for annotating each image
    # Checkbox for each category
    # Save annotations as JSON
    pass
```

## 🚨 Common Pitfalls

### Avoid These Issues:

1. **Class Imbalance**
   ```python
   # Check class distribution
   labels.sum(axis=0)  # Should be similar counts
   ```

2. **Overfitting**
   ```python
   # Monitor validation loss
   if val_loss > train_loss * 1.2:
       print("⚠️  Overfitting detected")
   ```

3. **Poor Quality Images**
   ```python
   # Validate image quality
   def check_image_quality(img):
       # Sharpness, contrast, noise checks
       # Reject blurry/low-quality images
       pass
   ```

## 📊 Monitoring & Improvement

### Post-Training Analysis

```python
def analyze_model_performance():
    """Detailed performance breakdown"""

    y_true, y_pred = get_predictions(test_dataset)

    # Per-category metrics
    for i, category in enumerate(['credit_card', 'api_keys', 'ui_pattern', 'secure_document']):
        precision, recall = calculate_metrics(y_true[:, i], y_pred[:, i])
        print(f"{category}: Precision {precision:.2f}, Recall {recall:.2f}")

    # Confusion matrix
    cm = confusion_matrix(y_true.argmax(axis=1), y_pred.argmax(axis=1))
    plot_confusion_matrix(cm)
```

### A/B Testing

```dart
// In-app testing different model versions
class ModelABTest {
  Future<ModelVersion> selectModelVersion() async {
    // Random selection for A/B testing
    return Random().nextBool()
        ? ModelVersion.new_trained_model
        : ModelVersion.fallback_algorithm;
  }
}
```

## 🎯 Success Metrics

### Model Acceptance Criteria

- **Size**: <100KB (TFLite quantized int8)
- **Speed**: <500ms on mobile devices
- **Accuracy**: >90% overall, 95%+ for credit cards
- **Privacy**: 100% local inference (no network calls)

### User Experience

- **Blocking Rate**: <2% false positives (user frustration)
- **Allow Rate**: >98% legitimate screenshots pass through
- **Speed Impact**: <1 second added to screenshot processing

## 🔄 Model Updates

### Retraining Process

```bash
# When new sensitive content types emerge:
1. Collect new dataset samples
2. Retrain model with original + new data
3. Quantize and test on-device performance
4. Release as app update
```

### Fallback Strategy

```dart
// In app: If model fails, use reliable computer vision
if (ml_result == null) {
  return await _fallbackComputerVision(imageBytes, mode);
}
```

## 📚 Resources

### Recommended Reading

1. **Mobile ML Best Practices**
   - TensorFlow Lite Guide
   - Model Quantization Techniques

2. **Dataset Creation**
   - Synthetic Data Generation
   - Data Augmentation Strategies

3. **Privacy-First ML**
   - Local Inference
   - Secure Model Deployment

### Tools & Frameworks

- **Training**: TensorFlow/Keras, PyTorch
- **Quantization**: TensorFlow Model Optimization Toolkit
- **Analysis**: Weights & Biases, TensorBoard
- **Dataset**: Roboflow, Labelbox, custom scripts
