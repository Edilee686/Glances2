/// Where the app points. Change this one line to switch environments.
///
///   Local Django (docker-compose), Android emulator:  http://10.0.2.2:8000
///   Local Django, real phone on the same wifi:        http://192.168.x.x:8000
///   Production:                                        https://glances.work
///
/// A real phone cannot reach "localhost" — that means the phone itself. Use
/// your PC's LAN address (run `ipconfig` and take the IPv4 of your wifi
/// adapter), and make sure Django is started with
/// `python manage.py runserver 0.0.0.0:8000` so it accepts outside connections.
class Config {
  static const String baseUrl = String.fromEnvironment(
    'GLANCES_API',
    defaultValue: 'http://10.0.2.2:8000',
  );

  static String get apiUrl => '$baseUrl/api';

  /// ws:// for http://, wss:// for https://
  static String get wsUrl =>
      baseUrl.replaceFirst(RegExp(r'^http'), 'ws');

  /// The backend treats a discovery candidate as "recent" for 10 minutes, or
  /// 2 minutes when ?mode=dev is passed. Dev mode makes testing far less
  /// tedious when you only have two accounts.
  static const bool devMode = true;
}
