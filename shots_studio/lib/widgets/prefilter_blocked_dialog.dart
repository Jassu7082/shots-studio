import 'package:flutter/material.dart';
import 'package:shots_studio/services/prefilter_service.dart';
import 'package:shots_studio/services/analytics/analytics_service.dart';

/// Dialog shown when sensitive content is detected by the prefilter
class PrefilterBlockedDialog extends StatelessWidget {
  final PrefilterResult result;
  final VoidCallback? onSendAnyway;
  final VoidCallback? onCancel;

  const PrefilterBlockedDialog({
    super.key,
    required this.result,
    this.onSendAnyway,
    this.onCancel,
  });

  /// Show the dialog and return true if user wants to send anyway
  static Future<bool?> show(
    BuildContext context,
    PrefilterResult result,
  ) async {
    // Log analytics when sensitive content is detected
    AnalyticsService().logFeatureUsed('prefilter_blocked');
    AnalyticsService().logFeatureAdopted(
      'sensitive_content_detected_${result.detectedCategories.join("_")}',
    );

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PrefilterBlockedDialog(
          result: result,
          onSendAnyway: () {
            // Log when user chooses to send anyway
            AnalyticsService().logFeatureUsed('prefilter_override');
            Navigator.of(context).pop(true);
          },
          onCancel: () {
            // Log when user cancels
            AnalyticsService().logFeatureUsed('prefilter_respected');
            Navigator.of(context).pop(false);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      icon: Icon(
        Icons.shield_outlined,
        color: theme.colorScheme.error,
        size: 48,
      ),
      title: Text(
        'Sensitive Content Detected',
        style: TextStyle(
          color: theme.colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
        textAlign: TextAlign.center,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warning message
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.error.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.error,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This screenshot appears to contain sensitive information that should not be sent to AI services.',
                      style: TextStyle(
                        color: theme.colorScheme.onErrorContainer,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Detected categories
            Text(
              'Detected:',
              style: TextStyle(
                color: theme.colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: result.detectedCategories.map((category) {
                return Chip(
                  label: Text(
                    _formatCategoryName(category),
                    style: TextStyle(
                      color: theme.colorScheme.onErrorContainer,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  backgroundColor: theme.colorScheme.errorContainer.withOpacity(0.5),
                  side: BorderSide(
                    color: theme.colorScheme.error.withOpacity(0.3),
                    width: 1,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Protection info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: theme.colorScheme.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Privacy Protection Active',
                          style: TextStyle(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This screenshot was analyzed locally on your device. No data was sent to external servers.',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Warning text
            Text(
              'Sending this screenshot to AI services may expose:',
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            ..._buildWarningList(theme),
          ],
        ),
      ),
      actions: [
        TextButton.icon(
          icon: Icon(Icons.close, size: 18),
          label: const Text('Don\'t Send'),
          style: TextButton.styleFrom(
            foregroundColor: theme.colorScheme.onSecondaryContainer,
          ),
          onPressed: onCancel ?? () => Navigator.of(context).pop(false),
        ),
        TextButton.icon(
          icon: Icon(Icons.warning_amber, size: 18),
          label: const Text('Send Anyway'),
          style: TextButton.styleFrom(
            foregroundColor: theme.colorScheme.error,
            backgroundColor: theme.colorScheme.errorContainer.withOpacity(0.3),
          ),
          onPressed: onSendAnyway ?? () => Navigator.of(context).pop(true),
        ),
      ],
      actionsPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
    );
  }

  List<Widget> _buildWarningList(ThemeData theme) {
    final warnings = _getWarningsForCategories(result.detectedCategories);
    return warnings.map((warning) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '• ',
              style: TextStyle(
                color: theme.colorScheme.error,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            Expanded(
              child: Text(
                warning,
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  List<String> _getWarningsForCategories(List<String> categories) {
    final warnings = <String>[];

    for (var category in categories) {
      switch (category) {
        case 'card_numbers':
          warnings.add('Credit/debit card numbers');
          break;
        case 'cvv_codes':
          warnings.add('CVV/CVC security codes');
          break;
        case 'api_keys':
          warnings.add('API keys or access tokens');
          break;
        case 'password_fields':
          warnings.add('Passwords or PINs');
          break;
        case 'private_keys':
          warnings.add('Private encryption keys');
          break;
        case 'transaction_screens':
          warnings.add('Financial transaction details');
          break;
        case 'social_security':
          warnings.add('Social security or national ID numbers');
          break;
        case 'email_credentials':
          warnings.add('Email addresses with credentials');
          break;
        case 'otp_codes':
          warnings.add('One-time passwords or verification codes');
          break;
      }
    }

    // Remove duplicates and return
    return warnings.toSet().toList();
  }

  String _formatCategoryName(String category) {
    // Convert snake_case to Title Case
    return category
        .split('_')
        .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}
