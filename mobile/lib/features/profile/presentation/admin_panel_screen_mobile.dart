import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:verifai/core/theme/app_typography.dart';

/// Mobile (Android/iOS): the admin dashboard opens in an in-app browser view.
/// The dashboard keeps its own Firebase sign-in — the same login the app uses —
/// so a one-time sign-in on this page is expected.
///
/// On web and desktop the barrel resolves to admin_panel_screen_web.dart
/// instead, which opens the dashboard in the default browser.
class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key, required this.panelUrl});

  /// The dashboard URL, derived from the app's configured API base URL
  /// (.../api/ becomes .../admin/).
  final String panelUrl;

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) {
          if (mounted) setState(() => _loading = false);
        },
      ))
      ..loadRequest(Uri.parse(widget.panelUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Admin Panel',
          style: AppTypography.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Reload',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _loading = true);
              _controller.reload();
            },
          ),
        ],
      ),
      body: Stack(children: [
        WebViewWidget(controller: _controller),
        if (_loading) const Center(child: CircularProgressIndicator()),
      ]),
    );
  }
}
