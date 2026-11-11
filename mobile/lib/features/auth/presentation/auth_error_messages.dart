String humanizeAuthError(Object error) {
  final message = error.toString().toLowerCase();

  // Wrong credentials (email/password)
  if (message.contains('wrong-password') ||
      message.contains('user-not-found') ||
      message.contains('invalid-credential') ||
      message.contains('invalid login') ||
      message.contains('user not found') ||
      message.contains('invalid password')) {
    return 'The email or password is incorrect.';
  }

  // Registration
  if (message.contains('email-already-in-use') ||
      message.contains('already registered') ||
      message.contains('already in use')) {
    return 'An account with this email already exists.';
  }
  if (message.contains('weak-password')) {
    return 'Please choose a stronger password (at least 6 characters).';
  }
  if (message.contains('invalid-email')) {
    return 'Please enter a valid email address.';
  }
  if (message.contains('operation-not-allowed') &&
      !message.contains('google')) {
    return 'Email sign-in is not enabled for this project yet.';
  }
  if (message.contains('too-many-requests')) {
    return 'Too many attempts. Please wait a moment and try again.';
  }

  // Google sign-in
  if (message.contains('account-exists-with-different-credential')) {
    return 'An account with this email already exists. Sign in with your email and password first.';
  }
  if (message.contains('google sign-in is not configured') ||
      message.contains('no matching oauth client') ||
      message.contains('developer_error') ||
      message.contains('developer error')) {
    return 'Google sign-in is not available for this build. The APK signing certificate may not match Firebase — install the latest build or contact support.';
  }
  if (message.contains('google') && message.contains('operation-not-allowed')) {
    return 'Google sign-in is not enabled for this Firebase project.';
  }
  if (message.contains('cancelled')) {
    return 'Google sign-in was cancelled.';
  }

  // Connectivity / session
  if (message.contains('timeout') || message.contains('timed out')) {
    return 'VerifAI took too long to respond. Please try again in a moment.';
  }
  if (message.contains('network-request-failed') ||
      message.contains('network') ||
      message.contains('socket') ||
      message.contains('connection')) {
    return 'We could not connect to VerifAI. Check your connection and try again.';
  }
  if (message.contains('expired') || message.contains('invalid or expired')) {
    return 'Your session has expired. Please sign in again.';
  }

  return 'Sign-in could not be completed. Please try again.';
}
