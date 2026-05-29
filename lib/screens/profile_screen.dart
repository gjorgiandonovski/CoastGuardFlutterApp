import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text('No user logged in.'));
    }

    final firestore = FirebaseFirestore.instance;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: firestore.collection('users').doc(user.uid).snapshots(),
      builder: (context, userSnapshot) {
        if (userSnapshot.hasError) {
          return Center(child: Text('Error: ${userSnapshot.error}'));
        }
        if (userSnapshot.connectionState == ConnectionState.waiting &&
            !userSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final profile = _UserProfile.fromSnapshot(userSnapshot.data, user);

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: firestore
              .collection('reports')
              .where('userId', isEqualTo: user.uid)
              .snapshots(),
          builder: (context, reportsSnapshot) {
            if (reportsSnapshot.hasError) {
              return Center(child: Text('Error: ${reportsSnapshot.error}'));
            }
            if (reportsSnapshot.connectionState == ConnectionState.waiting &&
                !reportsSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final reports =
                reportsSnapshot.data?.docs
                    .map(_ProfileReportItem.fromDocument)
                    .toList() ??
                const <_ProfileReportItem>[];
            reports.sort(
              (a, b) => b.createdAtEpochMs.compareTo(a.createdAtEpochMs),
            );

            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: firestore
                  .collection('events')
                  .where('participantIds', arrayContains: user.uid)
                  .snapshots(),
              builder: (context, eventsSnapshot) {
                if (eventsSnapshot.hasError) {
                  return Center(child: Text('Error: ${eventsSnapshot.error}'));
                }
                if (eventsSnapshot.connectionState == ConnectionState.waiting &&
                    !eventsSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final joinedEvents =
                    eventsSnapshot.data?.docs
                        .map(_ProfileEventItem.fromDocument)
                        .toList() ??
                    const <_ProfileEventItem>[];
                joinedEvents.sort(
                  (a, b) => a.dateEpochMs.compareTo(b.dateEpochMs),
                );

                return _ProfileContent(
                  profile: profile,
                  reports: reports,
                  joinedEvents: joinedEvents,
                );
              },
            );
          },
        );
      },
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({
    required this.profile,
    required this.reports,
    required this.joinedEvents,
  });

  final _UserProfile profile;
  final List<_ProfileReportItem> reports;
  final List<_ProfileEventItem> joinedEvents;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 34,
                    child: Text(
                      profile.avatarInitial,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    profile.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Role: ${profile.role}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _ProfileMetricTile(
                icon: Icons.star_outline,
                label: 'Points',
                value: profile.points.toString(),
                color: const Color(0xFFF9A825),
              ),
              _ProfileMetricTile(
                icon: Icons.assignment_outlined,
                label: 'Reports',
                value: reports.length.toString(),
                color: const Color(0xFF1565C0),
              ),
              _ProfileMetricTile(
                icon: Icons.group_outlined,
                label: 'Joined events',
                value: joinedEvents.length.toString(),
                color: const Color(0xFF2E7D32),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showAdminMessage(context, profile.role),
                  icon: const Icon(Icons.admin_panel_settings_outlined),
                  label: const Text('Admin Dashboard'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => FirebaseAuth.instance.signOut(),
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            'Recent reports',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          if (reports.isEmpty)
            const _ProfileNotice(
              icon: Icons.assignment_outlined,
              message: 'You have not submitted any reports yet.',
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: reports.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final report = reports[index];
                return _ProfileReportCard(report: report);
              },
            ),
          const SizedBox(height: 22),
          Text(
            'Joined cleanup events',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          if (joinedEvents.isEmpty)
            const _ProfileNotice(
              icon: Icons.event_busy_outlined,
              message: 'You have not joined any cleanup events yet.',
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: joinedEvents.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final event = joinedEvents[index];
                return _ProfileEventCard(
                  event: event,
                  canDelete: event.createdBy == profile.userId,
                );
              },
            ),
        ],
      ),
    );
  }

  void _showAdminMessage(BuildContext context, String role) {
    final isAdmin = role.toLowerCase() == 'admin';
    final message = isAdmin
        ? 'Admin dashboard is not implemented yet.'
        : 'Admin access required.';

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ProfileMetricTile extends StatelessWidget {
  const _ProfileMetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _ProfileNotice extends StatelessWidget {
  const _ProfileNotice({required this.icon, required this.message});

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

class _ProfileReportCard extends StatelessWidget {
  const _ProfileReportCard({required this.report});

  final _ProfileReportItem report;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.category,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        report.beach,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                _InlineStatusBadge(
                  label: report.status,
                  color: _reportStatusColor(report.status),
                ),
                IconButton(
                  tooltip: 'Delete report',
                  onPressed: () => _confirmDeleteReport(context, report),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              report.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InlineChip(icon: Icons.priority_high, label: report.severity),
                _InlineChip(
                  icon: Icons.schedule_outlined,
                  label: report.formattedDate,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteReport(
    BuildContext context,
    _ProfileReportItem report,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete report'),
          content: Text('Delete your report for ${report.beach}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('reports')
          .doc(report.id)
          .delete();
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Report deleted.')));
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete report: $error')),
      );
    }
  }
}

class _ProfileEventCard extends StatelessWidget {
  const _ProfileEventCard({required this.event, required this.canDelete});

  final _ProfileEventItem event;
  final bool canDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
                _InlineStatusBadge(
                  label: event.status,
                  color: _eventStatusColor(event.status),
                ),
                if (canDelete)
                  IconButton(
                    tooltip: 'Delete event',
                    onPressed: () => _confirmDeleteEvent(context, event),
                    icon: const Icon(Icons.delete_outline),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InlineChip(
                  icon: Icons.schedule_outlined,
                  label: event.formattedDate,
                ),
                _InlineChip(
                  icon: Icons.group_outlined,
                  label: '${event.participantCount}/${event.maxParticipants}',
                ),
                if (canDelete)
                  const _InlineChip(
                    icon: Icons.edit_calendar_outlined,
                    label: 'Created by you',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteEvent(
    BuildContext context,
    _ProfileEventItem event,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete cleanup event'),
          content: Text('Delete ${event.title}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('events')
          .doc(event.id)
          .delete();
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cleanup event deleted.')));
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete event: $error')));
    }
  }
}

class _InlineStatusBadge extends StatelessWidget {
  const _InlineStatusBadge({required this.label, required this.color});

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

class _InlineChip extends StatelessWidget {
  const _InlineChip({required this.icon, required this.label});

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

class _UserProfile {
  const _UserProfile({
    required this.userId,
    required this.name,
    required this.role,
    required this.points,
  });

  final String userId;
  final String name;
  final String role;
  final int points;

  String get avatarInitial {
    final normalized = name.trim();
    if (normalized.isEmpty) {
      return '?';
    }
    return normalized.characters.first.toUpperCase();
  }

  factory _UserProfile.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>>? snapshot,
    User user,
  ) {
    final data = snapshot?.data() ?? <String, dynamic>{};
    final fallbackName = user.displayName?.trim().isNotEmpty == true
        ? user.displayName!.trim()
        : (user.email?.trim().isNotEmpty == true ? user.email!.trim() : 'User');

    return _UserProfile(
      userId: user.uid,
      name: _readString(data, const ['name'], fallbackName),
      role: _readString(data, const ['role'], 'User'),
      points: _readInt(data['points']) ?? 0,
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

  static int? _readInt(Object? value) {
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
}

class _ProfileReportItem {
  const _ProfileReportItem({
    required this.id,
    required this.beach,
    required this.category,
    required this.severity,
    required this.status,
    required this.description,
    required this.createdAtEpochMs,
  });

  final String id;
  final String beach;
  final String category;
  final String severity;
  final String status;
  final String description;
  final int createdAtEpochMs;

  String get formattedDate =>
      _formatDate(DateTime.fromMillisecondsSinceEpoch(createdAtEpochMs));

  factory _ProfileReportItem.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();

    return _ProfileReportItem(
      id: doc.id,
      beach: _readString(data, const ['beach', 'beachName'], 'Unknown beach'),
      category: _readString(data, const ['category'], 'Unknown issue'),
      severity: _readString(data, const ['severity'], 'Unknown'),
      status: _readString(data, const ['status'], 'N/A'),
      description: _readString(data, const ['description'], 'No description'),
      createdAtEpochMs: _readInt(data['createdAtEpochMs']) ?? 0,
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

  static int? _readInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.round();
    }
    if (value is Timestamp) {
      return value.millisecondsSinceEpoch;
    }
    if (value is String) {
      return int.tryParse(value.trim());
    }
    return null;
  }
}

class _ProfileEventItem {
  const _ProfileEventItem({
    required this.id,
    required this.title,
    required this.beach,
    required this.status,
    required this.createdBy,
    required this.dateEpochMs,
    required this.participantCount,
    required this.maxParticipants,
  });

  final String id;
  final String title;
  final String beach;
  final String status;
  final String createdBy;
  final int dateEpochMs;
  final int participantCount;
  final int maxParticipants;

  String get formattedDate =>
      _formatDate(DateTime.fromMillisecondsSinceEpoch(dateEpochMs));

  factory _ProfileEventItem.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final participantIds = _readStringList(data['participantIds']);

    return _ProfileEventItem(
      id: doc.id,
      title: _readString(data, const ['title'], 'Cleanup event'),
      beach: _readString(data, const ['beach', 'beachName'], 'Unknown beach'),
      status: _readString(data, const ['status'], 'SCHEDULED'),
      createdBy: _readString(data, const ['createdBy'], ''),
      dateEpochMs: _readInt(data['dateEpochMs']) ?? 0,
      participantCount:
          _readInt(data['participantCount']) ?? participantIds.length,
      maxParticipants: _readInt(data['maxParticipants']) ?? 50,
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

  static List<String> _readStringList(Object? value) {
    if (value is Iterable) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return <String>[];
  }

  static int? _readInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.round();
    }
    if (value is Timestamp) {
      return value.millisecondsSinceEpoch;
    }
    if (value is String) {
      return int.tryParse(value.trim());
    }
    return null;
  }
}

Color _reportStatusColor(String status) {
  switch (status.toUpperCase()) {
    case 'UNDER_REVIEW':
      return const Color(0xFFEF6C00);
    case 'RESOLVED':
      return const Color(0xFF2E7D32);
    case 'REJECTED':
      return const Color(0xFFC62828);
    default:
      return const Color(0xFF546E7A);
  }
}

Color _eventStatusColor(String status) {
  switch (status.toUpperCase()) {
    case 'SCHEDULED':
      return const Color(0xFF1565C0);
    case 'COMPLETED':
      return const Color(0xFF2E7D32);
    case 'CANCELLED':
      return const Color(0xFFC62828);
    default:
      return const Color(0xFF546E7A);
  }
}

String _formatDate(DateTime date) {
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
