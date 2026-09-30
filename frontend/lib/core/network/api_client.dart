import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../storage/auth_storage.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient({required this._authStorage, http.Client? httpClient})
    :
      _httpClient = httpClient ?? http.Client();

  final AuthStorage _authStorage;
  final http.Client _httpClient;

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool authenticated = false,
  }) {
    return _request(
      method: 'GET',
      path: path,
      queryParameters: queryParameters,
      authenticated: authenticated,
    );
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Object? body,
    bool authenticated = false,
  }) {
    return _request(
      method: 'POST',
      path: path,
      body: body,
      authenticated: authenticated,
    );
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Object? body,
    bool authenticated = false,
  }) {
    return _request(
      method: 'PUT',
      path: path,
      body: body,
      authenticated: authenticated,
    );
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    Object? body,
    bool authenticated = false,
  }) {
    return _request(
      method: 'PATCH',
      path: path,
      body: body,
      authenticated: authenticated,
    );
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    Object? body,
    bool authenticated = false,
  }) {
    return _request(
      method: 'DELETE',
      path: path,
      body: body,
      authenticated: authenticated,
    );
  }

  Future<Map<String, dynamic>> multipart(
    String path, {
    required String method,
    required Map<String, String> fields,
    List<({String name, List<int> bytes})> files = const [],
  }) async {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final request = http.MultipartRequest(
      method,
      Uri.parse('${AppConfig.apiBaseUrl}$normalizedPath'),
    );
    final token = await _authStorage.readToken();

    if (token == null || token.isEmpty) {
      throw const ApiException(
        'Your session has expired. Please sign in again.',
        statusCode: 401,
      );
    }

    request.headers.addAll({
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    });
    request.fields.addAll(fields);

    for (final file in files) {
      request.files.add(
        http.MultipartFile.fromBytes('images', file.bytes, filename: file.name),
      );
    }

    try {
      final streamed = await _httpClient.send(request).timeout(
        const Duration(seconds: 45),
      );
      return _decodeResponse(await http.Response.fromStream(streamed));
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiException(
        'Cannot connect to the server. Make sure the backend is running.',
        details: error,
      );
    }
  }

  Future<Map<String, dynamic>> _request({
    required String method,
    required String path,
    Map<String, dynamic>? queryParameters,
    Object? body,
    required bool authenticated,
  }) async {
    final normalizedPath = path.startsWith('/') ? path : '/$path';

    final uri = Uri.parse('${AppConfig.apiBaseUrl}$normalizedPath').replace(
      queryParameters: queryParameters?.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
    );

    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (authenticated) {
      final token = await _authStorage.readToken();

      if (token == null || token.isEmpty) {
        throw const ApiException(
          'Your session has expired. Please sign in again.',
          statusCode: 401,
        );
      }

      headers['Authorization'] = 'Bearer $token';
    }

    try {
      late http.Response response;
      final encodedBody = body == null ? null : jsonEncode(body);

      switch (method) {
        case 'GET':
          response = await _httpClient
              .get(uri, headers: headers)
              .timeout(const Duration(seconds: 15));
          break;

        case 'POST':
          response = await _httpClient
              .post(uri, headers: headers, body: encodedBody)
              .timeout(const Duration(seconds: 20));
          break;

        case 'PUT':
          response = await _httpClient
              .put(uri, headers: headers, body: encodedBody)
              .timeout(const Duration(seconds: 20));
          break;

        case 'PATCH':
          response = await _httpClient
              .patch(uri, headers: headers, body: encodedBody)
              .timeout(const Duration(seconds: 20));
          break;

        case 'DELETE':
          response = await _httpClient
              .delete(uri, headers: headers, body: encodedBody)
              .timeout(const Duration(seconds: 20));
          break;

        default:
          throw ApiException('Unsupported method: $method');
      }

      return _decodeResponse(response);
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiException(
        'Cannot connect to the server. Make sure the backend is running.',
        details: error,
      );
    }
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    Map<String, dynamic> payload = {};

    if (response.body.isNotEmpty) {
      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        payload = decoded;
      }
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        payload['message']?.toString() ?? 'The request failed.',
        statusCode: response.statusCode,
        details: payload['errors'],
      );
    }

    return payload;
  }

  void dispose() {
    _httpClient.close();
  }
}
