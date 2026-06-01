import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CreateReportScreen extends StatefulWidget {
  const CreateReportScreen({super.key});

  @override
  State<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends State<CreateReportScreen> {
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

  Future<void> _submitReport(List<_BeachOption> beaches) async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) return;

    final selectedBeach = beaches.firstWhere((b) => b.id == _selectedBeachId, orElse: () => beaches.first);
    if (_selectedBeachId == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSubmitting = true);
    final now = DateTime.now();

    try {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();
      
      final reportRef = firestore.collection('reports').doc();
      final userRef = firestore.collection('users').doc(user.uid);
      final notificationRef = firestore.collection('notifications').doc();
      final beachRef = firestore.collection('beaches').doc(selectedBeach.id);

      batch.set(reportRef, {
        'beachId': selectedBeach.id,
        'beach': selectedBeach.name,
        'category': _selectedCategory,
        'severity': _selectedSeverity,
        'description': _descriptionController.text.trim(),
        'hasPhoto': _hasPhoto,
        'latitude': selectedBeach.latitude,
        'longitude': selectedBeach.longitude,
        'status': 'UNDER_REVIEW',
        'userId': user.uid,
        'userEmail': user.email,
        'createdAt': Timestamp.fromDate(now),
        'createdAtEpochMs': now.millisecondsSinceEpoch,
      });

      batch.set(beachRef, {
        'reportTypes': FieldValue.arrayUnion([_selectedCategory]),
        'reportCount': FieldValue.increment(1),
        'latestIssueSeverity': _selectedSeverity,
      }, SetOptions(merge: true));

      batch.set(userRef, {
        'points': FieldValue.increment(100),
        'updatedAt': Timestamp.fromDate(now),
      }, SetOptions(merge: true));

      batch.set(notificationRef, {
        'userId': user.uid,
        'title': 'Report submitted',
        'message': 'Your report for ${selectedBeach.name} is under review. You earned 100 points.',
        'type': 'report',
        'isRead': false,
        'reportId': reportRef.id,
        'createdAt': Timestamp.fromDate(now),
        'createdAtEpochMs': now.millisecondsSinceEpoch,
      });

      await batch.commit();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Coastal Report')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('beaches').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final beaches = snapshot.data!.docs.map((doc) => _BeachOption.fromDocument(doc)).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedBeachId,
                    decoration: const InputDecoration(labelText: 'Beach', border: OutlineInputBorder()),
                    items: beaches.map((b) => DropdownMenuItem(value: b.id, child: Text(b.name))).toList(),
                    onChanged: _isSubmitting ? null : (val) => setState(() => _selectedBeachId = val),
                    validator: (val) => val == null ? 'Select a beach' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                    items: _issueCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: _isSubmitting ? null : (val) => setState(() => _selectedCategory = val),
                    validator: (val) => val == null ? 'Select category' : null,
                  ),
                  const SizedBox(height: 16),
                  const Text('Severity'),
                  SegmentedButton<String>(
                    segments: _severityLevels.map((s) => ButtonSegment(value: s, label: Text(s))).toList(),
                    selected: {_selectedSeverity},
                    onSelectionChanged: _isSubmitting ? null : (val) => setState(() => _selectedSeverity = val.first),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                    maxLines: 4,
                    validator: (val) => (val?.isEmpty ?? true) ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Photo attached'),
                    value: _hasPhoto,
                    onChanged: _isSubmitting ? null : (val) => setState(() => _hasPhoto = val),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isSubmitting ? null : () => _submitReport(beaches),
                      child: _isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Text('Submit Report'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BeachOption {
  final String id, name;
  final double? latitude, longitude;
  _BeachOption({required this.id, required this.name, this.latitude, this.longitude});
  factory _BeachOption.fromDocument(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return _BeachOption(
      id: doc.id,
      name: d['name'] ?? 'Beach',
      latitude: (d['latitude'] as num?)?.toDouble(),
      longitude: (d['longitude'] as num?)?.toDouble(),
    );
  }
}
