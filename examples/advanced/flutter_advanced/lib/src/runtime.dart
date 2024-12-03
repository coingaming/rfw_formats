import 'dart:typed_data';
import 'package:rfw/rfw.dart';

const LibraryName _mainLibraryName = LibraryName(<String>["main"]);

FullyQualifiedWidgetName remoteWidget(String name) =>
    FullyQualifiedWidgetName(_mainLibraryName, name);

Runtime createRuntime() => Runtime()
  ..update(const LibraryName(<String>["widgets"]), createCoreWidgets())
  ..update(const LibraryName(<String>["material"]), createMaterialWidgets());
//..update(const LibraryName(<String>['local']), createLocalWidgets());

extension UpdateMainLibrary on Runtime {
  void updateMainLibrary(Uint8List library) {
    update(_mainLibraryName, decodeLibraryBlob(library));
  }
}
