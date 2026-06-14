class AppConfig {
  // for live api laravel https://events.itechevent.com/api/public 
  //Change this to your server IP/domain when deploying
  // For local development with physical device: use your machine's LAN IP (e.g. http://192.168.1.x/...)
  // For emulator: use http://10.0.2.2/...
  // Live production API
  static const String baseUrl = 'https://events.itechevent.com/api/public/index.php/api';
  // Local dev (LAN IP / 10.0.2.2 for emulator):
  // static const String baseUrl = 'http://192.168.1.111/p/inscri/2026/jestion%20badign%202026%20v2/api/public/index.php/api';

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
