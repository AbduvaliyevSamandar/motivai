import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/constants.dart';
import 'storage.dart';

// Xato turlari
class ApiError implements Exception {
  final String message;
  final int?   statusCode;
  ApiError(this.message, [this.statusCode]);
  @override String toString() => message;
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
    final res = await http
        .get(Uri.parse('${K.baseUrl}$ep'), headers: await _headers())
        .timeout(K.connectTimeout);
    return _parse(res);
  }

  // ── POST ──────────────────────────────────────────────
  Future<dynamic> post(String ep, Map<String, dynamic> body,
      {bool auth = true, Duration? timeout}) async {
    final res = await http
        .post(
          Uri.parse('${K.baseUrl}$ep'),
          headers: await _headers(auth: auth),
          body: jsonEncode(body),
        )
        .timeout(timeout ?? K.connectTimeout);
    return _parse(res);
  }

  // ── PUT ───────────────────────────────────────────────
  Future<dynamic> put(String ep, Map<String, dynamic> body) async {
    final res = await http
        .put(
          Uri.parse('${K.baseUrl}$ep'),
          headers: await _headers(),
          body: jsonEncode(body),
        )
        .timeout(K.connectTimeout);
    return _parse(res);
  }

  // ── PARSE ─────────────────────────────────────────────
  dynamic _parse(http.Response res) {
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode >= 200 && res.statusCode < 300) return body;
    if (res.statusCode == 401) {
      throw AuthError(body['detail']?.toString() ?? 'Token muddati tugagan');
    }
    throw ApiError(
      body['detail']?.toString() ?? body['message']?.toString() ?? 'Xato yuz berdi',
      res.statusCode,
    );
  }
}
