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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2F1B0C),
            ),
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
        title: const Text("Settings"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: const Color(0xFFFF9800), // thin orange line
            height: 1,
          ),
        ),
      ),

      body: Container(
        color: Colors.grey.shade100,
        child: ListView(
          padding: const EdgeInsets.only(top: 12, bottom: 24),
          children: [
            _buildSectionHeader('Preferences'),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.brightness_6),
                    title: const Text('Toggle Theme'),
                    subtitle: const Text('Switch between light and dark mode'),
                    onTap: widget.onThemeChange,
                  ),
                  SwitchListTile(
                    secondary: const Icon(Icons.lock_outline),
                    title: const Text('Hide My Items'),
                    subtitle: const Text(
                      'Control visibility of your wardrobe from others',
                    ),
                    value: hideItems,
                    onChanged: _toggleHideItems,
                  ),
                  SwitchListTile(
                    secondary: const Icon(Icons.visibility_off),
                    title: const Text('Hide My Outfits'),
                    subtitle: const Text(
                      'Control visibility of your outfits from others',
                    ),
                    value: hideOutfits,
                    onChanged: _toggleHideOutfits,
                  ),
                ],
              ),
            ),

            _buildSectionHeader('Support'),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.help_outline),
                    title: const Text('FAQ / Help Center'),
                    onTap:
                        () => _showDialog(
                          context,
                          'FAQ / Help Center',
                          'Q: How do I add an outfit?\nA: Tap the + button and select items.\n\nQ: Can I edit outfits?\nA: Not yet, but feature is coming soon.\n\nQ: How do I delete an item?\nA: Go to the item details and tap Delete.\n\nQ: What does "Hide My Items" do?\nA: It prevents your wardrobe items from being seen by others.\n\nQ: Can I share outfits?\nA: Yes, you can post them to the public feed.',
                        ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.support_agent),
                    title: const Text('Contact Support'),
                    onTap:
                        () => _showDialog(
                          context,
                          'Contact Support',
                          'Need help?\n\nEmail: outfitly_support@gmail.com\nPhone: +90 501 343 6614',
                        ),
                  ),
                ],
              ),
            ),

            _buildSectionHeader('About'),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('App Version'),
                    subtitle: const Text('v1.0.0'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text('Developer Info'),
                    subtitle: const Text('Built by Outfitly Team'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.policy),
                    title: const Text('Privacy Policy'),
                    onTap:
                        () => _showDialog(
                          context,
                          'Privacy Policy',
                          'Outfitly values your privacy. We never share your personal information without your consent.',
                        ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: const Text('Terms of Service'),
                    onTap:
                        () => _showDialog(
                          context,
                          'Terms of Service',
                          'By using Outfitly, you agree to our terms. Do not post offensive or illegal content.',
                        ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                    (route) => false,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
