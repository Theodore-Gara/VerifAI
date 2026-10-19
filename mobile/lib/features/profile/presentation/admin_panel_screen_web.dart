import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Web and desktop: the admin dashboard opens in the default browser tab
/// (in-app webviews are not supported there). Same URL derivation as mobile.
class AdminPanelScreen extends StatelessWidget {
  const AdminPanelScreen({super.key, required this.panelUrl});

  final String panelUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Panel')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('The admin dashboard opens in your browser.'),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => launchUrl(Uri.parse(panelUrl),
                  mode: LaunchMode.externalApplication),
              icon: const Icon(Icons.admin_panel_settings),
              label: const Text('Open Admin Panel'),
            ),
          ],
        ),
      ),
    );
  }
}
