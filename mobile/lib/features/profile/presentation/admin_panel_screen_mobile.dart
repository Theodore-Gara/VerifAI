import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:verifai/core/theme/app_typography.dart';

/// Mobile (Android/iOS): the admin dashboard opens in an in-app browser view.
/// The panel needs no sign-in of its own — the app hands its Firebase session
/// token to the page (via the URL fragment and a postMessage after load), and
/// refreshes it before it expires, so staff go straight in with the
/// credentials they already have.
///
/// On web and desktop the barrel resolves to admin_panel_screen_web.dart
/// instead, which opens the dashboard in the default browser (the token is
/// carried in the URL fragment there).
class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key, required this.panelUrl, this.tokenProvider});

  /// The dashboard URL, derived from the app's configured API base URL
  /// (.../api/ becomes .../admin/), already carrying the session token in its
  /// #fragment.
  final String panelUrl;

  /// Returns a fresh Firebase session token so the panel can be re-fed before
  /// the original expires. Optional: without it the initial token is simply
  /// re-posted, which still covers sessions shorter than an hour.
  final Future<String?> Function()? tokenProvider;

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  Timer? _renewalTimer;
  String? _lastToken;

  @override
  void initState() {
    super.initState();
    _lastToken = _tokenFromFragment(widget.panelUrl);
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) {
          if (mounted) setState(() => _loading = false);
          _postToken();
          // Firebase ID tokens last about an hour; hand a fresh one over
          // every 40 minutes so a long admin session never drops mid-work.
          _renewalTimer?.cancel();
          _renewalTimer = Timer.periodic(
              const Duration(minutes: 40), (_) => _renewToken());
        },
      ))
      ..loadRequest(Uri.parse(widget.panelUrl));
  }

  String? _tokenFromFragment(String url) {
    final match = RegExp(r'[#&]token=([^&#]+)').firstMatch(url);
    return match != null ? Uri.decodeComponent(match.group(1)!) : null;
  }

  Future<void> _renewToken() async {
    final provider = widget.tokenProvider;
    if (provider != null) {
      try {
        final fresh = await provider();
        if (fresh != null && fresh.isNotEmpty) _lastToken = fresh;
      } catch (_) {
        // Keep the previous token; the panel tolerates a failed renewal.
      }
    }
    await _postToken();
  }

  /// Dispatches the session token into the page as a synthetic message event —
  /// exactly what the panel's own handover listener expects.
  Future<void> _postToken() async {
    final token = _lastToken;
    if (token == null) return;
    final safeToken = token.replaceAll(r'\', r'\\').replaceAll("'", r"\'");
    try {
      await _controller.runJavaScript(
          'window.dispatchEvent(new MessageEvent("message", {data: '
          '{type: "verifai-admin-token", token: \'$safeToken\'}}));');
    } catch (_) {
      // The page may not be ready yet; the next renewal attempt covers it.
    }
  }

  @override
  void dispose() {
    _renewalTimer?.cancel();
    super.dispose();
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