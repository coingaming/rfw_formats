import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_advanced/src/runtime.dart';
import 'package:go_router/go_router.dart';
import 'package:rfw/rfw.dart';

class RfwScreen extends StatefulWidget {
  final String name;
  final Uint8List library;

  const RfwScreen({
    super.key,
    required this.name,
    required this.library,
  });

  @override
  State<RfwScreen> createState() => _RfwScreenState();
}

class _RfwScreenState extends State<RfwScreen> {
  late final DynamicContent _data;
  late final Runtime _runtime;

  @override
  void initState() {
    super.initState();
    _data = DynamicContent();
    _runtime = createRuntime()..updateMainLibrary(widget.library);
  }

  @override
  Widget build(BuildContext context) =>
      _buildRemoteWidget(context, widget.name);

  Widget _buildRemoteWidget(BuildContext context, String name) => RemoteWidget(
        runtime: _runtime,
        data: _data,
        widget: remoteWidget(name),
        onEvent: (String name, DynamicMap arguments) =>
            _onEvent(context, name, arguments),
      );

  void _onEvent(
    BuildContext context,
    String name,
    DynamicMap arguments,
  ) {
    if (name == "navigator") {
      final List<Object?> actions = arguments["actions"] as List<Object?>;
      for (final Object? action in actions) {
        if (action is DynamicMap) {
          _navigate(action);
        }
      }
    }
  }

  void _navigate(DynamicMap action) {
    if (action["action"] == "pop") {
      context.pop();
    } else if (action["action"] == "push") {
      final String path = action["path"] as String;

      context.go(path);
    }
  }
}
