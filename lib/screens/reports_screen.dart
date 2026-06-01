import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  static const List<String> _issueCategories = [
    'Polluted Water',
    'Trash',
    'Dead Fish',
    'Dead Sea Animal',
    'Oil Spill',
    'Sewage-like Water',
    'Bad Smell',
    'Algae',
    'Dangerous Swimming Zone',
    'Other',
  ];

  static const List<String> _severityLevels = [
    'Low',
    'Medium',
    'High',
    'Critical',
  ];

  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();

  String? _selectedBeachId;
  String? _selectedCategory;
  String _selectedSeverity = 'Medium';
  bool _hasPhoto = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

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
              _ReportFormCard(
                formKey: _formKey,
                beaches: beaches,
                selectedBeachId: _selectedBeachId,
                selectedBeach: selectedBeach,
                selectedCategory: _selectedCategory,
                selectedSeverity: _selectedSeverity,
                descriptionController: _descriptionController,
                hasPhoto: _hasPhoto,
                isSubmitting: _isSubmitting,
                onBeachChanged: (value) {
                  setState(() {
                    _selectedBeachId = value;
                  });
                },
                onCategoryChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
                onSeverityChanged: (value) {
                  setState(() {
                    _selectedSeverity = value;
                  });
                },
                onPhotoChanged: (value) {
                  setState(() {
                    _hasPhoto = value;
                  });
                },
                onSubmit: () => _submitReport(beaches),
              ),
              const SizedBox(height: 20),
              const Text('Recent reports'),
              const SizedBox(height: 10),
              const _RecentReportsSection(),
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

  Future<void> _submitReport(List<_BeachOption> beaches) async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    final selectedBeach = _selectedBeach(beaches);
    if (selectedBeach == null) {
      _showSnackBar('Select a beach before submitting.');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackBar('You must be signed in to submit a report.');
      return;
    }

    if (!selectedBeach.hasCoordinates) {
      _showSnackBar('The selected beach does not have GPS coordinates.');
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isSubmitting = true;
    });

    final now = DateTime.now();

    try {
      final firestore = FirebaseFirestore.instance;
      final reportRef = firestore.collection('reports').doc();
      final userRef = firestore.collection('users').doc(user.uid);
      final notificationRef = firestore.collection('notifications').doc();
      final description = _descriptionController.text.trim();


      final batch = firestore.batch();
      batch.set(reportRef, {
        'beachId': selectedBeach.id,
        'beach': selectedBeach.name,
        'category': _selectedCategory,
        'severity': _selectedSeverity,
        'description': description,
        'hasPhoto': _hasPhoto,
        'latitude': selectedBeach.latitude,
        'longitude': selectedBeach.longitude,
        'status': 'UNDER_REVIEW',
        'userId': user.uid,
        'userEmail': user.email,
        'createdAt': Timestamp.fromDate(now),
        'createdAtEpochMs': now.millisecondsSinceEpoch,
      });

      final beachRef = firestore.collection('beaches').doc(selectedBeach.id);
      batch.set(beachRef, {
        'reportTypes': FieldValue.arrayUnion([_selectedCategory]),
        'reportCount': FieldValue.increment(1),
      }, SetOptions(merge: true));

      batch.set(beachRef, {
        'reportTypes': FieldValue.arrayUnion([_selectedCategory]),
        'reportCount': FieldValue.increment(1),
        'latestIssueSeverity': _selectedSeverity,
      }, SetOptions(merge: true));

      batch.set(userRef, {
        'email': user.email,
        'points': FieldValue.increment(100),
        'updatedAt': Timestamp.fromDate(now),
      }, SetOptions(merge: true));

      batch.set(notificationRef, {
        'userId': user.uid,
        'title': 'Report submitted',
        'message':
            'Your report for ${selectedBeach.name} is under review. You earned 100 points.',
        'type': 'report',
        'isRead': false,
        'reportId': reportRef.id,
        'createdAt': Timestamp.fromDate(now),
        'createdAtEpochMs': now.millisecondsSinceEpoch,
      });

      await batch.commit();

      if (!mounted) {
        return;
      }

      setState(() {
        _selectedBeachId = null;
        _selectedCategory = null;
        _selectedSeverity = 'Medium';
        _hasPhoto = false;
        _isSubmitting = false;
      });
      _descriptionController.clear();
      _showSnackBar('Report submitted and sent for review.');
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSubmitting = false;
      });
      _showSnackBar('Failed to submit report: $error');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ReportFormCard extends StatelessWidget {
  const _ReportFormCard({
    required this.formKey,
    required this.beaches,
    required this.selectedBeachId,
    required this.selectedBeach,
    required this.selectedCategory,
    required this.selectedSeverity,
    required this.descriptionController,
    required this.hasPhoto,
    required this.isSubmitting,
    required this.onBeachChanged,
    required this.onCategoryChanged,
    required this.onSeverityChanged,
    required this.onPhotoChanged,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final List<_BeachOption> beaches;
  final String? selectedBeachId;
  final _BeachOption? selectedBeach;
  final String? selectedCategory;
  final String selectedSeverity;
  final TextEditingController descriptionController;
  final bool hasPhoto;
  final bool isSubmitting;
  final ValueChanged<String?> onBeachChanged;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<String> onSeverityChanged;
  final ValueChanged<bool> onPhotoChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final canSubmit =
        !isSubmitting &&
        beaches.isNotEmpty &&
        selectedBeach != null &&
        selectedBeach!.hasCoordinates;

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
                'Submit a coastal issue report',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Beach coordinates are pulled from the selected beach record.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              if (beaches.isEmpty)
                _FormNotice(
                  icon: Icons.beach_access_outlined,
                  message:
                      'No beaches are available yet. Add beach documents to Firestore before submitting reports.',
                )
              else ...[
                DropdownButtonFormField<String>(
                  key: ValueKey('beach-$selectedBeachId'),
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
                  onChanged: isSubmitting ? null : onBeachChanged,
                  validator: (value) =>
                      value == null ? 'Select a beach.' : null,
                ),
                const SizedBox(height: 16),
                _ReadOnlyField(
                  label: 'GPS coordinates',
                  value: selectedBeach == null
                      ? 'Select a beach'
                      : selectedBeach!.coordinatesLabel,
                  helperText:
                      selectedBeach != null && !selectedBeach!.hasCoordinates
                      ? 'This beach is missing latitude or longitude.'
                      : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  key: ValueKey('category-$selectedCategory'),
                  initialValue: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Issue category',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final category in _ReportsScreenState._issueCategories)
                      DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      ),
                  ],
                  onChanged: isSubmitting ? null : onCategoryChanged,
                  validator: (value) =>
                      value == null ? 'Select an issue category.' : null,
                ),
                const SizedBox(height: 16),
                Text('Severity', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                _SeveritySelector(
                  value: selectedSeverity,
                  enabled: !isSubmitting,
                  onChanged: onSeverityChanged,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descriptionController,
                  enabled: !isSubmitting,
                  minLines: 4,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) {
                      return 'Enter a description.';
                    }
                    if (text.length < 10) {
                      return 'Use at least 10 characters.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Photo available'),
                  subtitle: const Text(
                    'Local placeholder only. No camera or upload is connected.',
                  ),
                  value: hasPhoto,
                  onChanged: isSubmitting ? null : onPhotoChanged,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: canSubmit ? onSubmit : null,
                    icon: isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_outlined),
                    label: Text(
                      isSubmitting ? 'Submitting...' : 'Submit report',
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

class _SeveritySelector extends StatelessWidget {
  const _SeveritySelector({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String value;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 420) {
          return SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'Low', label: Text('Low')),
              ButtonSegment(value: 'Medium', label: Text('Medium')),
              ButtonSegment(value: 'High', label: Text('High')),
              ButtonSegment(value: 'Critical', label: Text('Critical')),
            ],
            selected: {value},
            showSelectedIcon: false,
            onSelectionChanged: enabled
                ? (selection) => onChanged(selection.first)
                : null,
          );
        }

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final level in _ReportsScreenState._severityLevels)
              ChoiceChip(
                label: Text(level),
                selected: value == level,
                onSelected: enabled ? (_) => onChanged(level) : null,
              ),
          ],
        );
      },
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({
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

class _FormNotice extends StatelessWidget {
  const _FormNotice({required this.icon, required this.message});

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

class _RecentReportsSection extends StatelessWidget {
  const _RecentReportsSection();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('reports')
          .orderBy('createdAtEpochMs', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const _FormNotice(
            icon: Icons.assignment_outlined,
            message: 'No reports have been submitted yet.',
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final report = _ReportItem.fromDocument(docs[index]);
            return _ReportCard(report: report);
          },
        );
      },
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report});

  final _ReportItem report;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final severityColor = _severityColor(report.severity);

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
                  backgroundColor: severityColor.withValues(alpha: 0.12),
                  child: Icon(
                    _categoryIcon(report.category),
                    color: severityColor,
                  ),
                ),
                const SizedBox(width: 12),
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
                _SeverityBadge(label: report.severity, color: severityColor),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetadataChip(
                  icon: Icons.location_on_outlined,
                  label: report.coordinatesLabel,
                ),
                _MetadataChip(
                  icon: report.hasPhoto
                      ? Icons.photo_camera_outlined
                      : Icons.photo_camera_back_outlined,
                  label: report.hasPhoto ? 'Photo available' : 'No photo flag',
                ),
                if (report.status.isNotEmpty)
                  _MetadataChip(icon: Icons.info_outline, label: report.status),
              ],
            ),
            const SizedBox(height: 12),
            Text(report.description),
          ],
        ),
      ),
    );
  }
}

