import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../../../core/storage/hive_helper.dart';

enum AuthStatus { initial, authenticating, authenticated, guest, unauthenticated }

class AuthState {
  final AuthStatus status;
  final String? email;
  final String? displayName;
  final String? errorMessage;

  AuthState({
    required this.status,
    this.email,
    this.displayName,
    this.errorMessage,
  });

  factory AuthState.initial() => AuthState(status: AuthStatus.initial);

  AuthState copyWith({
    AuthStatus? status,
    String? email,
    String? displayName,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState.initial()) {
    checkAutoLogin();
  }

  void checkAutoLogin() {
    try {
      final box = Hive.box(HiveHelper.settingsBox);
      final isLoggedIn = box.get('is_logged_in', defaultValue: false) as bool;
      final isGuest = box.get('is_guest_mode', defaultValue: false) as bool;
      final userName = box.get('user_name', defaultValue: 'Mathan') as String;
      final userEmail = box.get('user_email', defaultValue: '') as String;

      if (isLoggedIn) {
        state = AuthState(
          status: AuthStatus.authenticated,
          email: userEmail,
          displayName: userName,
        );
      } else if (isGuest) {
        state = AuthState(
          status: AuthStatus.guest,
          displayName: userName,
        );
      } else {
        state = AuthState(status: AuthStatus.unauthenticated);
      }
    } catch (_) {
      state = AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<bool> loginWithEmail(String email, String password) async {
    state = state.copyWith(status: AuthStatus.authenticating);
    await Future.delayed(const Duration(seconds: 1)); // Premium transition feel
    
    if (email.contains('@') && password.length >= 6) {
      final box = Hive.box(HiveHelper.settingsBox);
      await box.put('is_logged_in', true);
      await box.put('is_guest_mode', false);
      await box.put('user_email', email);
      
      final displayName = email.split('@').first;
      await box.put('user_name', displayName[0].toUpperCase() + displayName.substring(1));

      state = AuthState(
        status: AuthStatus.authenticated,
        email: email,
        displayName: box.get('user_name'),
      );
      return true;
    } else {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Invalid email or password (min 6 characters)',
      );
      return false;
    }
  }

  Future<bool> signupWithEmail(String email, String password, String name) async {
    state = state.copyWith(status: AuthStatus.authenticating);
    await Future.delayed(const Duration(seconds: 1));

    if (email.contains('@') && password.length >= 6 && name.isNotEmpty) {
      final box = Hive.box(HiveHelper.settingsBox);
      await box.put('is_logged_in', true);
      await box.put('is_guest_mode', false);
      await box.put('user_email', email);
      await box.put('user_name', name);

      state = AuthState(
        status: AuthStatus.authenticated,
        email: email,
        displayName: name,
      );
      return true;
    } else {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Invalid registration details',
      );
      return false;
    }
  }

  Future<void> loginWithGoogle() async {
    state = state.copyWith(status: AuthStatus.authenticating);
    await Future.delayed(const Duration(seconds: 1));

    final box = Hive.box(HiveHelper.settingsBox);
    await box.put('is_logged_in', true);
    await box.put('is_guest_mode', false);
    await box.put('user_email', 'mathan.google@gmail.com');
    await box.put('user_name', 'Mathan');

    state = AuthState(
      status: AuthStatus.authenticated,
      email: 'mathan.google@gmail.com',
      displayName: 'Mathan',
    );
  }

  Future<void> loginAsGuest() async {
    state = state.copyWith(status: AuthStatus.authenticating);
    await Future.delayed(const Duration(milliseconds: 600));

    final box = Hive.box(HiveHelper.settingsBox);
    await box.put('is_logged_in', false);
    await box.put('is_guest_mode', true);
    await box.put('user_name', 'Guest User');

    state = AuthState(
      status: AuthStatus.guest,
      displayName: 'Guest User',
    );
  }

  Future<void> logout() async {
    final box = Hive.box(HiveHelper.settingsBox);
    await box.put('is_logged_in', false);
    await box.put('is_guest_mode', false);
    state = AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> deleteAccount() async {
    final box = Hive.box(HiveHelper.settingsBox);
    await box.clear();
    state = AuthState(status: AuthStatus.unauthenticated);
  }
}
