import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          const ListTile(
            leading: Icon(Icons.person),
            title: Text('Profile'),
            subtitle: Text('Edit your profile information'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.dark_mode),
            title: const Text('Dark Mode'),
            trailing: Switch(
              value: false,
              onChanged: (value) {
                // TODO: Toggle dark mode
              },
            ),
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.language),
            title: Text('Language'),
            subtitle: Text('English'),
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.share),
            title: Text('Export Journal'),
            subtitle: Text('Export as PDF or images'),
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.delete),
            title: Text('Clear Data'),
            subtitle: Text('Reset all trips and data'),
          ),
        ],
      ),
    );
  }
}
