import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  final VoidCallback onThemeChange;

  const SettingsPage({super.key, required this.onThemeChange});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool hideItems = false;
  bool hideOutfits = false;
  int? userId;

  @override
  void initState() {
    super.initState();
    _loadUserSettings();
  }

  Future<void> _loadUserSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUserId = prefs.getInt('user_id');
    if (currentUserId != null) {
      setState(() {
        userId = currentUserId;
        hideItems = prefs.getBool('hide_items_$userId') ?? false;
        hideOutfits = prefs.getBool('hide_outfits_$userId') ?? false;
      });
    }
  }

  Future<void> _toggleHideItems(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    if (userId != null) {
      await prefs.setBool('hide_items_$userId', value);
      setState(() {
        hideItems = value;
      });
    }
  }

  Future<void> _toggleHideOutfits(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    if (userId != null) {
      await prefs.setBool('hide_outfits_$userId', value);
      setState(() {
        hideOutfits = value;
      });
    }
  }

  void _showDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(title),
            content: SingleChildScrollView(child: Text(content)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Theme Toggle
          ListTile(
            leading: Icon(Icons.brightness_6, color: theme.iconTheme.color),
            title: Text(
              'Toggle Theme',
              style: TextStyle(color: theme.textTheme.bodyLarge?.color),
            ),
            subtitle: Text(
              'Switch between light and dark mode',
              style: TextStyle(color: theme.textTheme.bodyMedium?.color),
            ),
            onTap: widget.onThemeChange,
          ),
          const Divider(),

          // Show/Hide Items Option
          SwitchListTile(
            secondary: Icon(Icons.lock_outline, color: theme.iconTheme.color),
            title: Text(
              'Hide My Items',
              style: TextStyle(color: theme.textTheme.bodyLarge?.color),
            ),
            subtitle: Text(
              'Control visibility of your wardrobe from others',
              style: TextStyle(color: theme.textTheme.bodyMedium?.color),
            ),
            value: hideItems,
            onChanged: _toggleHideItems,
          ),
          const Divider(),
          SwitchListTile(
            secondary: Icon(Icons.visibility_off, color: theme.iconTheme.color),
            title: Text(
              'Hide My Outfits',
              style: TextStyle(color: theme.textTheme.bodyLarge?.color),
            ),
            subtitle: Text(
              'Control visibility of your outfits from others',
              style: TextStyle(color: theme.textTheme.bodyMedium?.color),
            ),
            value: hideOutfits,
            onChanged: _toggleHideOutfits,
          ),
          const Divider(),

          // Help & Support Section
          ListTile(
            leading: Icon(Icons.help_outline, color: theme.iconTheme.color),
            title: Text(
              'FAQ / Help Center',
              style: TextStyle(color: theme.textTheme.bodyLarge?.color),
            ),
            onTap:
                () => _showDialog(
                  context,
                  'FAQ / Help Center',
                  'Q: How do I add an outfit?\nA: Tap the + button and select items.\n\n'
                      'Q: Can I edit outfits?\nA: Not yet, but feature is coming soon.\n\n'
                      'Q: How do I delete an item?\nA: Go to the item details and tap Delete.\n\n'
                      'Q: How do I view other profiles?\nA: Tap usernames from posts or searches.\n\n'
                      'Q: What does "Hide My Items" do?\nA: It prevents your wardrobe items from being seen by others.\n\n'
                      'Q: How do I change the app theme?\nA: Use the Toggle Theme option in Settings.\n\n'
                      'Q: Can I share outfits?\nA: Yes, you can post them to the public feed.\n\n'
                      'Q: How do I report an issue?\nA: Use the Contact Support option in Settings.\n\n',
                ),
          ),
          ListTile(
            leading: Icon(Icons.support_agent, color: theme.iconTheme.color),
            title: Text(
              'Contact Support',
              style: TextStyle(color: theme.textTheme.bodyLarge?.color),
            ),
            onTap:
                () => _showDialog(
                  context,
                  'Contact Support',
                  'Need help?\n\nEmail: outfitly_support@gmail.com\nPhone: +90 501 343 6614',
                ),
          ),
          const Divider(),

          // About Section
          ListTile(
            leading: Icon(Icons.info_outline, color: theme.iconTheme.color),
            title: Text(
              'App Version',
              style: TextStyle(color: theme.textTheme.bodyLarge?.color),
            ),
            subtitle: Text(
              'v1.0.0',
              style: TextStyle(color: theme.textTheme.bodyMedium?.color),
            ),
          ),
          ListTile(
            leading: Icon(Icons.person, color: theme.iconTheme.color),
            title: Text(
              'Developer Info',
              style: TextStyle(color: theme.textTheme.bodyLarge?.color),
            ),
            subtitle: Text(
              'Built by Outfitly Team',
              style: TextStyle(color: theme.textTheme.bodyMedium?.color),
            ),
          ),
          ListTile(
            leading: Icon(Icons.policy, color: theme.iconTheme.color),
            title: Text(
              'Privacy Policy',
              style: TextStyle(color: theme.textTheme.bodyLarge?.color),
            ),
            onTap:
                () => _showDialog(
                  context,
                  'Privacy Policy',
                  'Outfitly values your privacy. We never share your personal information without your consent.\n\n'
                      'We collect only necessary data for app functionality and never sell your data.',
                ),
          ),
          ListTile(
            leading: Icon(
              Icons.description_outlined,
              color: theme.iconTheme.color,
            ),
            title: Text(
              'Terms of Service',
              style: TextStyle(color: theme.textTheme.bodyLarge?.color),
            ),
            onTap:
                () => _showDialog(
                  context,
                  'Terms of Service',
                  'By using Outfitly, you agree to our terms:\n\n'
                      '- You are responsible for the content you upload.\n'
                      '- Do not post offensive or illegal content.\n'
                      '- Respect other users and their privacy.\n'
                      '- We reserve the right to suspend accounts violating our policies.',
                ),
          ),
          const Divider(),

          // Sign Out
          ListTile(
            leading: Icon(Icons.logout, color: theme.colorScheme.error),
            title: Text(
              'Sign Out',
              style: TextStyle(color: theme.colorScheme.error),
            ),
            onTap: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}
