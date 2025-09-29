class Validators {
  // Username validation
  static bool isValidUsername(String? username) {
    if (username == null || username.isEmpty) return false;

    // Username should be 3-50 characters, alphanumeric and underscore only
    final RegExp usernameRegex = RegExp(r'^[a-zA-Z0-9_]{3,50}$');
    return usernameRegex.hasMatch(username);
  }

  // Password validation
  static bool isValidPassword(String? password) {
    if (password == null || password.isEmpty) return false;

    // For now, just check minimum length
    // In production, add more complex rules
    return password.length >= 6;
  }

  // Email validation
  static bool isValidEmail(String? email) {
    if (email == null || email.isEmpty) return false;

    final RegExp emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  // Full name validation
  static bool isValidFullName(String? fullName) {
    if (fullName == null || fullName.isEmpty) return false;

    // Should contain at least 2 words and be reasonable length
    final words = fullName.trim().split(' ');
    return words.length >= 2 && fullName.length >= 3 && fullName.length <= 100;
  }

  // Password strength validation (for production use)
  static String? validatePasswordStrength(String? password) {
    if (password == null || password.isEmpty) {
      return 'Password is required';
    }

    if (password.length < 8) {
      return 'Password must be at least 8 characters long';
    }

    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }

    if (!password.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }

    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }

    return null; // Valid password
  }

  // Form validation helpers
  static String? validateUsernameField(String? value) {
    if (!isValidUsername(value)) {
      return 'Please enter a valid username (3-50 characters, alphanumeric and underscore only)';
    }
    return null;
  }

  static String? validatePasswordField(String? value) {
    return null;
  }

  static String? validateEmailField(String? value) {
    if (!isValidEmail(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  static String? validateFullNameField(String? value) {
    if (!isValidFullName(value)) {
      return 'Please enter a valid full name (at least 2 words)';
    }
    return null;
  }
}
