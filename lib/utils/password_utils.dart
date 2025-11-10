import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Utility class for password hashing and verification.
///
/// Uses SHA-256 hashing algorithm for password security.
/// Note: For production, consider using bcrypt or Argon2 for better security.
class PasswordUtils {
  /// Hashes a plain text password using SHA-256.
  ///
  /// [password] - The plain text password to hash.
  /// Returns the hashed password as a hexadecimal string.
  static String hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verifies if a plain text password matches a hashed password.
  ///
  /// [plainPassword] - The plain text password to verify.
  /// [hashedPassword] - The stored hashed password to compare against.
  /// Returns true if passwords match, false otherwise.
  static bool verifyPassword(String plainPassword, String hashedPassword) {
    final hashedInput = hashPassword(plainPassword);
    return hashedInput == hashedPassword;
  }

  /// Checks if a password string is already hashed.
  ///
  /// SHA-256 hashes are always 64 characters long hexadecimal strings.
  /// [password] - The password string to check.
  /// Returns true if the string appears to be a hash, false otherwise.
  static bool isHashed(String password) {
    // SHA-256 produces 64 character hex strings
    return password.length == 64 &&
        RegExp(r'^[a-f0-9]{64}$', caseSensitive: false).hasMatch(password);
  }
}
