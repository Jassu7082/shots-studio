import 'package:flutter/material.dart';
import 'package:shots_studio/services/analytics/analytics_service.dart';
import 'package:shots_studio/services/prefilter_service.dart';
import 'package:shots_studio/services/ml_prefilter_interface.dart';

class PrefilterLevelDialog extends StatefulWidget {
  final Function(String)? onPrefilterModeSelected;

  const PrefilterLevelDialog({
    super.key,
    this.onPrefilterModeSelected,
  });

  static Future<bool?> show(BuildContext context, {
    Function(String)? onPrefilterModeSelected,
  }) async {
   AnalyticsService().logFeatureUsed('prefilter_level_dialog_shown');

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PrefilterLevelDialog(
        onPrefilterModeSelected: onPrefilterModeSelected,
      ),
    );
  }

  @override
  State<PrefilterLevelDialog> createState() => _PrefilterLevelDialogState();
}

class _PrefilterLevelDialogState extends State<PrefilterLevelDialog> {
  PrefilterMode _selectedMode = PrefilterMode.light;

  @override
  void initState() {
    super.initState();
    _loadCurrentPrefilterMode();
  }

  Future<void> _loadCurrentPrefilterMode() async {
    final prefs = PrefilterService();
    final mode = await prefs.getPrefilterMode();
    setState(() {
      _selectedMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      icon: Icon(
        Icons.shield,
        color: theme.colorScheme.primary,
        size: 48,
      ),
      title: Text(
        'Privacy Filter Settings',
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
          children: [
            Text(
              'Choose the privacy protection level for screenshots before sending them to AI services.',
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            _buildModeOption(
              PrefilterMode.none,
              'No Protection',
              'Send all screenshots without privacy checks',
              Icons.warning,
              theme,
            ),
            const SizedBox(height: 12),
            _buildModeOption(
              PrefilterMode.light,
              'Light Protection (Recommended)',
              'Block credit cards and basic sensitive information',
              Icons.security,
              theme,
            ),
            const SizedBox(height: 12),
            _buildModeOption(
              PrefilterMode.deep,
              'Deep Protection',
              'Block financial data, credentials, and more sensitive content',
              Icons.verified_user,
              theme,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: theme.colorScheme.secondary,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Privacy Assurance',
                        style: TextStyle(
                          color: theme.colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'All privacy checks happen locally on your device. No screenshots are sent externally until you approve them.',
                    style: TextStyle(
                      color: theme.colorScheme.onSecondaryContainer,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton.icon(
          icon: Icon(Icons.skip_next, size: 18),
          label: const Text('Skip for Now'),
          style: TextButton.styleFrom(
            foregroundColor: theme.colorScheme.onSecondaryContainer,
          ),
          onPressed: () {
            AnalyticsService().logFeatureUsed('prefilter_dialog_skipped');
            Navigator.of(context).pop(false);
          },
        ),
        FilledButton.icon(
          icon: Icon(Icons.check, size: 18),
          label: const Text('Continue'),
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
          ),
          onPressed: () => _savePrefilterMode(context),
        ),
      ],
      actionsPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
    );
  }

  Widget _buildModeOption(
    PrefilterMode mode,
    String title,
    String description,
    IconData icon,
    ThemeData theme,
  ) {
    final isSelected = _selectedMode == mode;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedMode = mode;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer.withOpacity(0.3)
              : theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary.withOpacity(0.5)
                : theme.colorScheme.outline.withOpacity(0.2),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Radio<PrefilterMode>(
              value: mode,
              groupValue: _selectedMode,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedMode = value;
                  });
                }
              },
              activeColor: theme.colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        icon,
                        size: 18,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _savePrefilterMode(BuildContext context) async {
    final prefs = PrefilterService();
    await prefs.setPrefilterMode(_selectedMode);

    if (widget.onPrefilterModeSelected != null) {
      widget.onPrefilterModeSelected!(_selectedMode.name);
    }

    AnalyticsService().logFeatureUsed('prefilter_mode_selected');
    AnalyticsService().logFeatureAdopted('prefilter_mode_${_selectedMode.name}');

    Navigator.of(context).pop(true);
  }
}
