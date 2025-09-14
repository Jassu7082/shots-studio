/// Enum representing different build sources/flavors for the app
enum BuildSource {
  fdroid('fdroid'),
  github('github'),
  playstore('playstore');

  const BuildSource(this.value);
  final String value;

  /// Get the current build source from compile-time configuration
  static BuildSource get current {
    // Check if build source is defined via compile-time constants
    const String buildSourceString = String.fromEnvironment('BUILD_SOURCE');

    if (buildSourceString.isNotEmpty) {
      // Try to find matching enum value
      for (BuildSource source in BuildSource.values) {
        if (source.value == buildSourceString.toLowerCase()) {
          return source;
        }
      }
    }

    // Default to fdroid if not specified
    return BuildSource.fdroid;
  }

  /// Check if the current build source allows update checking
  bool get allowsUpdateCheck {
    switch (this) {
      case BuildSource.fdroid:
        return false; // F-Droid handles updates through their store
      case BuildSource.github:
        return true; // GitHub releases can check for updates
      case BuildSource.playstore:
        return false; // Play Store handles updates
    }
  }

  bool get allowsInAppUpdates {
    switch (this) {
      case BuildSource.fdroid:
        return false;
      case BuildSource.github:
        return true; // GitHub releases can handle in-app updates
      case BuildSource.playstore:
        return true;
    }
  }

  /// Get a human-readable name for the build source
  String get displayName {
    switch (this) {
      case BuildSource.fdroid:
        return 'F-Droid';
      case BuildSource.github:
        return 'GitHub';
      case BuildSource.playstore:
        return 'Play Store';
    }
  }
}
