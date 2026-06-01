import 'package:cloud_firestore/cloud_firestore.dart';

class Beach {
  const Beach({
    required this.id,
    required this.name,
    this.municipality,
    this.riskLevel,
    this.cleanlinessScore,
    this.latitude,
    this.longitude,
  });

  final String id;
  final String name;
  final String? municipality;
  final String? riskLevel;
  final int? cleanlinessScore;
  final double? latitude;
  final double? longitude;

  bool get hasCoordinates => latitude != null && longitude != null;

  String get coordinatesLabel {
    if (!hasCoordinates) {
      return 'Coordinates unavailable';
    }

    return '${latitude!.toStringAsFixed(5)}, ${longitude!.toStringAsFixed(5)}';
  }

  factory Beach.fromDocument(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    return Beach.fromMap(doc.id, doc.data());
  }

  factory Beach.fromMap(String id, Map<String, dynamic> data) {
    final location = data['location'];

    return Beach(
      id: id,
      name: _readString(data, const ['name', 'beachName', 'title'], id),
      municipality: _readNullableString(data, const ['municipality']),
      riskLevel: _readNullableString(data, const ['riskLevel']),
      cleanlinessScore: _readInt(data, const ['cleanlinessScore']),
      latitude:
          _readDouble(data, const ['latitude', 'lat']) ??
          (location is GeoPoint ? location.latitude : null),
      longitude:
          _readDouble(data, const ['longitude', 'lng', 'lon']) ??
          (location is GeoPoint ? location.longitude : null),
    );
  }

  static String _readString(
    Map<String, dynamic> data,
    List<String> keys,
    String fallback,
  ) {
    for (final key in keys) {
      final value = data[key];
      if (value == null) {
        continue;
      }

      final text = value.toString().trim();
      if (text.isNotEmpty) {
        return text;
      }
    }

    return fallback;
  }

  static String? _readNullableString(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = data[key];
      if (value == null) {
        continue;
      }

      final text = value.toString().trim();
      if (text.isNotEmpty) {
        return text;
      }
    }

    return null;
  }

  static double? _readDouble(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is num) {
        return value.toDouble();
      }
      if (value is String) {
        final parsed = double.tryParse(value.trim());
        if (parsed != null) {
          return parsed;
        }
      }
    }

    return null;
  }

  static int? _readInt(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is int) {
        return value;
      }
      if (value is num) {
        return value.toInt();
      }
      if (value is String) {
        final parsed = int.tryParse(value.trim());
        if (parsed != null) {
          return parsed;
        }
      }
    }

    return null;
  }
}
