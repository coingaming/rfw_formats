import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:phoenix_socket/phoenix_socket.dart';
import 'package:rfw/rfw.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "LiveView Counter",
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const CounterPage(),
    );
  }
}

class CounterPage extends StatefulWidget {
  const CounterPage({super.key});

  @override
  State<CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<CounterPage> {
  final String _baseUrl =
      Platform.isAndroid ? "http://10.0.2.2:4000" : "http://localhost:4000";

  final Runtime _runtime = Runtime();
  final DynamicContent _data = DynamicContent();

  late final PhoenixSocket _socket;
  PhoenixChannel? _channel;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _setupRuntime();
    _fetchRemoteWidgets();
    _setupSocket();
  }

  @override
  void dispose() {
    _socket.dispose();
    _channel?.close();
    super.dispose();
  }

  void _setupRuntime() {
    _runtime
      ..update(const LibraryName(["widgets"]), createCoreWidgets())
      ..update(const LibraryName(["material"]), createMaterialWidgets());
  }

  Future<void> _fetchRemoteWidgets() async {
    try {
      final response = await http.get(
        Uri.parse("$_baseUrl/api/widget-definition"),
        headers: {"Accept": "application/octet-stream"},
      );

      if (mounted && response.statusCode == 200) {
        setState(() {
          _runtime.update(
            const LibraryName(["main"]),
            decodeLibraryBlob(response.bodyBytes),
          );
          _isLoading = false;
        });
      } else {
        throw Exception("Failed to fetch remote widgets");
      }
    } catch (e) {
      return;
    }
  }

  void _setupSocket() {
    _socket =
        PhoenixSocket("${_baseUrl.replaceFirst("http", "ws")}/socket/websocket")
          ..connect()
          ..openStream.listen((_) => _joinChannel());
  }

  void _joinChannel() {
    _channel ??= _socket.addChannel(topic: "counter:lobby")
      ..join().onReply(
        "ok",
        (response) => _updateState(response.response["count"]),
      )
      ..messages.listen((Message message) {
        if (message.payload != null && message.payload!.containsKey("count")) {
          _updateState(message.payload!["count"]);
        }
      });
  }

  void _updateState(dynamic count) {
    _data.update("state", count.toString());
  }

  void _handleRemoteWidgetEvent(String name, DynamicMap arguments) {
    switch (name) {
      case "increment":
        _channel?.push("inc", {});
        break;
      case "decrement":
        _channel?.push("dec", {});
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Scaffold(body: Center(child: CircularProgressIndicator()))
        : RemoteWidget(
            runtime: _runtime,
            data: _data,
            widget:
                const FullyQualifiedWidgetName(LibraryName(["main"]), "root"),
            onEvent: _handleRemoteWidgetEvent,
          );
  }
}
