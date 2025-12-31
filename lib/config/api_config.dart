import 'package:flutter/foundation.dart';

class ApiConfig {
  const ApiConfig._();

  /// `flutter run --dart-define=USE_LOCAL_BACKEND=true` 로 실행하면 로컬 백엔드로 전환됩니다.
  // 기본적으로는 main의 설정을 따릅니다 (개발 환경에 맞게 override 가능).
  static const bool _useLocalBackend =
      bool.fromEnvironment('USE_LOCAL_BACKEND', defaultValue: false);

  /// 예약/진료 API는 별도 백엔드를 쓰는 경우가 있어 분리합니다.
  static const bool _useLocalAppointmentBackend =
      bool.fromEnvironment('USE_LOCAL_APPOINTMENT_BACKEND', defaultValue: false);

  /// `flutter run --dart-define=USE_LOCAL_CHAT_BACKEND=true` 로 실행하면 로컬 채팅 백엔드로 전환됩니다.
  // 기본적으로는 main의 설정을 따릅니다 (개발 환경에 맞게 override 가능).
  static const bool _useLocalChatBackend =
      bool.fromEnvironment('USE_LOCAL_CHAT_BACKEND', defaultValue: true);

  /// `flutter run --dart-define=BASE_URL=...`로 직접 베이스 URL을 지정할 수 있습니다.
  static const String _baseUrlOverride =
      String.fromEnvironment('BASE_URL', defaultValue: '');

  /// `flutter run --dart-define=APPOINTMENT_BASE_URL=...`로 예약 API URL을 지정할 수 있습니다.
  static const String _appointmentBaseUrlOverride =
      String.fromEnvironment('APPOINTMENT_BASE_URL', defaultValue: '');

  /// `flutter run --dart-define=CHAT_BASE_URL=...`로 채팅 베이스 URL을 지정할 수 있습니다.
  static const String _chatBaseUrlOverride =
      String.fromEnvironment('CHAT_BASE_URL', defaultValue: '');

  // 로컬/원격 베이스 URL (개발 환경에 맞게 조정하세요)
  static const String _localBaseUrl = 'http://192.168.41.140:8000';
  static const String _remoteBaseUrl = 'http://34.42.223.43';

  // 채팅(백엔드 서비스)가 별도 포트에서 동작하는 경우를 대비해 chat용 base URL도 정의합니다.
  // Android 에뮬레이터는 10.0.2.2, 데스크톱/웹은 127.0.0.1을 사용합니다.
  static String get _localChatBaseUrl {
    if (kIsWeb) return 'http://127.0.0.1:8001';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8001';
    }
    return 'http://127.0.0.1:8001';
  }
  static const String _remoteChatBaseUrl = 'http://34.42.223.43:8001';

  static String get baseUrl {
    if (_baseUrlOverride.isNotEmpty) return _baseUrlOverride;
    return _useLocalBackend ? _localBaseUrl : _remoteBaseUrl;
  }

  static String get appointmentBaseUrl {
    if (_appointmentBaseUrlOverride.isNotEmpty) return _appointmentBaseUrlOverride;
    return _useLocalAppointmentBackend ? _localBaseUrl : _remoteBaseUrl;
  }

  static String get chatBaseUrl {
    if (_chatBaseUrlOverride.isNotEmpty) return _chatBaseUrlOverride;
    return _useLocalChatBackend ? _localChatBaseUrl : _remoteChatBaseUrl;
  }

  static Uri buildUri(String path, [Map<String, dynamic>? query]) {
    final uri = Uri.parse('$baseUrl$path');
    if (query == null || query.isEmpty) return uri;
    final queryMap = query.map((key, value) => MapEntry(key, value.toString()));
    return uri.replace(queryParameters: {...uri.queryParameters, ...queryMap});
  }

  static Uri buildAppointmentUri(String path, [Map<String, dynamic>? query]) {
    final uri = Uri.parse('$appointmentBaseUrl$path');
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
