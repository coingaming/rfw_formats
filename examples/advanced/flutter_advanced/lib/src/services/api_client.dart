import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiClient {
  static final String _baseUrl =
      Platform.isAndroid ? "http://10.0.2.2:4000" : "http://localhost:4000";

  static Future<String?> login(
      String email, String password, bool rememberMe) async {
    try {
      final response = await http.post(
        Uri.parse("$_baseUrl/api/users/log_in"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "email": email,
          "password": password,
          "remember_me": rememberMe,
        }),
      );

      if (response.statusCode == 200) {
        return response.headers["authorization"];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<List<dynamic>?> fetchRfwTemplates() async {
    try {
      final response = await http.get(
        Uri.parse("$_baseUrl/api/rfw-templates"),
        headers: {"Accept": "application/json"},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
