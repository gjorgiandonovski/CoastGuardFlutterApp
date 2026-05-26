import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .orderBy('createdAtEpochMs', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) return const Center(child: Text('No alerts found.'));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: Icon(
                    data['isRead'] == true ? Icons.notifications_none : Icons.notifications_active,
                    color: data['isRead'] == true ? Colors.grey : Colors.red,
                  ),
                  title: Text(data['title'] ?? 'No title'),
                  subtitle: Text(data['message'] ?? 'No message'),
                  trailing: Text(data['type'] ?? ''),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
