import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:verifai/core/theme/app_spacing.dart';
import 'package:verifai/features/auth/providers.dart';
import 'auth_brand_header.dart';
import 'auth_error_messages.dart';
import 'package:verifai/shared/models.dart';
import 'package:verifai/shared/widgets.dart';

class _PasswordStrengthIndicator extends StatelessWidget {
  const _PasswordStrengthIndicator({
    required this.score,
    required this.label,
  });

  final int score;
  final String label;

  @override
  Widget build(BuildContext context) {
    const colors = [
      Colors.red,
      Colors.deepOrange,
      Colors.amber,
      Colors.lightGreen,
      Colors.green,
    ];
    final color = colors[score.clamp(0, 4).toInt()];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Password strength',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Row(
          children: List.generate(
            4,
            (index) => Expanded(
              child: Container(
                height: 5,
                margin: EdgeInsets.only(right: index == 3 ? 0 : 5),
                decoration: BoxDecoration(
                  color: score > index ? color : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Aim for 8+ characters, uppercase and lowercase letters, and a number or symbol.',
          style: TextStyle(
            fontSize: 11,
            height: 1.35,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}

enum _PendingAction { email, google }

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  /// Which button is currently submitting, so only it shows a spinner.
  _PendingAction? _pending;
  int _passwordStrength = 0;

  int _strengthFor(String value) {
    var score = 0;
    if (value.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(value) && RegExp(r'[a-z]').hasMatch(value)) {
      score++;
    }
    if (RegExp(r'\d').hasMatch(value)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(value)) score++;
    return score;
  }

  String get _strengthLabel =>
      const ['Very weak', 'Weak', 'Fair', 'Good', 'Strong'][_passwordStrength];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<AuthState>>(authNotifierProvider, (previous, next) {
      if (next.hasError && previous?.error != next.error) {
        final messenger = ScaffoldMessenger.of(context);
        messenger
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Text(humanizeAuthError(next.error!)),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'Dismiss',
                textColor: Colors.white,
                onPressed: messenger.hideCurrentSnackBar,
              ),
            ),
          );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create account'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.lg),
                const AuthBrandHeader(
                  title: 'Create your account',
                  subtitle: 'Build the skills employers trust.',
                ),
                const SizedBox(height: AppSpacing.xxl),
                VerifAIInput(
                  label: 'Full Name',
                  hint: 'Alex Mercer',
                  type: VerifAIInputType.name,
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your name';
                    }
                    if (value.trim().length < 2) {
                      return 'Name must be at least 2 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                VerifAIInput(
                  label: 'Email',
                  hint: 'you@example.com',
                  type: VerifAIInputType.email,
                  controller: _emailController,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                VerifAIInput(
                  label: 'Password',
                  hint: 'Create a password',
                  type: VerifAIInputType.password,
                  controller: _passwordController,
                  onChanged: (value) =>
                      setState(() => _passwordStrength = _strengthFor(value)),
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 8 ||
                        !RegExp(r'[A-Z]').hasMatch(value) ||
                        !RegExp(r'[a-z]').hasMatch(value) ||
                        (!RegExp(r'\d').hasMatch(value) &&
                            !RegExp(r'[^A-Za-z0-9]').hasMatch(value))) {
                      return 'Use 8+ characters with mixed case and a number or symbol';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                _PasswordStrengthIndicator(
                  score: _passwordStrength,
                  label: _strengthLabel,
                ),
                const SizedBox(height: AppSpacing.lg),
                VerifAIInput(
                  label: 'Confirm Password',
                  hint: 'Confirm your password',
                  type: VerifAIInputType.password,
                  controller: _confirmPasswordController,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleRegister(),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.xl),
                VerifAIButton(
                  label: 'Create account',
                  variant: VerifAIButtonVariant.primary,
                  isLoading: _pending == _PendingAction.email,
                  onPressed: _pending == null ? _handleRegister : null,
                  leadingIcon: Icons.bolt_rounded,
                ),
                const SizedBox(height: AppSpacing.lg),
                VerifAIButton(
                  label: 'Continue with Google',
                  variant: VerifAIButtonVariant.secondary,
                  isLoading: _pending == _PendingAction.google,
                  onPressed: _pending == null ? _handleGoogleSignIn : null,
                  leadingIcon: Icons.g_mobiledata,
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Sign In',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'By creating an account, you agree to our Terms of Service and Privacy Policy.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _pending = _PendingAction.email);
    try {
      await ref.read(authNotifierProvider.notifier).register(
            _emailController.text.trim(),
            _passwordController.text,
            _nameController.text.trim(),
          );
    } finally {
      if (mounted) setState(() => _pending = null);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _pending = _PendingAction.google);
    try {
      await ref.read(authNotifierProvider.notifier).signInWithGoogle();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(humanizeAuthError(e)),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _pending = null);
    }
  }
}
