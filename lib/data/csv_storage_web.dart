import 'package:shared_preferences/shared_preferences.dart';

class CsvStorage {
  static const _header = 'timestamp,latitude,longitude';
  static const _csvStorageKey = 'week_activity_csv_data';

  Future<List<String>> readRows() async {
    final preferences = await SharedPreferences.getInstance();
    final csv = preferences.getString(_csvStorageKey) ?? '$_header\n';

    return csv
        .split('\n')
        .skip(1)
        .where((line) => line.trim().isNotEmpty)
        .toList();
  }

  Future<void> appendRow(String row) async {
    final preferences = await SharedPreferences.getInstance();
    final existing = preferences.getString(_csvStorageKey) ?? '$_header\n';
    await preferences.setString(_csvStorageKey, '$existing$row\n');
  }

  Future<String> locationLabel() async {
    return 'Browser local storage (CSV format)';
  }
}
