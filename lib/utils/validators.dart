class Validators {
  // Phone number validation
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter phone number';
    }

    // Remove any spaces, dashes, or brackets
    String phone = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Check if it contains only digits
    if (!RegExp(r'^[0-9]+$').hasMatch(phone)) {
      return 'Phone number should contain only digits';
    }

    // Check for valid length (10 digits for most countries, including India)
    if (phone.length < 10) {
      return 'Phone number must be at least 10 digits';
    }

    if (phone.length > 15) {
      return 'Phone number is too long';
    }

    // For India: Check if it starts with 6-9 (valid mobile number prefix)
    if (phone.length == 10) {
      if (!RegExp(r'^[6-9]').hasMatch(phone)) {
        return 'Invalid phone number format';
      }
    }

    return null;
  }

  // Format phone number for display
  static String formatPhoneNumber(String phone) {
    // Remove any non-digit characters
    String cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');

    // Format as XXX-XXX-XXXX for 10 digit numbers
    if (cleaned.length == 10) {
      return '${cleaned.substring(0, 3)}-${cleaned.substring(3, 6)}-${cleaned.substring(6)}';
    }

    return cleaned;
  }

  // Clean phone number (remove formatting)
  static String cleanPhoneNumber(String phone) {
    return phone.replaceAll(RegExp(r'[^0-9]'), '');
  }

  // Password validation with strength requirements
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter password';
    }

    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }

    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }

    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain at least one lowercase letter';
    }

    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    }

    return null;
  }

  // Password validation for login (less strict - just check not empty)
  static String? validatePasswordForLogin(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter password';
    }
    return null;
  }

  // Name validation
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter name';
    }

    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }

    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
      return 'Name should contain only letters';
    }

    return null;
  }

  // Wage validation
  static String? validateWage(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter wage';
    }

    if (double.tryParse(value) == null) {
      return 'Please enter a valid number';
    }

    if (double.parse(value) < 0) {
      return 'Wage cannot be negative';
    }

    return null;
  }

  // Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter email address';
    }

    // Basic email regex pattern
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }

    return null;
  }
}
