/// App-wide settings. Change [siteUrl] if your website lives at another address.
///
/// The app talks to `$siteUrl/api/...`. On Netlify that path is forwarded to the
/// Node.js server on Render (see `public/_redirects` in the website project).
/// You can also override it at build time:
///   flutter build apk --dart-define=SITE_URL=https://example.com
class AppConfig {
  static const String siteUrl = String.fromEnvironment(
    'SITE_URL',
    // Punycode form of www.الأكاديميةالعربية.com
    defaultValue: 'https://www.xn--igbhbafec8bu3f7ekgl8ebg.com',
  );

  static String get apiBase => '$siteUrl/api';

  static const String phone = '01001558689';
  static const String whatsapp = '201001558689';
  static const String mapsUrl = 'https://www.google.com/maps?q=30.032678400536835,31.20282638870303';
  static const String facebookUrl = 'https://www.facebook.com/share/1B6JUnoqUW/';

  /// Free hosting can take up to a minute to wake the server, so be patient.
  static const Duration timeout = Duration(seconds: 60);

  static const String version = '1.0.0';
}
