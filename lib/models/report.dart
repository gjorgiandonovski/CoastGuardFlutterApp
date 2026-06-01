import 'package:cloud_firestore/cloud_firestore.dart';

class Report {
  const Report({
    required this.id,
    required this.beachId,
    required this.beach,
    required this.category,
    required this.severity,
    required this.description,
    required this.hasPhoto,
    required this.status,
    this.userId,
    this.userEmail,
    this.latitude,
    this.longitude,
    this.createdAtEpochMs,
  });

  final String id;
  final String beachId;
  final String beach;
  final String category;
  final String severity;
  final String description;
  final bool hasPhoto;
  final String status;
  final String? userId;
  final String? userEmail;
  final double? latitude;
  final double? longitude;
  final int? createdAtEpochMs;

  String get coordinatesLabel {
    if (latitude == null || longitude == null) {
      return 'Coordinates unavailable';
    }

    return '${latitude!.toStringAsFixed(5)}, ${longitude!.toStringAsFixed(5)}';
  }

  factory Report.fromDocument(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    return Report.fromMap(doc.id, doc.data());
  }

  factory Report.fromMap(String id, Map<String, dynamic> data) {
    return Report(
      id: id,
      beachId: _readString(data, const ['beachId'], ''),
      beach: _readString(data, const ['beach', 'beachName'], 'Unknown beach'),
      category: _readString(data, const ['category'], 'Uncategorized issue'),
      severity: _readString(data, const ['severity'], 'Unknown'),
      description: _readString(data, const ['description'], 'No description'),
      hasPhoto: data['hasPhoto'] == true || data['photoFlag'] == true,
      status: _readString(data, const ['status'], ''),
      userId: _readNullableString(data, const ['userId']),
      userEmail: _readNullableString(data, const ['userEmail']),
      latitude: _readDouble(data, const ['latitude', 'lat']),
      longitude: _readDouble(data, const ['longitude', 'lng', 'lon']),
      createdAtEpochMs: _readInt(data, const ['createdAtEpochMs']),
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
