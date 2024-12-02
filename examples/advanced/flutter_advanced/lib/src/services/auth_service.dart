import 'package:flutter_advanced/src/services/api_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final storage = const FlutterSecureStorage();

  // In-memory token for non-remembered sessions
  String? _temporaryToken;

  Future<bool> login(String email, String password, bool rememberMe) async {
    try {
      final token = await ApiClient.login(email, password, rememberMe);

      if (token != null) {
        if (rememberMe) {
          await storage.write(key: "auth_token", value: token);
        } else {
          _temporaryToken = token;
          await storage.delete(key: "auth_token");
        }
        return true;
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
