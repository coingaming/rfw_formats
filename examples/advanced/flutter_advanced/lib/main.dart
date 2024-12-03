import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_advanced/src/services/auth_service.dart';
import 'package:flutter_advanced/src/services/rfw_service.dart';
import 'package:flutter_advanced/src/router.dart';
import 'package:sembast/sembast_io.dart';

final _authService = AuthService();
final _rfwService = RfwService();
late final AppRouter _appRouter;

List<Map<String, dynamic>> _convertConfig(List<dynamic> config) {
  return config.map((dynamic item) {
    final map = Map<String, dynamic>.from(item as Map);
    if (map['routes'] != null) {
      map['routes'] = _convertConfig(map['routes'] as List<dynamic>);
    }
    return map;
  }).toList();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize RFW service first
  disableSembastCooperator();
  await _rfwService.initialize();
  enableSembastCooperator();
  //await _rfwService.clearTemplates();

  // Create AppRouter after RFW service is initialized
  _appRouter = AppRouter(
    authService: _authService,
    rfwService: _rfwService,
  );

  // Get and apply dynamic routing configuration
  final routingConfig = await _rfwService.getRoutingConfiguration();
  if (routingConfig != null) {
    log("yeee");
    // Convert configuration with proper type handling
    final convertedConfig = _convertConfig(routingConfig);
    _appRouter.mergeRoutingConfiguration(convertedConfig);
  }

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: "Advanced RFW Example",
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      routerConfig: _appRouter.router,
    );
  }
}
