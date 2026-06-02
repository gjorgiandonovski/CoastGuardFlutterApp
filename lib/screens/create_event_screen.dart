import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/beach.dart';
import '../models/event.dart';
import '../services/beach_api_service.dart';
import '../services/event_api_service.dart';

class CreateEventScreen extends StatefulWidget {
  final Event? event;
  const CreateEventScreen({super.key, this.event});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final EventApiService _eventApiService = EventApiService();
  final BeachApiService _beachApiService = BeachApiService();
  
  late TextEditingController _titleController;
  late TextEditingController _participantsController;
  
  String? _selectedBeachId;
  late DateTime _selectedDate;
  bool _isSubmitting = false;

  bool get _isEditing => widget.event != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event?.title ?? '');
    _participantsController = TextEditingController(text: widget.event?.maxParticipants.toString() ?? '10');
    _selectedBeachId = widget.event?.beachId;
    _selectedDate = widget.event != null 
        ? DateTime.fromMillisecondsSinceEpoch(widget.event!.dateEpochMs)
        : DateTime.now().add(const Duration(days: 1));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _participantsController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submitEvent(List<Beach> beaches) async {
    if (!_formKey.currentState!.validate() || _selectedBeachId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You must be logged in')));
      return;
    }

    setState(() => _isSubmitting = true);
    
    try {
      final selectedBeach = beaches.firstWhere((b) => b.id == _selectedBeachId);
      final maxParticipants = int.parse(_participantsController.text);

      if (_isEditing) {
        await _eventApiService.updateEvent(
          eventId: widget.event!.id,
          title: _titleController.text.trim(),
          beachId: selectedBeach.id,
          beachName: selectedBeach.name,
          date: _selectedDate,
          maxParticipants: maxParticipants,
        );
      } else {
        await _eventApiService.createCleanupEvent(
          user: user,
          beach: selectedBeach,
          title: _titleController.text.trim(),
          date: _selectedDate,
          maxParticipants: maxParticipants,
        );
      }

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
      appBar: AppBar(title: Text(_isEditing ? 'Edit Event' : 'Create Event')),
      body: StreamBuilder<List<Beach>>(
        stream: _beachApiService.watchBeaches(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
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
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedBeachId,
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
                    validator: (v) => int.tryParse(v ?? '') == null ? 'Enter a valid number' : null,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('Event Date'),
                    subtitle: Text("${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}"),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () => _selectDate(context),
                    shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(4)),
                  ),
                  const SizedBox(height: 32),
                  _isSubmitting 
                    ? const CircularProgressIndicator()
                    : SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton(
                          onPressed: () => _submitEvent(beaches), 
                          child: Text(_isEditing ? 'Update Event' : 'Publish Event'),
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
