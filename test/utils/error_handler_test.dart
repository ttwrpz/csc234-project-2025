// Tests for: ErrorHandler utility
// Features covered: Firebase auth error mapping, storage error mapping,
//   Firestore error mapping, user-friendly error messages
import 'package:flutter_test/flutter_test.dart';
import 'package:user_centric_mobile_app/utils/error_handler.dart';

void main() {
  group('ErrorHandler - Firebase Auth Messages', () {
    test('user-not-found returns correct message', () {
      expect(
        ErrorHandler.getFirebaseAuthMessage('user-not-found'),
        'No account found with this email address.',
      );
    });

    test('wrong-password returns correct message', () {
      expect(
        ErrorHandler.getFirebaseAuthMessage('wrong-password'),
        'Incorrect email or password. Please try again.',
      );
    });

    test('invalid-credential returns correct message', () {
      expect(
        ErrorHandler.getFirebaseAuthMessage('invalid-credential'),
        'Incorrect email or password. Please try again.',
      );
    });

    test('email-already-in-use returns correct message', () {
      expect(
        ErrorHandler.getFirebaseAuthMessage('email-already-in-use'),
        'An account already exists with this email.',
      );
    });

    test('weak-password returns correct message', () {
      expect(
        ErrorHandler.getFirebaseAuthMessage('weak-password'),
        'Password is too weak. Use at least 6 characters.',
      );
    });

    test('invalid-email returns correct message', () {
      expect(
        ErrorHandler.getFirebaseAuthMessage('invalid-email'),
        'Please enter a valid email address.',
      );
    });

    test('too-many-requests returns correct message', () {
      expect(
        ErrorHandler.getFirebaseAuthMessage('too-many-requests'),
        'Too many attempts. Please wait and try again.',
      );
    });

    test('network-request-failed returns correct message', () {
      expect(
        ErrorHandler.getFirebaseAuthMessage('network-request-failed'),
        'No internet connection. Please check your network.',
      );
    });

    test('sign-in-cancelled returns correct message', () {
      expect(
        ErrorHandler.getFirebaseAuthMessage('sign-in-cancelled'),
        'Sign-in was cancelled.',
      );
    });

    test('requires-recent-login returns correct message', () {
      expect(
        ErrorHandler.getFirebaseAuthMessage('requires-recent-login'),
        'Please sign in again to complete this action.',
      );
    });

    test('user-disabled returns correct message', () {
      expect(
        ErrorHandler.getFirebaseAuthMessage('user-disabled'),
        'This account has been disabled.',
      );
    });

    test('operation-not-allowed returns correct message', () {
      expect(
        ErrorHandler.getFirebaseAuthMessage('operation-not-allowed'),
        'This sign-in method is not enabled.',
      );
    });

    test('unknown code returns generic message', () {
      expect(
        ErrorHandler.getFirebaseAuthMessage('unknown-error-code'),
        'An unexpected error occurred. Please try again.',
      );
    });

    test('empty code returns generic message', () {
      expect(
        ErrorHandler.getFirebaseAuthMessage(''),
        'An unexpected error occurred. Please try again.',
      );
    });
  });

  group('ErrorHandler - Storage Messages', () {
    test('object-not-found returns correct message', () {
      expect(
        ErrorHandler.getStorageMessage('object-not-found'),
        'File not found.',
      );
    });

    test('unauthorized returns correct message', () {
      expect(
        ErrorHandler.getStorageMessage('unauthorized'),
        'You do not have permission to access this file.',
      );
    });

    test('cancelled returns correct message', () {
      expect(
        ErrorHandler.getStorageMessage('cancelled'),
        'Upload was cancelled.',
      );
    });

    test('unknown returns correct message', () {
      expect(
        ErrorHandler.getStorageMessage('unknown'),
        'An error occurred while uploading. Please try again.',
      );
    });

    test('retry-limit-exceeded returns correct message', () {
      expect(
        ErrorHandler.getStorageMessage('retry-limit-exceeded'),
        'Upload failed after multiple attempts. Please try again.',
      );
    });

    test('quota-exceeded returns correct message', () {
      expect(
        ErrorHandler.getStorageMessage('quota-exceeded'),
        'Storage quota exceeded. Please contact support.',
      );
    });

    test('unknown code returns generic message', () {
      expect(
        ErrorHandler.getStorageMessage('some-random-error'),
        'Storage error. Please try again.',
      );
    });
  });

  group('ErrorHandler - Firestore Messages', () {
    test('permission-denied returns correct message', () {
      expect(
        ErrorHandler.getFirestoreMessage('permission-denied'),
        'You do not have permission to perform this action.',
      );
    });

    test('not-found returns correct message', () {
      expect(
        ErrorHandler.getFirestoreMessage('not-found'),
        'The requested data was not found.',
      );
    });

    test('unavailable returns correct message', () {
      expect(
        ErrorHandler.getFirestoreMessage('unavailable'),
        'Service is temporarily unavailable. Please try again.',
      );
    });

    test('deadline-exceeded returns correct message', () {
      expect(
        ErrorHandler.getFirestoreMessage('deadline-exceeded'),
        'The operation took too long. Please try again.',
      );
    });

    test('unknown code returns generic message', () {
      expect(
        ErrorHandler.getFirestoreMessage('random-code'),
        'A database error occurred. Please try again.',
      );
    });
  });
}
