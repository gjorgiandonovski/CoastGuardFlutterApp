import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedBeachId;
  bool _isPublishing = false;
  String? _joiningEventId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('beaches').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final beaches =
            snapshot.data?.docs.map(_BeachOption.fromDocument).toList() ??
            const <_BeachOption>[];
        final selectedBeach = _selectedBeach(beaches);

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CreateEventCard(
                formKey: _formKey,
                beaches: beaches,
                selectedBeachId: _selectedBeachId,
                selectedBeach: selectedBeach,
                isPublishing: _isPublishing,
                onBeachChanged: (value) {
                  setState(() {
                    _selectedBeachId = value;
                  });
                },
                onPublish: () => _publishEvent(beaches),
              ),
              const SizedBox(height: 20),
              const Text('Upcoming cleanup events'),
              const SizedBox(height: 10),
              _EventsListSection(
                joiningEventId: _joiningEventId,
                onJoin: _joinEvent,
              ),
            ],
          ),
        );
      },
    );
  }

  _BeachOption? _selectedBeach(List<_BeachOption> beaches) {
    for (final beach in beaches) {
      if (beach.id == _selectedBeachId) {
        return beach;
      }
    }
    return null;
  }

  Future<void> _publishEvent(List<_BeachOption> beaches) async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackBar('You must be signed in to publish an event.');
      return;
    }

    final selectedBeach = _selectedBeach(beaches);
    if (selectedBeach == null) {
      _showSnackBar('Select a beach before publishing.');
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isPublishing = true;
    });

    final firestore = FirebaseFirestore.instance;
    final now = DateTime.now();
    final eventDate = now.add(const Duration(days: 2));
    final eventRef = firestore.collection('events').doc();
    final userRef = firestore.collection('users').doc(user.uid);
    final notificationRef = firestore.collection('notifications').doc();

    try {
      final batch = firestore.batch();
      batch.set(eventRef, {
        'title': 'Beach Cleanup at ${selectedBeach.name}',
        'type': 'cleanup',
        'beachId': selectedBeach.id,
        'beach': selectedBeach.name,
        'dateEpochMs': eventDate.millisecondsSinceEpoch,
        'maxParticipants': 50,
        'participantCount': 1,
        'participantIds': [user.uid],
        'status': 'SCHEDULED',
        'createdBy': user.uid,
        'createdByEmail': user.email,
        'createdAt': Timestamp.fromDate(now),
        'createdAtEpochMs': now.millisecondsSinceEpoch,
      });
      batch.set(userRef, {
        'email': user.email,
        'points': FieldValue.increment(150),
        'updatedAt': Timestamp.fromDate(now),
      }, SetOptions(merge: true));
      batch.set(notificationRef, {
        'userId': user.uid,
        'title': 'Cleanup event published',
        'message':
            'Your event at ${selectedBeach.name} is live. You earned 150 points.',
        'type': 'event',
        'isRead': false,
        'eventId': eventRef.id,
        'createdAt': Timestamp.fromDate(now),
        'createdAtEpochMs': now.millisecondsSinceEpoch,
      });

      await batch.commit();

      if (!mounted) {
        return;
      }

      setState(() {
        _selectedBeachId = null;
        _isPublishing = false;
      });
      _showSnackBar('Cleanup event published.');
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isPublishing = false;
      });
      _showSnackBar('Failed to publish event: $error');
    }
  }

  Future<void> _joinEvent(_EventItem event) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackBar('You must be signed in to join an event.');
      return;
    }

    if (event.participantIds.contains(user.uid)) {
      _showSnackBar('You already joined this event.');
      return;
    }

    setState(() {
      _joiningEventId = event.id;
    });

    final firestore = FirebaseFirestore.instance;
    final now = DateTime.now();
    final eventRef = firestore.collection('events').doc(event.id);
    final userRef = firestore.collection('users').doc(user.uid);
    final notificationRef = firestore.collection('notifications').doc();

    try {
      await firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(eventRef);
        if (!snapshot.exists) {
          throw const _EventJoinException('This event no longer exists.');
        }

        final data = snapshot.data() as Map<String, dynamic>;
        final participantIds = _EventItem.readParticipantIds(
          data['participantIds'],
        );
        final maxParticipants =
            _EventItem.readInt(data['maxParticipants']) ?? 50;

        if (participantIds.contains(user.uid)) {
          throw const _EventJoinException('You already joined this event.');
        }

        if (participantIds.length >= maxParticipants) {
          throw const _EventJoinException('This event is already full.');
        }

        participantIds.add(user.uid);

        transaction.update(eventRef, {
          'participantIds': participantIds,
          'participantCount': participantIds.length,
          'updatedAt': Timestamp.fromDate(now),
        });
        transaction.set(userRef, {
          'email': user.email,
          'points': FieldValue.increment(50),
          'updatedAt': Timestamp.fromDate(now),
        }, SetOptions(merge: true));
        transaction.set(notificationRef, {
          'userId': user.uid,
          'title': 'Joined cleanup event',
          'message': 'You joined ${event.title} and earned 50 points.',
          'type': 'event',
          'isRead': false,
          'eventId': event.id,
          'createdAt': Timestamp.fromDate(now),
          'createdAtEpochMs': now.millisecondsSinceEpoch,
        });
      });

      if (!mounted) {
        return;
      }

      _showSnackBar('Joined event successfully.');
    } on _EventJoinException catch (error) {
      if (!mounted) {
        return;
      }
      _showSnackBar(error.message);
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showSnackBar('Failed to join event: $error');
    } finally {
      if (mounted) {
        setState(() {
          _joiningEventId = null;
        });
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _CreateEventCard extends StatelessWidget {
  const _CreateEventCard({
    required this.formKey,
    required this.beaches,
    required this.selectedBeachId,
    required this.selectedBeach,
    required this.isPublishing,
    required this.onBeachChanged,
    required this.onPublish,
  });

  final GlobalKey<FormState> formKey;
  final List<_BeachOption> beaches;
  final String? selectedBeachId;
  final _BeachOption? selectedBeach;
  final bool isPublishing;
  final ValueChanged<String?> onBeachChanged;
  final VoidCallback onPublish;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final canPublish = !isPublishing && selectedBeach != null;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create cleanup event',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Publishing sets the event two days in the future with a 50-person limit and auto-joins you.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              if (beaches.isEmpty)
                _EventNotice(
                  icon: Icons.beach_access_outlined,
                  message:
                      'No beaches are available yet. Add beach documents to Firestore before creating events.',
                )
              else ...[
                DropdownButtonFormField<String>(
                  key: ValueKey('event-beach-$selectedBeachId'),
                  initialValue: _containsBeach(beaches, selectedBeachId)
                      ? selectedBeachId
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Beach',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final beach in beaches)
                      DropdownMenuItem<String>(
                        value: beach.id,
                        child: Text(beach.name),
                      ),
                  ],
                  onChanged: isPublishing ? null : onBeachChanged,
                  validator: (value) =>
                      value == null ? 'Select a beach.' : null,
                ),
                const SizedBox(height: 16),
                _ReadOnlyEventField(
                  label: 'Publish date',
                  value: _formatEventDate(
                    DateTime.now().add(const Duration(days: 2)),
                  ),
                  helperText: 'Automatically scheduled two days from now.',
                ),
                const SizedBox(height: 16),
                _ReadOnlyEventField(label: 'Max participants', value: '50'),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: canPublish ? onPublish : null,
                    icon: isPublishing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.campaign_outlined),
                    label: Text(
                      isPublishing ? 'Publishing...' : 'Publish event',
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static bool _containsBeach(List<_BeachOption> beaches, String? selectedId) {
    if (selectedId == null) {
      return false;
    }

    for (final beach in beaches) {
      if (beach.id == selectedId) {
        return true;
      }
    }

    return false;
  }
}

class _EventsListSection extends StatelessWidget {
  const _EventsListSection({
    required this.joiningEventId,
    required this.onJoin,
  });

  final String? joiningEventId;
  final ValueChanged<_EventItem> onJoin;

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('events')
          .orderBy('dateEpochMs', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final events =
            snapshot.data?.docs.map(_EventItem.fromDocument).toList() ??
            const <_EventItem>[];

        if (events.isEmpty) {
          return const _EventNotice(
            icon: Icons.event_busy_outlined,
            message: 'No cleanup events have been published yet.',
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: events.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final event = events[index];
            final isJoining = joiningEventId == event.id;
            final isJoined =
                currentUserId != null &&
                event.participantIds.contains(currentUserId);

            return _EventCard(
              event: event,
              isJoining: isJoining,
              isJoined: isJoined,
              onJoin: () => onJoin(event),
            );
          },
        );
      },
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.event,
    required this.isJoining,
    required this.isJoined,
    required this.onJoin,
  });

  final _EventItem event;
  final bool isJoining;
  final bool isJoined;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final canJoin = !isJoining && !isJoined && !event.isFull;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: colorScheme.secondaryContainer,
                  child: Icon(
                    Icons.volunteer_activism_outlined,
                    color: colorScheme.onSecondaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        event.beach,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                _EventStatusBadge(
                  label: isJoined
                      ? 'Joined'
                      : event.isFull
                      ? 'Full'
                      : event.status,
                  color: isJoined
                      ? colorScheme.primary
                      : event.isFull
                      ? Colors.red
                      : colorScheme.tertiary,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _EventMetadataChip(
                  icon: Icons.calendar_today_outlined,
                  label: event.formattedDate,
                ),
                _EventMetadataChip(
                  icon: Icons.group_outlined,
                  label: '${event.participantCount}/${event.maxParticipants}',
                ),
                _EventMetadataChip(
                  icon: Icons.place_outlined,
                  label: event.beach,
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: canJoin ? onJoin : null,
                icon: isJoining
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        isJoined
                            ? Icons.check_circle_outline
                            : event.isFull
                            ? Icons.block
                            : Icons.group_add_outlined,
                      ),
                label: Text(
                  isJoined
                      ? 'Joined'
                      : event.isFull
                      ? 'Event full'
                      : isJoining
                      ? 'Joining...'
                      : 'Join event',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadOnlyEventField extends StatelessWidget {
  const _ReadOnlyEventField({
    required this.label,
    required this.value,
    this.helperText,
  });

  final String label;
  final String value;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        border: const OutlineInputBorder(),
      ),
      child: Text(
        value,
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
      ),
    );
  }
}

class _EventNotice extends StatelessWidget {
  const _EventNotice({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EventStatusBadge extends StatelessWidget {
  const _EventStatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EventMetadataChip extends StatelessWidget {
  const _EventMetadataChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}

class _BeachOption {
  const _BeachOption({required this.id, required this.name});

  final String id;
  final String name;

  factory _BeachOption.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();

    return _BeachOption(
      id: doc.id,
      name: _readString(data, const ['name', 'beachName', 'title'], doc.id),
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
}

class _EventItem {
  const _EventItem({
    required this.id,
    required this.title,
    required this.beach,
    required this.status,
    required this.date,
    required this.maxParticipants,
    required this.participantCount,
    required this.participantIds,
  });

  final String id;
  final String title;
  final String beach;
  final String status;
  final DateTime date;
  final int maxParticipants;
  final int participantCount;
  final List<String> participantIds;

  bool get isFull => participantCount >= maxParticipants;
  String get formattedDate => _formatEventDate(date);

  factory _EventItem.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final participantIds = readParticipantIds(data['participantIds']);
    final participantCount =
        readInt(data['participantCount']) ?? participantIds.length;

    return _EventItem(
      id: doc.id,
      title: _readString(data, const ['title'], 'Cleanup event'),
      beach: _readString(data, const ['beach', 'beachName'], 'Unknown beach'),
      status: _readString(data, const ['status'], 'SCHEDULED'),
      date: DateTime.fromMillisecondsSinceEpoch(
        readInt(data['dateEpochMs']) ?? 0,
      ),
      maxParticipants: readInt(data['maxParticipants']) ?? 50,
      participantCount: participantCount,
      participantIds: participantIds,
    );
  }

  static List<String> readParticipantIds(Object? value) {
    if (value is Iterable) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }

    return <String>[];
  }

  static int? readInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.round();
    }
    if (value is String) {
      return int.tryParse(value.trim());
    }
    return null;
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
}

class _EventJoinException implements Exception {
  const _EventJoinException(this.message);

  final String message;
}

String _formatEventDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  final month = months[date.month - 1];
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$month ${date.day}, ${date.year} at $hour:$minute';
}
