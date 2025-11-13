class MapConfig {
  const MapConfig._();

  /// Kakao 지도/내비게이션 연동에 사용할 키들.
  static const nativeAppKey = '88e57c918c6ebc263d135b41ead8aadf';
  static const restApiKey = 'f100cc682eedd7bd6626894fbb44bbce';
  static const javascriptKey = 'e4e515da6e25f9520bc57a762841ff95';
  static const adminKey = '8befa7ec2cea18655eb85e058dd62532';

  /// kakao_map_plugin은 JavaScript 키를 사용하므로 아래 getter를 참고하세요.
  static const kakaoMapAppKey = javascriptKey;

  /// 병원 기본 정보
  static const hospitalName = '건양대학교병원';
  static const hospitalAddress = '대전 서구 관저동 176-1';
  static const hospitalLatitude = 36.353704;
  static const hospitalLongitude = 127.424936;
}
