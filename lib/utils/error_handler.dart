import 'package:flutter/material.dart';

/// Centralized mapping of Firebase error codes to user-friendly messages.
class ErrorHandler {
  /// Returns a user-friendly message for a Firebase Auth error code.
  static String getFirebaseAuthMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email address.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait and try again.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';
      case 'sign-in-cancelled':
        return 'Sign-in was cancelled.';
      case 'requires-recent-login':
        return 'Please sign in again to complete this action.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled.';
      default:
        return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Returns a user-friendly message for a Firebase Storage error code.
  static String getStorageMessage(String code) {
    switch (code) {
      case 'object-not-found':
        return 'File not found.';
      case 'unauthorized':
        return 'You do not have permission to access this file.';
      case 'cancelled':
        return 'Upload was cancelled.';
      case 'unknown':
        return 'An error occurred while uploading. Please try again.';
      case 'retry-limit-exceeded':
        return 'Upload failed after multiple attempts. Please try again.';
      case 'quota-exceeded':
        return 'Storage quota exceeded. Please contact support.';
      default:
        return 'Storage error. Please try again.';
    }
  }

  /// Returns a user-friendly message for a Firestore error code.
  static String getFirestoreMessage(String code) {
    switch (code) {
      case 'permission-denied':
        return 'You do not have permission to perform this action.';
      case 'not-found':
        return 'The requested data was not found.';
      case 'unavailable':
        return 'Service is temporarily unavailable. Please try again.';
      case 'deadline-exceeded':
        return 'The operation took too long. Please try again.';
      default:
        return 'A database error occurred. Please try again.';
    }
  }

  /// Shows a red error snackbar with a warning icon. Duration: 5 seconds.
  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// Shows a green success snackbar with a checkmark icon. Duration: 3 seconds.
  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF4A7C59),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
