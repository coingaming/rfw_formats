import 'dart:developer';
import 'dart:typed_data';
import 'package:flutter_advanced/src/services/api_client.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';
import 'package:sembast/blob.dart';

class RfwService {
  static const String _dbName = "rfw_templates.db";

  late Database _db;
  late final StoreRef<String, dynamic> _store =
      StoreRef<String, dynamic>.main();

  Future<void> initialize() async {
    try {
      await _openDatabase();
      await fetchAndStoreTemplates();
    } catch (e) {
      throw Exception("Failed to initialize RFW service: $e");
    }
  }

  Future<void> _openDatabase() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dbPath = "${appDir.path}/$_dbName";
    _db = await databaseFactoryIo.openDatabase(dbPath);
  }

  Future<void> _processTemplates(List<dynamic> templates) async {
    for (var template in templates) {
      // Store the main template
      if (template["path"] != null && template["template"] != null) {
        await _storeTemplate(template["path"], template["template"]);
      }

      // Process nested routes if they exist
      if (template["routes"] != null) {
        await _processTemplates(template["routes"]);
      }
    }
  }

  Future<void> fetchAndStoreTemplates() async {
    try {
      final templates = await ApiClient.fetchRfwTemplates();
      if (templates != null) {
        final routingConfig = _removeTemplatesFromData(templates);
        await _storeRoutingConfiguration(routingConfig);
        await _processTemplates(templates);
      } else {
        throw Exception("Failed to fetch RFW templates: API returned null");
      }
    } catch (e) {
      throw Exception("Failed to fetch and store RFW templates: $e");
    }
  }

  List<dynamic> _removeTemplatesFromData(List<dynamic> data) {
    return data.map((item) {
      Map<String, dynamic> newItem = Map<String, dynamic>.from(item);
      newItem.remove("template");
      if (newItem.containsKey("routes")) {
        newItem["routes"] =
            _removeTemplatesFromData(List<dynamic>.from(newItem["routes"]));
      }
      return newItem;
    }).toList();
  }

  Future<void> _storeRoutingConfiguration(dynamic routingConfig) async {
    try {
      await _store.record("routing_configuration").put(_db, routingConfig);
    } catch (e) {
      throw Exception("Failed to store routing configuration: $e");
    }
  }

  Future<void> _storeTemplate(String path, String base64Template) async {
    try {
      final blobTemplate = Blob.fromBase64(base64Template);
      await _store.record(path).put(_db, blobTemplate);
    } catch (e) {
      throw Exception("Failed to store template for path $path: $e");
    }
  }

  Future<Uint8List?> getTemplate(String path) async {
    try {
      final blobTemplate = await _store.record(path).get(_db) as Blob?;
      if (blobTemplate != null) {
        return blobTemplate.bytes;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<dynamic> getRoutingConfiguration() async {
    try {
      return await _store.record("routing_configuration").get(_db);
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, Uint8List>> getAllTemplates() async {
    try {
      final records = await _store.find(_db);
      log(records.toString());
      return Map.fromEntries(
        records
            .where((record) => record.key != "routing_configuration")
            .map((record) {
          final blob = record.value as Blob?;
          if (blob != null) {
            return MapEntry(
              record.key.toString(),
              blob.bytes,
            );
          } else {
            return MapEntry(record.key.toString(), Uint8List(0));
          }
        }),
      );
    } catch (e) {
      return {};
    }
  }

  Future<void> clearTemplates() async {
    try {
      await _store.delete(_db);
    } catch (e) {
      throw Exception("Failed to clear templates: $e");
    }
  }

  Future<bool> hasTemplates() async {
    try {
      final count = await _store.count(_db);
      return count > 0;
    } catch (e) {
      return false;
    }
  }

  Future<void> close() async {
    await _db.close();
  }
}
