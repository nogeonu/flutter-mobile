import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class ApiException implements Exception {
  ApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  ApiClient({
    http.Client? client,
    Uri Function(String, [Map<String, dynamic>?])? uriBuilder,
  })  : _client = client ?? http.Client(),
        _uriBuilder = uriBuilder ?? ApiConfig.buildUri;

  final http.Client _client;
  final Uri Function(String, [Map<String, dynamic>?]) _uriBuilder;

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    final uri = _uriBuilder(path, query);
    final response = await _client.get(uri, headers: _defaultHeaders);
    return _handleResponse(response);
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    final uri = _uriBuilder(path);
    final response = await _client.post(
      uri,
      headers: _defaultHeaders,
      body: jsonEncode(body ?? const {}),
    );
    return _handleResponse(response);
  }

  Future<dynamic> put(String path, {Map<String, dynamic>? body}) async {
    final uri = _uriBuilder(path);
    final response = await _client.put(
      uri,
      headers: _defaultHeaders,
      body: jsonEncode(body ?? const {}),
    );
    return _handleResponse(response);
  }

  dynamic _handleResponse(http.Response response) {
    final status = response.statusCode;
    final text = response.body.isEmpty ? '{}' : response.body;
    final dynamic data = jsonDecode(text);
    if (status >= 200 && status < 300) {
      return data;
    }
    final message = data is Map && data['detail'] is String
        ? data['detail'] as String
        : 'Request failed with status $status';
    throw ApiException(status, message);
  }

  Map<String, String> get _defaultHeaders => const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  void close() => _client.close();
}
