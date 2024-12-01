import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AuthService {
  static final String baseUrl =
      Platform.isAndroid ? "http://10.0.2.2:4000" : "http://localhost:4000";
  final storage = const FlutterSecureStorage();

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
          await storage.write(key: "auth_token", value: token);
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
  }

  Future<bool> isAuthenticated() async {
    final token = await storage.read(key: "auth_token");
    return token != null;
  }

  Future<String?> getToken() async {
    return await storage.read(key: "auth_token");
  }
}
