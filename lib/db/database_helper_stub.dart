class DatabaseHelper {
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  final List<Map<String, dynamic>> _rows = [];
  int _nextId = 1;

  Future<int> insertCoordinate({
    required String timestamp,
    required double latitude,
    required double longitude,
  }) async {
    final id = _nextId++;
    _rows.insert(0, {
      'id': id,
      'timestamp': timestamp,
      'latitude': latitude,
      'longitude': longitude,
    });
    return id;
  }

  Future<List<Map<String, dynamic>>> getCoordinates() async {
    return List.unmodifiable(_rows);
  }

  Future<int> deleteCoordinate(int id) async {
    final before = _rows.length;
    _rows.removeWhere((r) => r['id'] == id);
    return before - _rows.length;
  }

  Future<int> updateCoordinate({
    required int id,
    required double latitude,
    required double longitude,
  }) async {
    final index = _rows.indexWhere((r) => r['id'] == id);
    if (index == -1) return 0;
    _rows[index] = {..._rows[index], 'latitude': latitude, 'longitude': longitude};
    return 1;
  }
}