class _SeverityBadge extends StatelessWidget {
  const _SeverityBadge({required this.label, required this.color});

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

class _MetadataChip extends StatelessWidget {
  const _MetadataChip({required this.icon, required this.label});

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
  const _BeachOption({
    required this.id,
    required this.name,
    this.latitude,
    this.longitude,
  });

  final String id;
  final String name;
  final double? latitude;
  final double? longitude;

  bool get hasCoordinates => latitude != null && longitude != null;
  String get coordinatesLabel => hasCoordinates
      ? '${latitude!.toStringAsFixed(5)}, ${longitude!.toStringAsFixed(5)}'
      : 'Coordinates unavailable';

  factory _BeachOption.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final location = data['location'];

    return _BeachOption(
      id: doc.id,
      name: _readString(data, const ['name', 'beachName', 'title'], doc.id),
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
}

class _ReportItem {
  const _ReportItem({
    required this.beach,
    required this.category,
    required this.severity,
    required this.description,
    required this.hasPhoto,
    required this.status,
    this.latitude,
    this.longitude,
  });

  final String beach;
  final String category;
  final String severity;
  final String description;
  final bool hasPhoto;
  final String status;
  final double? latitude;
  final double? longitude;

  String get coordinatesLabel {
    if (latitude == null || longitude == null) {
      return 'Coordinates unavailable';
    }

    return '${latitude!.toStringAsFixed(5)}, ${longitude!.toStringAsFixed(5)}';
  }

