import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_model.dart';
import '../services/firebase_auth_service.dart';

/// Provider for FirebaseAuthService
final firebaseAuthServiceProvider = Provider<FirebaseAuthService>((ref) {
  return FirebaseAuthService();
});

/// Stream of current Firebase User
final authStateStreamProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(firebaseAuthServiceProvider);
  return authService.authStateChanges;
});

/// Async value for current UserModel fetched from Firestore
final currentUserModelProvider = FutureProvider<UserModel?>((ref) async {
  final authState = ref.watch(authStateStreamProvider);
  final user = authState.asData?.value;

  if (user == null) {
    return null;
  }

  final authService = ref.watch(firebaseAuthServiceProvider);
  return await authService.getUserProfile(user.uid);
});

/// State for Auth Actions (e.g. Login)
class AuthControllerState {
  final bool isLoading;
  final String? errorMessage;

  const AuthControllerState({
    this.isLoading = false,
    this.errorMessage,
  });

  AuthControllerState copyWith({
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthControllerState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// Controller for performing login & logout actions
class AuthController extends StateNotifier<AuthControllerState> {
  final FirebaseAuthService _authService;

  AuthController(this._authService) : super(const AuthControllerState());

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      state = state.copyWith(isLoading: false);
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message ?? 'Authentication failed.',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'An unexpected error occurred: $e',
      );
      return false;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    await _authService.signOut();
    state = const AuthControllerState();
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthControllerState>((ref) {
  final authService = ref.watch(firebaseAuthServiceProvider);
  return AuthController(authService);
});
