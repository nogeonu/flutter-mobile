class ApiConfig {
  const ApiConfig._();

  /// `flutter run --dart-define=USE_LOCAL_BACKEND=true` 로 실행하면 로컬 백엔드로 전환됩니다.
  static const bool _useLocalBackend =
      bool.fromEnvironment('USE_LOCAL_BACKEND', defaultValue: false);

  static const String _localBaseUrl = 'http://127.0.0.1:8000';
  static const String _remoteBaseUrl = 'http://34.42.223.43:8000';

  static String get baseUrl =>
      _useLocalBackend ? _localBaseUrl : _remoteBaseUrl;

  static Uri buildUri(String path, [Map<String, dynamic>? query]) {
    final uri = Uri.parse('$baseUrl$path');
    if (query == null || query.isEmpty) return uri;
    final queryMap =
        query.map((key, value) => MapEntry(key, value.toString()));
    return uri.replace(queryParameters: {
      ...uri.queryParameters,
      ...queryMap,
    });
  }
}
