import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:kkeutgong_mobile/core/auth/token_store.dart';
import 'package:kkeutgong_mobile/core/routes/app_routes.dart';

class ApiException implements Exception {
  final int statusCode;
  final String body;
  ApiException(this.statusCode, this.body);
  @override
  String toString() => 'ApiException($statusCode): $body';
}

class ApiClient {
  ApiClient._internal();
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  final http.Client _http = http.Client();
  final TokenStore _tokenStore = TokenStore();

  String get baseUrl {
    final configured = dotenv.maybeGet('API_BASE_URL');
    // Release builds must have API_BASE_URL set in assets/config/.env. The
    // localhost fallback only exists for local dev; shipping it would mean
    // every request fails silently against a non-existent server.
    if (!kDebugMode && (configured == null || configured.isEmpty)) {
      throw StateError('API_BASE_URL is missing from assets/config/.env');
    }
    final raw = configured ?? 'http://localhost:3000/api';
    if (kIsWeb) return raw;
    if (Platform.isAndroid) {
      return raw.replaceFirst('localhost', '10.0.2.2');
    }
    return raw;
  }

  Future<Map<String, String>> _authHeaders() async {
    final token = await _tokenStore.accessToken;
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> get(String path, {Map<String, String>? query}) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    final headers = await _authHeaders();
    final res = await _http.get(uri, headers: headers);
    return _decodeWithRefresh(res, () => get(path, query: query));
  }

  Future<dynamic> post(String path, {Object? body}) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = await _authHeaders();
    final res = await _http.post(
      uri,
      headers: headers,
      body: jsonEncode(body ?? const {}),
    );
    return _decodeWithRefresh(res, () => post(path, body: body));
  }

  Future<dynamic> patch(String path, {Object? body}) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = await _authHeaders();
    final res = await _http.patch(
      uri,
      headers: headers,
      body: jsonEncode(body ?? const {}),
    );
    return _decodeWithRefresh(res, () => patch(path, body: body));
  }

  Future<dynamic> delete(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = await _authHeaders();
    final res = await _http.delete(uri, headers: headers);
    return _decodeWithRefresh(res, () => delete(path));
  }

  /// POST without auth header — used for token refresh itself.
  Future<dynamic> postRaw(String path, {Object? body}) async {
    final uri = Uri.parse('$baseUrl$path');
    const headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final res = await _http.post(
      uri,
      headers: headers,
      body: jsonEncode(body ?? const {}),
    );
    return _decode(res);
  }

  Future<dynamic> _decodeWithRefresh(
    http.Response res,
    Future<dynamic> Function() retry,
  ) async {
    if (res.statusCode == 401) {
      final outcome = await _tryRefresh();
      switch (outcome) {
        case _RefreshOutcome.success:
          return retry();
        case _RefreshOutcome.networkError:
          // Don't clear tokens or kick the user to login on a transient
          // network failure — surface the error so the caller can retry.
          throw ApiException(503, 'Network error during token refresh');
        case _RefreshOutcome.expired:
          await _tokenStore.clear();
          Get.offAllNamed(AppRoutes.welcome);
          throw ApiException(401, 'Session expired');
      }
    }
    return _decode(res);
  }

  Future<_RefreshOutcome> _tryRefresh() async {
    final refresh = await _tokenStore.refreshToken;
    if (refresh == null) return _RefreshOutcome.expired;
    try {
      final json = await postRaw('/auth/refresh', body: {'refreshToken': refresh})
          as Map<String, dynamic>;
      await _tokenStore.saveTokens(
        access: json['accessToken'] as String,
        refresh: json['refreshToken'] as String,
      );
      return _RefreshOutcome.success;
    } on ApiException catch (e) {
      // Backend rejected the refresh token (revoked / expired / reused).
      if (e.statusCode == 401 || e.statusCode == 403) {
        return _RefreshOutcome.expired;
      }
      return _RefreshOutcome.networkError;
    } on SocketException {
      return _RefreshOutcome.networkError;
    } on HttpException {
      return _RefreshOutcome.networkError;
    } catch (_) {
      // JSON parse / type errors here mean the server returned garbage; treat
      // it as a network problem so we don't sign the user out.
      return _RefreshOutcome.networkError;
    }
  }

  dynamic _decode(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.isEmpty) return null;
      return jsonDecode(utf8.decode(res.bodyBytes));
    }
    throw ApiException(res.statusCode, utf8.decode(res.bodyBytes));
  }
}

enum _RefreshOutcome { success, expired, networkError }
