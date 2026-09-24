class AppConfig {
  const AppConfig._();

  static const String apiBaseUrl = 'http://localhost:8081/api';

  static const String backendBaseUrl = 'http://localhost:8081';

  static String resolveImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.trim().isEmpty) {
      return '';
    }

    if (imageUrl.startsWith('http://') ||
        imageUrl.startsWith('https://')) {
      return imageUrl;
    }

    final normalizedPath = imageUrl.startsWith('/')
        ? imageUrl
        : '/$imageUrl';

    return '$backendBaseUrl$normalizedPath';
  }
}