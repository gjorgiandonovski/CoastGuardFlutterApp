import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/beach.dart';
import '../services/beach_api_service.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _participantsController = TextEditingController(text: '10');
  
  String? _selectedBeachId;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  bool _isSubmitting = false;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submitEvent() async {
    if (!_formKey.currentState!.validate() || _selectedBeachId == null) return;
    
    setState(() => _isSubmitting = true);
    final user = FirebaseAuth.instance.currentUser;

    try {
      await FirebaseFirestore.instance.collection('events').add({
        'title': _titleController.text.trim(),
        'beachId': _selectedBeachId,
        'maxParticipants': int.parse(_participantsController.text),
        'dateEpochMs': _selectedDate.millisecondsSinceEpoch,
        'organizerId': user?.uid,
        'participantIds': [user?.uid],
        'status': 'SCHEDULED',
        'createdAtEpochMs': DateTime.now().millisecondsSinceEpoch,
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Cleanup Event')),
      body: StreamBuilder<List<Beach>>(
        stream: BeachApiService().watchBeaches(),
        builder: (context, snapshot) {
          final beaches = snapshot.data ?? [];
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Event Title', border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Beach', border: OutlineInputBorder()),
                    items: beaches.map((b) => DropdownMenuItem(value: b.id, child: Text(b.name))).toList(),
                    onChanged: (val) => setState(() => _selectedBeachId = val),
                    validator: (val) => val == null ? 'Select a beach' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _participantsController,
                    decoration: const InputDecoration(labelText: 'Max Participants', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    validator: (v) => int.tryParse(v!) == null ? 'Enter a valid number' : null,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('Event Date'),
                    subtitle: Text("${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}"),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () => _selectDate(context),
                    shape: RoundedRectangleBorder(side: const BorderSide(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
                  ),
                  const SizedBox(height: 24),
                  _isSubmitting 
                    ? const CircularProgressIndicator()
                    : SizedBox(
                        width: double.infinity,
                        child: FilledButton(onPressed: _submitEvent, child: const Text('Publish Event')),
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
