class Validators {
  static String? required(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    // Rwanda phone number format: +250 7XX XXX XXX
    final phoneRegex = RegExp(r'^(\+250|0)7[0-9]{8}$');
    if (!phoneRegex.hasMatch(value.replaceAll(' ', ''))) {
      return 'Please enter a valid Rwanda phone number';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  static String? idNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'ID number is required';
    }
    // Rwanda national ID is 16 digits
    if (!RegExp(r'^\d{16}$').hasMatch(value)) {
      return 'ID number must be 16 digits';
    }
    return null;
  }

  static String? licenseNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'License number is required';
    }
    if (value.length < 5) {
      return 'License number must be at least 5 characters';
    }
    return null;
  }

  static String? employeeId(String? value) {
    if (value == null || value.isEmpty) {
      return 'Employee ID is required';
    }
    return null;
  }

  static String? minLength(String? value, int minLength, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    if (value.length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }
    return null;
  }

  static String? maxLength(String? value, int maxLength, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    if (value.length > maxLength) {
      return '$fieldName must not exceed $maxLength characters';
    }
    return null;
  }

  static String? number(String? value, {bool required = true}) {
    if (value == null || value.isEmpty) {
      return required ? 'This field is required' : null;
    }
    if (!RegExp(r'^\d+$').hasMatch(value)) {
      return 'Please enter a valid number';
    }
    return null;
  }

  static String? positiveNumber(String? value, {bool required = true}) {
    if (value == null || value.isEmpty) {
      return required ? 'This field is required' : null;
    }
    final number = int.tryParse(value);
    if (number == null) {
      return 'Please enter a valid number';
    }
    if (number < 0) {
      return 'Number must be positive';
    }
    return null;
  }
}