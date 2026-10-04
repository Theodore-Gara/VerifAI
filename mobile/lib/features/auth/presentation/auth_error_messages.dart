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
  if (message.contains('operation-not-allowed')) {
    return 'Email sign-in is not enabled for this project yet.';
  }
  if (message.contains('too-many-requests')) {
    return 'Too many attempts. Please wait a moment and try again.';
  }

  // Google sign-in
  if (message.contains('developer_error') ||
      message.contains('developer error')) {
    return 'Google sign-in is not available for this build.';
  }
  if (message.contains('cancelled')) {
    return 'Google sign-in was cancelled.';
  }

  // Connectivity / session
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
