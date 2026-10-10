import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/notification_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late String name;
  late String email;

  @override
  void initState() {
    super.initState();

    final user = FirebaseAuth.instance.currentUser;

    email = user?.email ?? '';

    final displayName = user?.displayName;

    name = (displayName != null && displayName.trim().isNotEmpty)
        ? displayName
        : _nameFromEmail(email);
  }

  // "juan.delacruz@mail.com" -> "juan.delacruz"
  String _nameFromEmail(String value) {
    if (value.isEmpty) return 'MediTrack User';
    return value.split('@').first;
  }

  // ------------------------------------------------------------
  // EDIT PROFILE (name only - email changes need verification)
  // ------------------------------------------------------------

  void editProfile() {
    final nameController = TextEditingController(text: name);
    final emailController = TextEditingController(text: email);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                enabled: false,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  helperText: 'Your sign-in email cannot be changed here.',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final newName = nameController.text.trim();

                Navigator.pop(dialogContext);

                if (newName.isEmpty || newName == name) return;

                try {
                  await FirebaseAuth.instance.currentUser?.updateDisplayName(
                    newName,
                  );

                  if (!mounted) return;

                  setState(() {
                    name = newName;
                  });
                } catch (_) {
                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Could not update your name. Please try again.',
                      ),
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // ------------------------------------------------------------
  // LOG OUT
  // ------------------------------------------------------------

  Future<void> confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Log out?'),
          content: const Text(
            'You will need to sign in again to see your medicines.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F),
              ),
              child: const Text('Log out'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    // Go back to the login screen and clear all previous screens.
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'MediTrack',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(
        Icons.medication_rounded,
        color: Color(0xFF1976D2),
        size: 40,
      ),
      children: const [
        Text(
          'MediTrack helps users organize their medication schedules, '
          'track taken doses, and manage medication reminders.',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 42,
                  backgroundColor: Color(0xFFEAF4FF),
                  child: Icon(Icons.person, size: 45, color: Color(0xFF1976D2)),
                ),
                const SizedBox(height: 12),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(email, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: editProfile,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit Profile'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Preferences',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: Color(0xFF172B4D),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: ValueListenableBuilder<bool>(
              valueListenable: remindersEnabledNotifier,
              builder: (context, enabled, _) {
                return Column(
                  children: [
                    SwitchListTile(
                      value: enabled,
                      onChanged: (value) => setRemindersEnabled(value),
                      secondary: const Icon(
                        Icons.notifications_active_outlined,
                        color: Color(0xFF1976D2),
                      ),
                      title: const Text('Medication Reminders'),
                      subtitle: const Text(
                        'Enable medication reminder notifications',
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'More',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: Color(0xFF172B4D),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('About MediTrack'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: showAbout,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: const Text('Help & Support'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Help & Support will be available in a future version.',
                        ),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout, color: Color(0xFFD32F2F)),
                  title: const Text(
                    'Log out',
                    style: TextStyle(color: Color(0xFFD32F2F)),
                  ),
                  onTap: confirmLogout,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
