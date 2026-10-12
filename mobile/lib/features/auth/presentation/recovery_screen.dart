import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:verifai/core/theme/app_colors.dart';

class RecoveryScreen extends StatefulWidget {
  const RecoveryScreen({super.key, this.forgotEmail = false});
  final bool forgotEmail;
  @override
  State<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends State<RecoveryScreen> {
  final _email = TextEditingController();
  bool _busy = false;
  bool _sent = false;
  String? _error;
  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final forgotEmail = widget.forgotEmail;
    return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
            backgroundColor: AppColors.background,
            title: const Text('Account recovery')),
        body: SafeArea(
            child: ListView(padding: const EdgeInsets.all(24), children: [
          Container(
              width: 76,
              height: 76,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [AppColors.accentGreen, AppColors.accentCyan]),
                  borderRadius: BorderRadius.circular(24)),
              child: Icon(
                  forgotEmail
                      ? Icons.alternate_email_rounded
                      : Icons.lock_reset_rounded,
                  size: 36,
                  color: AppColors.primaryNavy)),
          const SizedBox(height: 22),
          Text(forgotEmail ? 'Forgot your email?' : 'Reset your password',
              style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryNavy)),
          const SizedBox(height: 10),
          Text(
              forgotEmail
                  ? 'For your privacy, VerifAI cannot reveal account email addresses here. Try the email accounts you may have registered with, check your inbox for earlier VerifAI messages, or contact your organisation’s support team.'
                  : 'Enter the email address associated with your account. If it is registered, Firebase will send a password-reset link.',
              style:
                  const TextStyle(height: 1.5, color: AppColors.textSecondary)),
          if (!forgotEmail) ...[
            const SizedBox(height: 24),
            TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                decoration: InputDecoration(
                    labelText: 'Email address',
                    hintText: 'you@example.com',
                    prefixIcon: const Icon(Icons.mail_outline_rounded),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.border)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            const BorderSide(color: AppColors.border)))),
            const SizedBox(height: 14),
            SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                    onPressed: (_busy || _sent) ? null : _sendReset,
                    icon: _busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.mark_email_read_outlined),
                    label:
                        Text(_sent ? 'Email request sent' : 'Send reset link'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryNavy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14))))),
            if (_sent)
              const Padding(
                  padding: EdgeInsets.only(top: 14),
                  child: Text(
                      'If the address is registered, a reset email should arrive shortly. Check spam or junk too.',
                      style: TextStyle(
                          color: AppColors.accentGreen, height: 1.4))),
            if (_error != null)
              Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(_error!,
                      style: const TextStyle(color: AppColors.error))),
          ],
          const SizedBox(height: 20),
          TextButton(
              onPressed: () => context.go('/login'),
              child: const Text('Back to sign in')),
        ])));
  }

  Future<void> _sendReset() async {
    final email = _email.text.trim();
    if (!email.contains('@')) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }
    setState(() => _busy = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) setState(() => _sent = true);
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _error = e.code == 'invalid-email'
            ? 'Enter a valid email address.'
            : 'We could not send the reset email right now. Check the address and try again.');
      }
    } catch (_) {
      if (mounted) {
        setState(() =>
            _error = 'We could not send the reset email. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