  factory _ReportItem.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();

    return _ReportItem(
      beach: _readString(data, const ['beach', 'beachName'], 'Unknown beach'),
      category: _readString(data, const ['category'], 'Uncategorized issue'),
      severity: _readString(data, const ['severity'], 'Unknown'),
      description: _readString(data, const ['description'], 'No description'),
      hasPhoto: data['hasPhoto'] == true || data['photoFlag'] == true,
      status: _readString(data, const ['status'], ''),
      latitude: _readDouble(data, const ['latitude', 'lat']),
      longitude: _readDouble(data, const ['longitude', 'lng', 'lon']),
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
}

Color _severityColor(String severity) {
  switch (severity.toLowerCase()) {
    case 'low':
      return const Color(0xFF2E7D32);
    case 'medium':
      return const Color(0xFFEF6C00);
    case 'high':
      return const Color(0xFFC62828);
    case 'critical':
      return const Color(0xFF6A1B9A);
    default:
      return const Color(0xFF546E7A);
  }
}

IconData _categoryIcon(String category) {
  switch (category.toLowerCase()) {
    case 'polluted water':
    case 'sewage-like water':
      return Icons.water_drop_outlined;
    case 'trash':
      return Icons.delete_outline;
    case 'dead fish':
    case 'dead sea animal':
      return Icons.crisis_alert_outlined;
    case 'oil spill':
      return Icons.opacity_outlined;
    case 'bad smell':
      return Icons.air_outlined;
    case 'algae':
      return Icons.spa_outlined;
    case 'dangerous swimming zone':
      return Icons.warning_amber_outlined;
    default:
      return Icons.assignment_outlined;
  }
}
