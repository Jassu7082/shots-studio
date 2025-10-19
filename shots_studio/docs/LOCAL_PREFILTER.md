# Local Prefilter Documentation

## Overview

The Local Prefilter is a privacy protection feature in Shots Studio that scans screenshots on-device for potentially sensitive information before sending them to external AI services (Gemini or Gemma). This ensures that sensitive data like credit card numbers, API keys, passwords, and other private information is never transmitted outside the user's device.

## How It Works

### Architecture

1. **OCR Processing**: Uses the existing Tesseract OCR engine to extract text from screenshots
2. **Pattern Matching**: Applies regex patterns and keyword detection against predefined sensitive categories
3. **Blocking Mechanism**: Prevents matching screenshots from being sent to AI services
4. **User Override**: Provides a dialog allowing users to override the block if needed

### Flow Diagram

```
Screenshot → OCR Scan → Pattern Match → {Allow/Block}
                                    ↓
                                Block Dialog (User Choice)
                      Allow Anyway → Send to AI
                         ↓
                      Don't Send → Skip
```

## Configuration

### Prefilter Modes

- **None**: Disables the prefilter entirely (not recommended)
- **Light**: Scans for commonly sensitive data (recommended default)
- **Deep**: Comprehensive scan including financial and credential data

### Settings Location

- **Settings → Privacy Prefilter**
- Default: Light mode (recommended)
- Can be changed per user preference

## Sensitive Categories

### Light Mode

| Category | Detection Methods | Examples |
|----------|-------------------|----------|
| Card Numbers | Regex + Format | Visa, Mastercard, Amex formats |
| CVV Codes | Regex + Keywords | CVV, CVC codes |
| API Keys | Regex + Keywords | API keys, tokens, secrets |
| Password Fields | Keywords + Context | Login forms, credentials |
| OTP Codes | Regex + Keywords | Verification codes |

### Deep Mode (Additional)

| Category | Detection Methods | Examples |
|----------|-------------------|----------|
| Private Keys | Regex | RSA/EC private keys |
| Financial Screens | Keywords + Currency | Bank balances, transactions |
| SSN/Social Security | Regex | National ID numbers |
| Email Credentials | Context + Regex | Emails with passwords |
| Transaction History | Keywords + Amounts | Receipt data |

## Implementation Details

### Files

```
assets/sensitive_definitions.json         # Detection patterns
lib/services/prefilter_service.dart       # Core service
lib/widgets/prefilter_blocked_dialog.dart # UI dialog
lib/services/screenshot_analysis_service.dart # Integration point
```

### Pattern Definition Format

```json
{
  "categories": {
    "category_name": {
      "regex": ["pattern1", "pattern2"],
      "keywords": ["keyword1", "keyword2"],
      "enabled_light": true,
      "enabled_deep": true
    }
  }
}
```

### OCR Text Extraction

- Uses existing `OCRService` (Tesseract backend)
- Supports both image files and bitmap data
- Automatically cleans temporary files after processing

## Privacy Guarantees

### On-Device Processing

- **All analysis occurs locally** on the user's device
- **No network calls** are made during prefilter checks
- **OCR text is processed in-memory** and discarded after analysis
- **No data leaves the device** without user consent

### Analytics

- **Blocked detections** are logged for improvement
- **Category information** is anonymized in analytics
- **User choice tracking** (send anyway/don't send) for UX studies

## Performance Considerations

### Speed Impact

- **Light Mode**: Minimal impact (~100-300ms per screenshot)
- **Deep Mode**: Moderate impact (~200-500ms per screenshot)
- **OCR Quality**: Depends on screenshot resolution and text size

### Resource Usage

- **Memory**: Low (OCR text ~10-50KB typical)
- **Battery**: Negligible difference from OCR alone
- **Storage**: No permanent storage of extracted text

## Customizing Categories

### Adding New Categories

1. Add new category to `assets/sensitive_definitions.json`
2. Define regex patterns (Dart flavor) and keywords
3. Set light/deep enablement flags
4. Update pattern matches in code if needed

### Testing Patterns

```dart
import 'package:shots_studio/services/prefilter_service.dart';

final service = PrefilterService();
final result = await service.analyzeScreenshot(screenshot, mode: PrefilterMode.deep);
print('Detected: ${result.detectedCategories}');
```

## User Experience

### Blocking Dialog Features

- Clear explanation of detected sensitive content
- Category-specific warnings (e.g., "Credit card numbers detected")
- List of potential risks if sent anyway
- Two choices: "Don't Send" (default) or "Send Anyway"

### Override Behavior

- User acknowledges risk by choosing "Send Anyway"
- No further prompts for the same screenshot processing
- Analytics track override decisions

## Future Enhancements

### Planned Features

- **Machine Learning Models**: Custom ML for better pattern detection
- **Custom Categories**: User-defined sensitive patterns
- **Batch Override**: Override entire batch decisions
- **Prefilter History**: View recently blocked screenshots

### Research Areas

- **False Positive Reduction**: Improve accuracy over time
- **International Currencies**: Additional currency pattern support
- **Image Recognition**: Direct image pattern detection (no OCR)

## Contributing

### Adding Detection Patterns

1. **Test thoroughly** with various screenshot examples
2. **Balance sensitivity** vs false positives
3. **Document examples** of what triggers the pattern
4. **Consider international variants** (dates, currencies, etc.)

### UI/UX Improvements

- **Accessibility**: Screen reader support for all dialogs
- **Themes**: Proper theming for blocked dialog
- **Localization**: User-facing strings for all categories

## Troubleshooting

### Common Issues

**Prefilter blocks legitimate screenshots**
- Try Light mode instead of Deep
- Check if screenshot contains monetary symbols (₹, $, etc.)
- Use "Send Anyway" for specific cases

**OCR fails to extract text**
- Ensure good screenshot quality
- Check image resolution (>1000px recommended)
- Verify text contrast is sufficient

**Prefilter settings not saving**
- Check app permissions for SharedPreferences
- Try restarting the app
- Verify settings storage space

### Debug Information

Enable developer mode to see:
- Prefilter processing time
- OCR confidence scores
- Matching pattern details
- Full text extraction (masked)

## Support

For issues with the Local Prefilter:

1. **Settings → Advanced Settings** (if available)
2. **Check Logs** for prefilter errors
3. **Test with sample screenshots** containing known patterns
4. **Report Issues** with reproduction steps and screenshot examples

---

*Document Version: 1.0.0*
*Last Updated: October 2025*
*Privacy Protection: Fully On-Device*
