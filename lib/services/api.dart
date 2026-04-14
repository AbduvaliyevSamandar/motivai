import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/constants.dart';
import 'storage.dart';

class ApiError implements Exception {
  final String message;
  final int?   code;
  ApiError(this.message, [this.code]);
  @override
  String toString() => message;
}

class AuthError extends ApiError {
  AuthError(super.msg) : super(401);
}

class Api {
  static final Api _i = Api._();
  factory Api() => _i;
  Api._();

  final _store = Storage();

  Future<Map<String, String>> _headers({bool auth = true}) async {
    final h = {'Content-Type': 'application/json'};
    if (auth) {
      final t = await _store.getToken();
      if (t != null) h['Authorization'] = 'Bearer $t';
    }
    return h;
  }

  // ── GET ───────────────────────────────────────────────
  Future<dynamic> get(String ep) async {
    final uri = Uri.parse('${K.base}$ep');
    try {
      final res = await http
          .get(uri, headers: await _headers())
          .timeout(K.timeout);
      return _parse(res);
    } on ApiError {
      rethrow;
    } catch (e) {
      throw ApiError('Tarmoq xatosi: $e');
    }
  }

  // ── POST ─────────────────────────────────────────────
  Future<dynamic> post(
    String ep,
    Map<String, dynamic> body, {
    bool auth = true,
    Duration? timeout,
  }) async {
    final uri = Uri.parse('${K.base}$ep');
    try {
      final res = await http
          .post(uri,
              headers: await _headers(auth: auth),
              body: jsonEncode(body))
          .timeout(timeout ?? K.timeout);
      return _parse(res);
    } on ApiError {
      rethrow;
    } catch (e) {
      throw ApiError('Tarmoq xatosi: $e');
    }
  }

  // ── PUT ──────────────────────────────────────────────
  Future<dynamic> put(String ep, Map<String, dynamic> body) async {
    final uri = Uri.parse('${K.base}$ep');
    try {
      final res = await http
          .put(uri,
              headers: await _headers(),
              body: jsonEncode(body))
          .timeout(K.timeout);
      return _parse(res);
    } on ApiError {
      rethrow;
    } catch (e) {
      throw ApiError('Tarmoq xatosi: $e');
    }
  }

  // ── PARSE ─────────────────────────────────────────────
  dynamic _parse(http.Response res) {
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode >= 200 && res.statusCode < 300) return body;
    if (res.statusCode == 401) {
      throw AuthError(
          _msg(body) ?? 'Avtorizatsiya xatosi. Qayta kiring.');
    }
    throw ApiError(
        _msg(body) ?? 'Server xatosi (${res.statusCode})',
        res.statusCode);
  }

  String? _msg(dynamic b) =>
      b is Map ? (b['detail'] ?? b['message'])?.toString() : null;
}
