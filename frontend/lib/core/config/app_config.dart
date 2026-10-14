class AppConfig {
  const AppConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8081/api',
  );

  static String get backendBaseUrl {
    final uri = Uri.parse(apiBaseUrl);

    return Uri(
      scheme: uri.scheme,
      host: uri.host,
      port: uri.hasPort ? uri.port : null,
    ).toString().replaceFirst(RegExp(r'/$'), '');
  }

  static String resolveImageUrl(String? imageUrl) {
    final value = imageUrl?.trim() ?? '';

    if (value.isEmpty) {
      return '';
    }

    if (value.startsWith('http://') ||
        value.startsWith('https://') ||
        value.startsWith('data:') ||
        value.startsWith('blob:')) {
      return value;
    }

    final normalizedPath = value.startsWith('/') ? value : '/$value';

    return '$backendBaseUrl$normalizedPath';
  }
}
