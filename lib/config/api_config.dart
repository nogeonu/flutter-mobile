class ApiConfig {
  const ApiConfig._();

  /// `flutter run --dart-define=USE_LOCAL_BACKEND=true` 로 실행하면 로컬 백엔드로 전환됩니다.
  // 기본적으로는 main의 설정을 따릅니다 (개발 환경에 맞게 override 가능).
  static const bool _useLocalBackend =
      bool.fromEnvironment('USE_LOCAL_BACKEND', defaultValue: false);

  /// `flutter run --dart-define=USE_LOCAL_CHAT_BACKEND=true` 로 실행하면 로컬 채팅 백엔드로 전환됩니다.
  // 기본적으로는 main의 설정을 따릅니다 (개발 환경에 맞게 override 가능).
  static const bool _useLocalChatBackend =
      bool.fromEnvironment('USE_LOCAL_CHAT_BACKEND', defaultValue: false);

  // 로컬/원격 베이스 URL (개발 환경에 맞게 조정하세요)
  static const String _localBaseUrl = 'http://192.168.41.140:8000';
  static const String _remoteBaseUrl = 'http://34.42.223.43';

  // 채팅(백엔드 서비스)가 별도 포트에서 동작하는 경우를 대비해 chat용 base URL도 정의합니다.
  // 에뮬레이터에서 로컬 호스트에 접근하려면 Android 에뮬레이터의 경우 10.0.2.2를 사용합니다.
  static const String _localChatBaseUrl = 'http://10.0.2.2:8001';
  static const String _remoteChatBaseUrl = 'http://34.42.223.43:8001';

  static String get baseUrl =>
      _useLocalBackend ? _localBaseUrl : _remoteBaseUrl;

  static String get chatBaseUrl =>
      _useLocalChatBackend ? _localChatBaseUrl : _remoteChatBaseUrl;

  // static String get chatBaseUrl => _localChatBaseUrl; // 로컬용

  static Uri buildUri(String path, [Map<String, dynamic>? query]) {
    final uri = Uri.parse('$baseUrl$path');
    if (query == null || query.isEmpty) return uri;
    final queryMap = query.map((key, value) => MapEntry(key, value.toString()));
    return uri.replace(queryParameters: {...uri.queryParameters, ...queryMap});
  }

  static Uri buildChatUri(String path, [Map<String, dynamic>? query]) {
    final uri = Uri.parse('$chatBaseUrl$path');
    if (query == null || query.isEmpty) return uri;
    final queryMap = query.map((key, value) => MapEntry(key, value.toString()));
    return uri.replace(queryParameters: {...uri.queryParameters, ...queryMap});
  }
}
