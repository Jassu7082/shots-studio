import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/sponsorship_service.dart';
import '../../services/analytics/analytics_service.dart';
import '../../services/update_checker_service.dart';
import '../sponsorship/sponsorship_dialog.dart';
import '../update_dialog.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/build_source.dart';

class AboutSection extends StatelessWidget {
  final String appVersion;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const AboutSection({
    super.key,
    required this.appVersion,
    this.onTap,
    this.onLongPress,
  });

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $urlString');
    }
  }

  Future<void> _checkForUpdatesManually(BuildContext context) async {
    // Show loading indicator
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Checking for updates...')));

    try {
      final updateInfo = await UpdateCheckerService.checkForUpdates();

      if (updateInfo != null) {
        // Update is available, show dialog
        if (context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => UpdateDialog(updateInfo: updateInfo),
          );
        }
      } else {
        // No update available
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You are running the latest version!'),
            ),
          );
        }
      }
    } catch (e) {
      // Error occurred
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to check for updates: $e')),
        );
      }
    }
  }

  void _showSponsorshipDialog(BuildContext context) {
    final sponsorshipOptions = SponsorshipService.getAllOptions();

    // Route to fullscreen dialog
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder:
            (context) =>
                SponsorshipDialog(sponsorshipOptions: sponsorshipOptions),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Divider(color: theme.colorScheme.outline),
        ListTile(
          leading: Icon(Icons.code, color: theme.colorScheme.primary),
          title: Text(
            AppLocalizations.of(context)?.sourceCode ?? 'Source Code',
            style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
          ),
          subtitle: Text(
            'Contribute on GitHub',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          onTap: () {
            // Log analytics for source code access
            AnalyticsService().logFeatureUsed('source_code_accessed');
            AnalyticsService().logFeatureUsed('github_link_clicked');

            Navigator.pop(context);
            _launchURL('https://github.com/AnsahMohammad/shots-studio');
            // _launchURL('https://gitlab.com/mohdansah10/shots-studio');
          },
        ),
        ListTile(
          leading: Icon(Icons.favorite, color: Colors.redAccent),
          title: Text(
            AppLocalizations.of(context)?.support ?? 'Support',
            style: TextStyle(color: Colors.greenAccent),
          ),
          subtitle: Text(
            'Sponsor the project',
            style: TextStyle(color: Colors.greenAccent),
          ),
          onTap: () {
            // Log analytics for sponsorship access
            AnalyticsService().logFeatureUsed('sponsorship_dialog_opened');
            AnalyticsService().logFeatureUsed('support_clicked');

            Navigator.pop(context);
            _showSponsorshipDialog(context);
            _launchURL(
              'https://Ansahmohammad.github.io/shots-studio/donation.html',
            );
            // _launchURL('https://shots-studio-854420.gitlab.io/donation.html');
          },
        ),
        Divider(color: theme.colorScheme.outline),
        ListTile(
          leading: Icon(Icons.info_outline, color: theme.colorScheme.primary),
          title: Text(
            AppLocalizations.of(context)?.about ?? 'About',
            style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
          ),
          subtitle: Text(
            'Version $appVersion (${BuildSource.current.displayName})',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          onTap: () {
            // Log analytics for about section interactions
            AnalyticsService().logFeatureUsed('about_section_clicked');

            if (onTap != null) {
              onTap!();
            }
            // Don't close drawer when tapping About to allow for multiple taps
          },
          onLongPress: () {
            if (onLongPress != null) {
              onLongPress!();
            }
          },
        ),
        // Only show update checker for builds that support it
        if (BuildSource.current.allowsUpdateCheck)
          ListTile(
            leading: Icon(
              Icons.system_update,
              color: theme.colorScheme.primary,
            ),
            title: Text(
              AppLocalizations.of(context)?.checkForUpdates ??
                  'Check for Updates',
              style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
            ),
            subtitle: Text(
              'Check for app updates',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
            onTap: () {
              // Log analytics for update check access
              AnalyticsService().logFeatureUsed('manual_update_check');

              // Close drawer first, then check for updates with a fresh context
              Navigator.pop(context);

              // Use a post-frame callback to ensure the drawer is closed before checking updates
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final navigatorContext = Navigator.of(context).context;
                _checkForUpdatesManually(navigatorContext);
              });
            },
          ),
      ],
    );
  }
}
