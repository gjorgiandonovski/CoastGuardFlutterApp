import 'dart:io';

import 'package:path_provider/path_provider.dart';

class CsvStorage {
  static const _header = 'timestamp,latitude,longitude';

  Future<File> _csvFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/gps_coordinates.csv');
  }

  Future<List<String>> readRows() async {
    final file = await _csvFile();

    if (!await file.exists()) {
      await file.writeAsString('$_header\n');
    }

    final lines = await file.readAsLines();
    return lines.skip(1).where((line) => line.trim().isNotEmpty).toList();
  }

  Future<void> appendRow(String row) async {
    final file = await _csvFile();
    if (!await file.exists()) {
      await file.writeAsString('$_header\n');
    }
    await file.writeAsString('$row\n', mode: FileMode.append);
  }

  Future<String> locationLabel() async {
    final file = await _csvFile();
    return file.path;
  }
}
