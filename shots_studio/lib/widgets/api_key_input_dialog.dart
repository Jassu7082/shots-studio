import 'package:flutter/material.dart';
import 'package:shots_studio/services/analytics/analytics_service.dart';

class ApiKeyInputDialog extends StatefulWidget {
  final Function(String)? onApiKeySaved;

  const ApiKeyInputDialog({
    super.key,
    this.onApiKeySaved,
  });

  static Future<bool?> show(BuildContext context, {
    Function(String)? onApiKeySaved,
  }) async {
    AnalyticsService().logFeatureUsed('api_key_dialog_shown');

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ApiKeyInputDialog(
        onApiKeySaved: onApiKeySaved,
      ),
    );
  }

  @override
  State<ApiKeyInputDialog> createState() => _ApiKeyInputDialogState();
}

class _ApiKeyInputDialogState extends State<ApiKeyInputDialog> {
  final TextEditingController _apiKeyController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _obscureText = true;

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      icon: Icon(
        Icons.key,
        color: theme.colorScheme.primary,
        size: 48,
      ),
      title: Text(
        'Enter API Key',
        style: TextStyle(
          color: theme.colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
        textAlign: TextAlign.center,
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'To use AI analysis, you need to provide your Gemini API key. This will be stored locally on your device.',
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _apiKeyController,
                obscureText: _obscureText,
                decoration: InputDecoration(
                  labelText: 'Gemini API Key',
                  hintText: 'Enter your API key here',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'API key is required';
                  }
                  if (value.trim().length < 20) {
                    return 'API key appears to be too short';
                  }
                  return null;
                },
                autofocus: true,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: theme.colorScheme.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Get your API key from Google AI Studio. It\'s completely free to start.',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton.icon(
          icon: Icon(Icons.cancel, size: 18),
          label: const Text('Cancel'),
          style: TextButton.styleFrom(
            foregroundColor: theme.colorScheme.onSecondaryContainer,
          ),
          onPressed: () {
            AnalyticsService().logFeatureUsed('api_key_dialog_cancelled');
            Navigator.of(context).pop(false);
          },
        ),
        FilledButton.icon(
          icon: Icon(Icons.save, size: 18),
          label: const Text('Save & Continue'),
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
          ),
          onPressed: () => _saveApiKey(context),
        ),
      ],
      actionsPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
    );
  }

  void _saveApiKey(BuildContext context) {
    if (_formKey.currentState?.validate() ?? false) {
      final apiKey = _apiKeyController.text.trim();
      if (widget.onApiKeySaved != null) {
        widget.onApiKeySaved!(apiKey);
      }
      AnalyticsService().logFeatureUsed('api_key_saved');
      Navigator.of(context).pop(true);
    } else {
      AnalyticsService().logFeatureUsed('api_key_validation_failed');
    }
  }
}
