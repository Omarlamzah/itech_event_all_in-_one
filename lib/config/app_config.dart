class AppConfig {
  // for live api laravel https://events.itechevent.com/api/public
  //Change this to your server IP/domain when deploying
  // For local development with physical device: use your machine's LAN IP (e.g. http://192.168.1.x/...)
  // For emulator: use http://10.0.2.2/...
  // Live production API
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://events.itechevent.com/api/public/index.php/api',
  );
  // Local dev (LAN IP / 10.0.2.2 for emulator):
  // static const String baseUrl = 'http://192.168.1.111/p/inscri/2026/jestion%20badign%202026%20v2/api/public/index.php/api';

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);

  static String get publicMobileBaseUrl =>
      '${baseUrl.replaceFirst(RegExp(r'/$'), '')}/public/mobile';

  static String get mediaBaseUrl {
    const indexApiSuffix = '/index.php/api';
    const apiSuffix = '/api';

    if (baseUrl.endsWith(indexApiSuffix)) {
      return baseUrl.substring(0, baseUrl.length - indexApiSuffix.length);
    }
    if (baseUrl.endsWith(apiSuffix)) {
      return baseUrl.substring(0, baseUrl.length - apiSuffix.length);
    }
    return baseUrl;
  }

  static String storageUrl(String path) {
    if (path.startsWith('http')) return path;

    final base = mediaBaseUrl.replaceFirst(RegExp(r'/$'), '');
    final normalizedPath = path.startsWith('/') ? path : '/$path';

    if (path.startsWith('/storage/') || path.startsWith('storage/')) {
      final cleanPath = path.replaceFirst(RegExp(r'^/?storage/'), '');
      return '$base/link/$cleanPath';
    }
    if (path.startsWith('/link/') || path.startsWith('link/')) {
      return '$base$normalizedPath';
    }
    return '$base/link$normalizedPath';
  }
}
