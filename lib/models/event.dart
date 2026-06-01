import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  const Event({
    required this.id,
    required this.title,
    required this.type,
    required this.beachId,
    required this.beach,
    required this.dateEpochMs,
    required this.maxParticipants,
    required this.participantCount,
    required this.participantIds,
    required this.status,
    this.createdBy,
    this.createdByEmail,
  });

  final String id;
  final String title;
  final String type;
  final String beachId;
  final String beach;
  final int dateEpochMs;
  final int maxParticipants;
  final int participantCount;
  final List<String> participantIds;
  final String status;
  final String? createdBy;
  final String? createdByEmail;

  factory Event.fromDocument(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    return Event.fromMap(doc.id, doc.data());
  }

  factory Event.fromMap(String id, Map<String, dynamic> data) {
    return Event(
      id: id,
      title: _readString(data, const ['title'], 'Untitled event'),
      type: _readString(data, const ['type'], 'cleanup'),
      beachId: _readString(data, const ['beachId'], ''),
      beach: _readString(data, const ['beach'], 'Unknown beach'),
      dateEpochMs: _readInt(data, const ['dateEpochMs']) ?? 0,
      maxParticipants: _readInt(data, const ['maxParticipants']) ?? 0,
      participantCount: _readInt(data, const ['participantCount']) ?? 0,
      participantIds: _readStringList(data['participantIds']),
      status: _readString(data, const ['status'], ''),
      createdBy: _readNullableString(data, const ['createdBy']),
      createdByEmail: _readNullableString(data, const ['createdByEmail']),
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

  static List<String> _readStringList(dynamic value) {
    if (value is Iterable) {
      return value
          .map((item) => item?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }

    return const <String>[];
  }
}
