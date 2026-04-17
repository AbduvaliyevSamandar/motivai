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
  AuthError(String msg) : super(msg, 401);
}

class Api {
  static final Api _i = Api._();
  factory Api() => _i;
  Api._();

  final _store = Storage();

  /// Endpoint ga trailing slash qo'shadi (307 redirect oldini olish uchun)
  String _fixUrl(String ep) {
    final url = '${K.base}$ep';
    // Query string bo'lsa, ? dan oldingi qismga slash qo'shamiz
    final qIdx = url.indexOf('?');
    if (qIdx > 0) {
      final path = url.substring(0, qIdx);
      final query = url.substring(qIdx);
      return path.endsWith('/') ? url : '$path/$query';
    }
    return url.endsWith('/') ? url : '$url/';
  }

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
    final uri = Uri.parse(_fixUrl(ep));
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
  Future<dynamic> post(String ep, Map<String, dynamic> body,
      {bool auth = true, Duration? timeout}) async {
    final uri = Uri.parse(_fixUrl(ep));
    try {
      final headers = await _headers(auth: auth);
      var res = await http
          .post(uri, headers: headers, body: jsonEncode(body))
          .timeout(timeout ?? K.timeout);

      // 307/308 redirect bo'lsa - yangi URL ga qayta yuboramiz
      if ((res.statusCode == 307 || res.statusCode == 308) &&
          res.headers['location'] != null) {
        final newUri = Uri.parse(res.headers['location']!);
        res = await http
            .post(newUri, headers: headers, body: jsonEncode(body))
            .timeout(timeout ?? K.timeout);
      }

      return _parse(res);
    } on ApiError {
      rethrow;
    } catch (e) {
      throw ApiError('Tarmoq xatosi: $e');
    }
  }

  // ── PUT ──────────────────────────────────────────────
  Future<dynamic> put(String ep, Map<String, dynamic> body) async {
    final uri = Uri.parse(_fixUrl(ep));
    try {
      final headers = await _headers();
      var res = await http
          .put(uri, headers: headers, body: jsonEncode(body))
          .timeout(K.timeout);

      if ((res.statusCode == 307 || res.statusCode == 308) &&
          res.headers['location'] != null) {
        final newUri = Uri.parse(res.headers['location']!);
        res = await http
            .put(newUri, headers: headers, body: jsonEncode(body))
            .timeout(K.timeout);
      }

      return _parse(res);
    } on ApiError {
      rethrow;
    } catch (e) {
      throw ApiError('Tarmoq xatosi: $e');
    }
  }

  // ── PARSE ─────────────────────────────────────────────
  dynamic _parse(http.Response res) {
    dynamic body;
    try {
      body = jsonDecode(utf8.decode(res.bodyBytes));
    } catch (_) {
      body = {'detail': 'Server javob bermadi'};
    }
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
