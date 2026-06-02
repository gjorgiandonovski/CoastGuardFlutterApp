import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/event.dart';
import '../services/event_api_service.dart';
import 'create_event_screen.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final EventApiService _eventApiService = EventApiService();
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  Future<void> _deleteEvent(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text('Are you sure you want to delete this event?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      await _eventApiService.deleteEvent(id);
    }
  }

  Future<void> _toggleJoin(Event event) async {
    if (_currentUserId == null) return;

    final isJoined = event.participantIds.contains(_currentUserId);
    if (isJoined) {
      await _eventApiService.unjoinEvent(event.id, _currentUserId!);
    } else {
      if (event.participantIds.length < event.maxParticipants) {
        await _eventApiService.joinEvent(event.id, _currentUserId!);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event is full')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<Event>>(
        stream: _eventApiService.watchUpcomingEvents(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final events = snapshot.data ?? [];
          if (events.isEmpty) return const Center(child: Text('No upcoming cleanup events.'));

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final event = events[index];
              final isOrganizer = event.createdBy == _currentUserId;
              final isJoined = _currentUserId != null && event.participantIds.contains(_currentUserId);
              final isFull = event.participantIds.length >= event.maxParticipants;

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.blueAccent,
                    child: Icon(Icons.volunteer_activism, color: Colors.white),
                  ),
                  title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Participants: ${event.participantIds.length}/${event.maxParticipants}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isOrganizer) ...[
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => CreateEventScreen(event: event)),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteEvent(event.id),
                        ),
                      ] else ...[
                        TextButton.icon(
                          onPressed: () => _toggleJoin(event),
                          icon: Icon(
                            isJoined ? Icons.remove_circle_outline : Icons.add_circle_outline,
                            color: isJoined ? Colors.red : Colors.green,
                          ),
                          label: Text(
                            isJoined ? 'Unjoin' : 'Join',
                            style: TextStyle(color: isJoined ? Colors.red : Colors.green),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CreateEventScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
