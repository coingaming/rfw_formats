import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_advanced/src/services/api_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for managing Remote Flutter Widget (RFW) templates
///
/// This service handles:
/// - Fetching templates from the API
/// - Storing templates in secure storage
/// - Caching templates in memory
/// - Retrieving templates from cache or storage
class RfwService {
  static const _storage = FlutterSecureStorage();
  static const String _counterTemplateKey = "rfw_template_counter";

  final Map<String, Uint8List> templatesCache = {};

  Future<void> initialize() async {
    try {
      /* final hasStoredTemplates = await hasTemplates();
      if (!hasStoredTemplates) { */
      await fetchAndStoreTemplates();
      /* } else {
        await getTemplates();
      } */
    } catch (e) {
      print("Failed to initialize RfwService: $e");
    }
  }

  Future<void> fetchAndStoreTemplates() async {
    try {
      final templates = await ApiClient.fetchRfwTemplates();
      if (templates != null) {
        // Convert Uint8List to base64 for storage
        final base64Templates = base64Encode(templates);
        await _storage.write(key: _counterTemplateKey, value: base64Templates);
        templatesCache[_counterTemplateKey] = templates;
      } else {
        throw Exception("Failed to fetch RFW templates: API returned null");
      }
    } catch (e) {
      throw Exception("Failed to fetch and store RFW templates: $e");
    }
  }

  Future<Uint8List?> getTemplates() async {
    try {
      if (templatesCache.containsKey(_counterTemplateKey)) {
        return templatesCache[_counterTemplateKey];
      }

      final storedTemplates = await _storage.read(key: _counterTemplateKey);
      if (storedTemplates != null) {
        try {
          final templates = Uint8List.fromList(base64Decode(storedTemplates));
          templatesCache[_counterTemplateKey] = templates;
          return templates;
        } catch (e) {
          await clearTemplates();
          return null;
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> clearTemplates() async {
    try {
      await _storage.delete(key: _counterTemplateKey);
      templatesCache.clear();
    } catch (e) {
      throw Exception("Failed to clear templates: $e");
    }
  }

  Future<bool> hasTemplates() async {
    if (templatesCache.containsKey(_counterTemplateKey)) {
      return true;
    }
    final storedTemplates = await _storage.read(key: _counterTemplateKey);
    return storedTemplates != null;
  }
}
