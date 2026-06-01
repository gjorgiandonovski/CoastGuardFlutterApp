import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    this.reportId,
    this.eventId,
    this.userId,
    this.createdAtEpochMs,
  });

  final String id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final String? reportId;
  final String? eventId;
  final String? userId;
  final int? createdAtEpochMs;

  factory AppNotification.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return AppNotification.fromMap(doc.id, doc.data());
  }

  factory AppNotification.fromMap(String id, Map<String, dynamic> data) {
    return AppNotification(
      id: id,
      title: _readString(data, const ['title'], 'No title'),
      message: _readString(data, const ['message'], 'No message'),
      type: _readString(data, const ['type'], ''),
      isRead: data['isRead'] == true,
      reportId: _readNullableString(data, const ['reportId']),
      eventId: _readNullableString(data, const ['eventId']),
      userId: _readNullableString(data, const ['userId']),
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
