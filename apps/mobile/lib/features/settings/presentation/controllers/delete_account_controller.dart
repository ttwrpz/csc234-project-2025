import 'package:core/core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/data/providers.dart';
import '../../../auth/domain/auth_credentials.dart';
import '../../../auth/domain/auth_failure.dart';
import '../../../auth/domain/usecases/delete_account.dart';

/// Sealed lifecycle states for the account-deletion flow. The Settings
/// screen listens to the [deleteAccountControllerProvider] and reacts:
/// `running` shows a blocking spinner overlay; `success` is observable
/// for tests (the router redirects on auth-state change); `errored`
/// triggers a SnackBar (network / unknown) or an inline error in the
/// password modal (wrongPassword).
sealed class DeleteAccountState {
  const DeleteAccountState();
}

/// Initial state. No deletion in flight.
class DeleteAccountIdle extends DeleteAccountState {
  const DeleteAccountIdle();
}

/// Reauth + CF call + signOut in flight. UI shows a blocking spinner.
class DeleteAccountRunning extends DeleteAccountState {
  const DeleteAccountRunning();
}

/// CF returned ok and signOut completed. The router will redirect to
/// `/sign-in` via the auth-state stream emitting `null`.
class DeleteAccountSuccess extends DeleteAccountState {
  const DeleteAccountSuccess();
}

/// Use case returned a failure. [reason] tells the UI which surface to
/// drive — inline error vs. SnackBar — without leaking AuthFailure
/// types into the presentation layer.
class DeleteAccountErrored extends DeleteAccountState {
  const DeleteAccountErrored(this.reason);
  final DeleteAccountErrorReason reason;
}

/// Coarse classification of `AuthFailure` for the UI. The screen maps
/// each to a different surface: [wrongPassword] keeps the password
/// modal open with an inline error; [network] and [unknown] pop a
/// SnackBar.
enum DeleteAccountErrorReason { wrongPassword, network, unknown }

/// Notifier that orchestrates account deletion. Holds the lifecycle
/// state above; the actual reauth credential collection (biometric vs.
/// password modal) happens in the Settings screen because it requires
/// `BuildContext` for `showDialog` / `Navigator`. The screen calls
/// [run] with whichever credential it built, and reacts to the
/// resulting state transitions.
///
/// The controller does NOT call signOut itself — that's owned by
/// [DeleteAccountUseCase], which composes reauth → CF → signOut.
class DeleteAccountController extends Notifier<DeleteAccountState> {
  DeleteAccountController({Logger logger = const Logger('settings.delete')})
    : _logger = logger;

  final Logger _logger;

  @override
  DeleteAccountState build() => const DeleteAccountIdle();

  /// Runs the full deletion sequence with the provided reauth credential.
  /// Returns the final state for callers that prefer await-ing over
  /// listening; the underlying notifier is updated either way so widget
  /// tests can assert on either surface.
  Future<DeleteAccountState> run({required AuthCredentials creds}) async {
    if (state is DeleteAccountRunning) return state;
    state = const DeleteAccountRunning();
    final useCase = ref.read(deleteAccountUseCaseProvider);
    final result = await useCase.call(reauth: creds);
    final next = switch (result) {
      Ok<void, AuthFailure>() => const DeleteAccountSuccess(),
      Err<void, AuthFailure>(failure: final f) => DeleteAccountErrored(
        _classify(f),
      ),
    };
    if (next is DeleteAccountErrored) {
      // Log the reason class only — never the underlying cause object,
      // which can carry PII (e.g. `AuthFailure.unknown(email-formatted)`).
      _logger.warn('deleteAccount errored reason=${next.reason.name}');
    }
    state = next;
    return next;
  }

  /// Returns the controller to its initial state. The password modal
  /// calls this when the user dismisses an inline-error so a
  /// subsequent retry doesn't see stale UI.
  void reset() {
    state = const DeleteAccountIdle();
  }

  static DeleteAccountErrorReason _classify(AuthFailure failure) {
    // AuthFailure's variant classes are file-private (`_WrongPassword`,
    // `_Network`, etc.) so we can't pattern-match them by type from
    // here. Compare runtimeType against known canonical const factories
    // — same identity, same Type instance.
    final type = failure.runtimeType;
    if (type == const AuthFailure.wrongPassword().runtimeType) {
      return DeleteAccountErrorReason.wrongPassword;
    }
    if (type == const AuthFailure.network().runtimeType) {
      return DeleteAccountErrorReason.network;
    }
    return DeleteAccountErrorReason.unknown;
  }
}

final deleteAccountControllerProvider =
    NotifierProvider<DeleteAccountController, DeleteAccountState>(
      DeleteAccountController.new,
    );
