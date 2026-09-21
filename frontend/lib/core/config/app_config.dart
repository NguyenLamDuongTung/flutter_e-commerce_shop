import 'package:flutter/foundation.dart';

abstract final class AppConfig {
  static const String appName = 'Nova Store';

  static String get apiBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:8080/api';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:8080/api';

      default:
        return 'http://localhost:8080/api';
    }
  }

  static String resolveImageUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '';
    }

    final imageUrl = value.trim();

    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return imageUrl;
    }

    final apiUri = Uri.parse(apiBaseUrl);
    final serverOrigin = '${apiUri.scheme}://${apiUri.host}:${apiUri.port}';

    if (imageUrl.startsWith('/')) {
      return '$serverOrigin$imageUrl';
    }

    return '$serverOrigin/$imageUrl';
  }
}
