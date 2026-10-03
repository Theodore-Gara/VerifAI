String humanizeAuthError(Object error) {
  final message = error.toString().toLowerCase();

  if (message.contains('user not found') ||
      message.contains('invalid password')) {
    return 'The email or password is incorrect.';
  }
  if (message.contains('already registered') ||
      message.contains('email-already-in-use')) {
    return 'An account with this email already exists.';
  }
  if (message.contains('developer_error') ||
      message.contains('developer error')) {
    return 'Google sign-in is not available for this build.';
  }
  if (message.contains('cancelled')) {
    return 'Google sign-in was cancelled.';
  }
  if (message.contains('network') ||
      message.contains('socket') ||
      message.contains('connection')) {
    return 'We could not connect to VerifAI. Check your connection and try again.';
  }
  if (message.contains('expired') || message.contains('invalid or expired')) {
    return 'Your session has expired. Please sign in again.';
  }
  return 'Sign-in could not be completed. Please try again.';
}
