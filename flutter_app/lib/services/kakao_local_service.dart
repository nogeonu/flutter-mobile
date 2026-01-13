import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/map_config.dart';

class KakaoPlace {
  KakaoPlace({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.distanceMeters,
    this.phone,
    this.placeUrl,
  });

  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double distanceMeters;
  final String? phone;
  final String? placeUrl;

  factory KakaoPlace.fromJson(Map<String, dynamic> json) {
    final distanceRaw = json['distance'];
    final distance = distanceRaw is String
        ? double.tryParse(distanceRaw) ?? 0
        : (distanceRaw as num?)?.toDouble() ?? 0;

    return KakaoPlace(
      name: json['place_name'] as String,
      address: (json['road_address_name'] as String?)?.isNotEmpty == true
          ? json['road_address_name'] as String
          : (json['address_name'] as String?) ?? '',
      latitude: double.parse(json['y'] as String),
      longitude: double.parse(json['x'] as String),
      distanceMeters: distance,
      phone: (json['phone'] as String?)?.isNotEmpty == true
          ? json['phone'] as String
          : null,
      placeUrl: json['place_url'] as String?,
    );
  }
}

class KakaoLocalService {
  const KakaoLocalService._();

  static const _baseUrl = 'https://dapi.kakao.com/v2/local';

  static Future<List<KakaoPlace>> fetchNearbyPharmacies({
    required double latitude,
    required double longitude,
    int radius = 2000,
    int size = 5,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl/search/category.json?category_group_code=PM9&x='
      '$longitude&y=$latitude&radius=$radius&sort=distance&size=$size',
    );

    final response = await http.get(
      uri,
      headers: {
        HttpHeaders.authorizationHeader: 'KakaoAK ${MapConfig.restApiKey}',
      },
    );

    if (response.statusCode != 200) {
      throw HttpException('카카오 장소 검색 실패: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final documents = (data['documents'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    return documents.map(KakaoPlace.fromJson).toList();
  }
}
