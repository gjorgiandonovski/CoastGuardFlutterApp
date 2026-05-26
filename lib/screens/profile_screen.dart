import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(
        child: Text('No user logged in.'),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text('User profile not found.'));
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const CircleAvatar(
                radius: 50,
                child: Icon(Icons.person, size: 50),
              ),
              const SizedBox(height: 16),
              Text(
                data['name'] ?? 'No name',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Text('Role: ${data['role'] ?? 'User'}'),
              const Divider(height: 32),
              ListTile(
                leading: const Icon(Icons.star, color: Colors.amber),
                title: const Text('Points'),
                trailing: Text(
                  data['points']?.toString() ?? '0',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const ListTile(
                leading: Icon(Icons.badge),
                title: Text('Badges'),
              ),
              // Aquí podrías mapear los badges si son un array simple
              Wrap(
                spacing: 8,
                children: ((data['badges'] as List?) ?? []).map((badge) {
                  return Chip(label: Text(badge.toString()));
                }).toList(),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => FirebaseAuth.instance.signOut(),
                child: const Text('Sign Out'),
              ),
            ],
          ),
        );
      },
    );
  }
}
