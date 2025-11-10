class EnhancedValidators {
  // Vietnamese name validation with enhanced security
  static bool isValidVietnameseName(String? name) {
    if (name == null || name.trim().isEmpty) return false;

    // Remove extra spaces and normalize
    final normalized = name.trim().replaceAll(RegExp(r'\s+'), ' ');

    // Check length
    if (normalized.length < 2 || normalized.length > 50) return false;

    // Check for valid Vietnamese characters only
    final vietnameseNameRegex = RegExp(r'^[a-zA-ZÀ-ỹ\s]+$');
    if (!vietnameseNameRegex.hasMatch(normalized)) return false;

    // Prevent names with only spaces or single characters
    if (normalized.split(' ').any((part) => part.isEmpty)) return false;

    // Prevent common injection patterns
    final dangerousPatterns = [
      RegExp(r'<[^>]*>'), // HTML tags
      RegExp(r'javascript:', caseSensitive: false),
      RegExp(r'on\w+\s*=', caseSensitive: false), // Event handlers
      RegExp(r'(union|select|insert|update|delete|drop)\s',
          caseSensitive: false), // SQL
    ];

    for (final pattern in dangerousPatterns) {
      if (pattern.hasMatch(normalized)) return false;
    }

    return true;
  }

  // Enhanced username validation
  static bool isValidUsername(String? username) {
    if (username == null || username.trim().isEmpty) return false;

    final trimmed = username.trim().toLowerCase();

    // Length check
    if (trimmed.length < 3 || trimmed.length > 30) return false;

    // Format check
    final usernameRegex = RegExp(r'^[a-z0-9_]+$');
    if (!usernameRegex.hasMatch(trimmed)) return false;

    // Prevent reserved usernames
    final reservedUsernames = [
      'admin',
      'administrator',
      'root',
      'system',
      'null',
      'undefined',
      'test',
      'demo',
      'guest',
      'anonymous',
      'user',
      'student',
      'instructor'
    ];

    if (reservedUsernames.contains(trimmed)) return false;

    // Prevent usernames that look like system accounts
    if (trimmed.startsWith('sys') || trimmed.startsWith('adm')) return false;

    return true;
  }

  // Enhanced email validation
  static bool isValidEmail(String? email) {
    if (email == null || email.trim().isEmpty) return false;

    final trimmed = email.trim().toLowerCase();

    // Basic email regex
    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(trimmed)) return false;

    // Additional security checks
    if (trimmed.length > 255) return false;

    // Prevent dangerous characters
    final dangerousChars = ['<', '>', '"', "'", '&', ';'];
    for (final char in dangerousChars) {
      if (trimmed.contains(char)) return false;
    }

    return true;
  }

  // Password strength validation
  static ValidationResult validatePasswordStrength(String? password) {
    if (password == null || password.isEmpty) {
      return ValidationResult(false, 'Password is required');
    }

    if (password.length < 6) {
      return ValidationResult(false, 'Password must be at least 6 characters');
    }

    if (password.length > 50) {
      return ValidationResult(false, 'Password cannot exceed 50 characters');
    }

    // Calculate strength score
    int score = 0;
    if (password.length >= 8) score++;
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score++;

    String strengthMessage = '';
    if (score < 2) {
      strengthMessage =
          'Weak password. Consider adding numbers or special characters.';
    } else if (score < 4) {
      strengthMessage = 'Good password strength.';
    } else {
      strengthMessage = 'Strong password.';
    }

    return ValidationResult(true, strengthMessage, score: score);
  }

  // Validate form field with custom message
  static String? validateField(
    String? value, {
    required String fieldName,
    bool required = true,
    int? minLength,
    int? maxLength,
    bool Function(String)? customValidator,
    String? customMessage,
  }) {
    if (required && (value == null || value.trim().isEmpty)) {
      return '$fieldName is required';
    }

    if (value != null && value.trim().isNotEmpty) {
      final trimmed = value.trim();

      if (minLength != null && trimmed.length < minLength) {
        return '$fieldName must be at least $minLength characters';
      }

      if (maxLength != null && trimmed.length > maxLength) {
        return '$fieldName cannot exceed $maxLength characters';
      }

      if (customValidator != null && !customValidator(trimmed)) {
        return customMessage ?? '$fieldName is invalid';
      }
    }

    return null;
  }

  // Vietnamese full name validator for forms
  static String? validateVietnameseName(String? value) {
    return validateField(
      value,
      fieldName: 'Full name',
      required: true,
      minLength: 2,
      maxLength: 50,
      customValidator: isValidVietnameseName,
      customMessage: 'Full name can only contain Vietnamese letters and spaces',
    );
  }

  // Username validator for forms
  static String? validateUsername(String? value) {
    return validateField(
      value,
      fieldName: 'Username',
      required: true,
      minLength: 3,
      maxLength: 30,
      customValidator: isValidUsername,
      customMessage:
          'Username can only contain letters, numbers, and underscores',
    );
  }

  // Email validator for forms
  static String? validateEmail(String? value) {
    return validateField(
      value,
      fieldName: 'Email',
      required: true,
      maxLength: 255,
      customValidator: isValidEmail,
      customMessage: 'Please enter a valid email address',
    );
  }

  // Password validator for forms
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    final result = validatePasswordStrength(value);
    return result.isValid ? null : result.message;
  }

  // Confirm password validator
  static String? validateConfirmPassword(
      String? value, String? originalPassword) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }

    if (value != originalPassword) {
      return 'Passwords do not match';
    }

    return null;
  }

  // Generic required field validator
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  // Sanitize input to prevent XSS
  static String sanitizeInput(String input) {
    return input
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;')
        .replaceAll('&', '&amp;');
  }

  // Generate username suggestion from full name
  static String generateUsernameSuggestion(String fullName) {
    if (fullName.isEmpty) return '';

    // Convert to lowercase and remove accents
    String username = fullName
        .toLowerCase()
        .replaceAll(RegExp(r'[àáạảãâầấậẩẫăằắặẳẵ]'), 'a')
        .replaceAll(RegExp(r'[èéẹẻẽêềếệểễ]'), 'e')
        .replaceAll(RegExp(r'[ìíịỉĩ]'), 'i')
        .replaceAll(RegExp(r'[òóọỏõôồốộổỗơờớợởỡ]'), 'o')
        .replaceAll(RegExp(r'[ùúụủũưừứựửữ]'), 'u')
        .replaceAll(RegExp(r'[ỳýỵỷỹ]'), 'y')
        .replaceAll(RegExp(r'[đ]'), 'd')
        .replaceAll(RegExp(r'[^a-z0-9]'), '');

    return username;
  }
}

class ValidationResult {
  final bool isValid;
  final String message;
  final int score;

  ValidationResult(this.isValid, this.message, {this.score = 0});
}
