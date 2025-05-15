import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  final VoidCallback onThemeChange;

  const SettingsPage({super.key, required this.onThemeChange});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor:
            Theme.of(
              context,
            ).appBarTheme.backgroundColor, // Dynamic app bar color
        foregroundColor:
            Theme.of(context).appBarTheme.foregroundColor, // Dynamic text color
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ), // Explicitly set to white
          onPressed: () {
            Navigator.of(context).pop(); // Close the settings page
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Settings',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color:
                    Theme.of(
                      context,
                    ).textTheme.bodyLarge?.color, // Dynamic text color
              ),
            ),
            const SizedBox(height: 16),

            // Profile Info Option
            ListTile(
              title: Text(
                'Profile Info',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ), // Dynamic text color
              ),
              trailing: Icon(
                Icons.arrow_forward,
                color: Theme.of(context).iconTheme.color,
              ), // Dynamic icon color
              onTap: () {
                // Add functionality here in the future
              },
            ),
            const SizedBox(height: 16),

            // Theme Change Button
            ElevatedButton(
              onPressed: onThemeChange,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    Theme.of(
                      context,
                    ).colorScheme.primary, // Dynamic button color
                foregroundColor:
                    Theme.of(
                      context,
                    ).colorScheme.onPrimary, // Dynamic text color
              ),
              child: const Text('Change Theme'),
            ),
            const SizedBox(height: 16),

            // Sign Out Button
            ElevatedButton(
              onPressed: () {
                // Redirect to the login page
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    Theme.of(context).colorScheme.error, // Dynamic button color
                foregroundColor:
                    Theme.of(context).colorScheme.onError, // Dynamic text color
              ),
              child: const Text('Sign Out'),
            ),
          ],
        ),
      ),
    );
  }
}
