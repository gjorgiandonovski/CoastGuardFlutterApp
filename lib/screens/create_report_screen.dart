import 'package:flutter/material.dart';

import '../models/beach.dart';
import '../services/auth_service.dart';
import '../services/beach_api_service.dart';
import '../services/report_api_service.dart';

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
  final AuthService _authService = AuthService();
  final BeachApiService _beachApiService = BeachApiService();
  final ReportApiService _reportApiService = ReportApiService();

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

  Beach? _selectedBeach(List<Beach> beaches) {
    for (final beach in beaches) {
      if (beach.id == _selectedBeachId) {
        return beach;
      }
    }

    return null;
  }

  Future<void> _submitReport(List<Beach> beaches) async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    final selectedBeach = _selectedBeach(beaches);
    if (selectedBeach == null) {
      _showSnackBar('Select a beach before submitting.');
      return;
    }

    if (!selectedBeach.hasCoordinates) {
      _showSnackBar('The selected beach does not have GPS coordinates.');
      return;
    }

    final user = _authService.currentUser;
    if (user == null) {
      _showSnackBar('You must be signed in to submit a report.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _reportApiService.submitReport(
        user: user,
        beach: selectedBeach,
        category: _selectedCategory!,
        severity: _selectedSeverity,
        description: _descriptionController.text.trim(),
        hasPhoto: _hasPhoto,
      );

      if (!mounted) {
        return;
      }

      Navigator.pop(context);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSubmitting = false;
      });
      _showSnackBar('Error: $error');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Coastal Report')),
      body: StreamBuilder<List<Beach>>(
        stream: _beachApiService.watchBeaches(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final beaches = snapshot.data ?? const <Beach>[];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedBeachId,
                    decoration: const InputDecoration(
                      labelText: 'Beach',
                      border: OutlineInputBorder(),
                    ),
                    items: beaches
                        .map(
                          (b) => DropdownMenuItem(
                            value: b.id,
                            child: Text(b.name),
                          ),
                        )
                        .toList(),
                    onChanged: _isSubmitting
                        ? null
                        : (val) => setState(() => _selectedBeachId = val),
                    validator: (val) => val == null ? 'Select a beach' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items: _issueCategories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: _isSubmitting
                        ? null
                        : (val) => setState(() => _selectedCategory = val),
                    validator: (val) => val == null ? 'Select category' : null,
                  ),
                  const SizedBox(height: 16),
                  const Text('Severity'),
                  SegmentedButton<String>(
                    segments: _severityLevels
                        .map((s) => ButtonSegment(value: s, label: Text(s)))
                        .toList(),
                    selected: {_selectedSeverity},
                    onSelectionChanged: _isSubmitting
                        ? null
                        : (val) =>
                              setState(() => _selectedSeverity = val.first),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 4,
                    validator: (val) =>
                        (val?.isEmpty ?? true) ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Photo attached'),
                    value: _hasPhoto,
                    onChanged: _isSubmitting
                        ? null
                        : (val) => setState(() => _hasPhoto = val),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => _submitReport(beaches),
                      child: _isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Submit Report'),
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
