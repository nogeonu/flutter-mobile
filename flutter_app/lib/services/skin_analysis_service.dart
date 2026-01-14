import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class SkinAnalysisResult {
  final String predictedClass;
  final String predictedCode;
  final double confidence;
  final Map<String, double> classProbabilities;
  final List<TopPrediction> top3Predictions;
  final String? heatmap; // Base64 인코딩된 히트맵 이미지
  final String status;
  final String? error;
  final String? warning;

  SkinAnalysisResult({
    required this.predictedClass,
    required this.predictedCode,
    required this.confidence,
    required this.classProbabilities,
    required this.top3Predictions,
    this.heatmap,
    required this.status,
    this.error,
    this.warning,
  });

  factory SkinAnalysisResult.fromJson(Map<String, dynamic> json) {
    // 클래스별 확률 파싱
    Map<String, double> probabilities = {};
    if (json['class_probabilities'] != null) {
      (json['class_probabilities'] as Map<String, dynamic>).forEach((key, value) {
        probabilities[key] = (value as num).toDouble();
      });
    }

    // 상위 3개 예측 결과 파싱
    List<TopPrediction> top3 = [];
    if (json['top_3_predictions'] != null) {
      for (var item in json['top_3_predictions']) {
        top3.add(TopPrediction.fromJson(item));
      }
    }

    return SkinAnalysisResult(
      predictedClass: json['predicted_class'] ?? '',
      predictedCode: json['predicted_code'] ?? '',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      classProbabilities: probabilities,
      top3Predictions: top3,
      heatmap: json['heatmap'],
      status: json['status'] ?? 'error',
      error: json['error'] ?? json['message'],
      warning: json['warning'],
    );
  }
}

class TopPrediction {
  final String className;
  final String classCode;
  final double confidence;

  TopPrediction({
    required this.className,
    required this.classCode,
    required this.confidence,
  });

  factory TopPrediction.fromJson(Map<String, dynamic> json) {
    return TopPrediction(
      className: json['class_name'] ?? '',
      classCode: json['class_code'] ?? '',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
    );
  }
}

class SkinAnalysisService {
  final String baseUrl;

  SkinAnalysisService({String? baseUrl})
      : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  Future<SkinAnalysisResult> analyzeImage(File imageFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/chat/skin/analyze/'),
      );

      // 이미지 파일 추가
      var imageStream = http.ByteStream(imageFile.openRead());
      var imageLength = await imageFile.length();
      var multipartFile = http.MultipartFile(
        'image',
        imageStream,
        imageLength,
        filename: imageFile.path.split('/').last,
      );

      request.files.add(multipartFile);

      print('[SkinAnalysisService] 분석 요청: ${imageFile.path}');

      // 요청 전송
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print('[SkinAnalysisService] 응답 상태: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        print('[SkinAnalysisService] 분석 완료: ${jsonData['predicted_class']}');
        return SkinAnalysisResult.fromJson(jsonData);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? '분석 실패');
      }
    } catch (e) {
      print('[SkinAnalysisService] 오류: $e');
      return SkinAnalysisResult(
        predictedClass: '',
        predictedCode: '',
        confidence: 0.0,
        classProbabilities: {},
        top3Predictions: [],
        status: 'error',
        error: e.toString(),
      );
    }
  }
}
