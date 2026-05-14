import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/admin_model.dart';
import '../providers/auth_providers.dart';
import '../../../../core/error/failures.dart';

/// State for the auth notifier
class AuthNotifierState {
  final bool isLoading;
  final String? errorMessage;
  final AdminModel? admin;

  const AuthNotifierState({
    this.isLoading = false,
    this.errorMessage,
    this.admin,
  });

  AuthNotifierState copyWith({
    bool? isLoading,
    String? errorMessage,
    AdminModel? admin,
    bool clearError = false,
    bool clearAdmin = false,
  }) {
    return AuthNotifierState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      admin: clearAdmin ? null : (admin ?? this.admin),
    );
  }
}

/// Notifier for login/logout actions
class AuthNotifier extends StateNotifier<AuthNotifierState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AuthNotifierState());

  Future<bool> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.signIn(email, password);

    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
      (admin) {
        state = state.copyWith(isLoading: false, admin: admin);
        return true;
      },
    );
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    await _repository.signOut();
    state = const AuthNotifierState();
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthNotifierState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});
