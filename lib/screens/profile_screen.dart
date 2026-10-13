
import 'package:flutter/material.dart';
import '../services/session.dart';
import '../utils/constants.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 20),
          CircleAvatar(
            radius: 48,
            backgroundColor: AppConstants.primaryColor.withOpacity(0.12),
            child: const Icon(
              Icons.person,
              size: 55,
              color: AppConstants.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Full Name'),
              subtitle: Text(Session.name ?? 'Not available'),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.email_outlined),
              title: const Text('Email Address'),
              subtitle: Text(Session.email ?? 'Not available'),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.verified_user_outlined),
              title: const Text('Account'),
              subtitle: Text(
                Session.userId == null
                    ? 'Not logged in'
                    : 'User ID: ${Session.userId}',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
