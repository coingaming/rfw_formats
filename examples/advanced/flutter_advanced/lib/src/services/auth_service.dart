import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AuthService {
  static final String baseUrl =
      Platform.isAndroid ? "http://10.0.2.2:4000" : "http://localhost:4000";
  final storage = const FlutterSecureStorage();

  // In-memory token for non-remembered sessions
  static String? _temporaryToken;

  Future<bool> login(String email, String password, bool rememberMe) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/users/log_in"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "email": email,
          "password": password,
          "remember_me": rememberMe,
        }),
      );

      if (response.statusCode == 200) {
        final token = response.headers["authorization"];
        if (token != null) {
          if (rememberMe) {
            // Store token permanently if remember me is true
            await storage.write(key: "auth_token", value: token);
          } else {
            // Store token only in memory if remember me is false
            _temporaryToken = token;
            // Ensure no token is stored permanently
            await storage.delete(key: "auth_token");
          }
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    await storage.delete(key: "auth_token");
    _temporaryToken = null;
  }

  Future<bool> isAuthenticated() async {
    final permanentToken = await storage.read(key: "auth_token");
    return permanentToken != null || _temporaryToken != null;
  }

  Future<String?> getToken() async {
    // Prefer permanent token over temporary
    final permanentToken = await storage.read(key: "auth_token");
    return permanentToken ?? _temporaryToken;
  }
}
