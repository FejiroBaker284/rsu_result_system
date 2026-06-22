import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/services/auth_service.dart';
import '../models/profile_model.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final currentProfileProvider = FutureProvider<ProfileModel?>((ref) async {
  ref.watch(authStateProvider);
  return ref.watch(authServiceProvider).getCurrentProfile();
});

class AuthNotifier extends StateNotifier<AsyncValue<ProfileModel?>> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    try {
      final profile = await _authService.getCurrentProfile();
      state = AsyncValue.data(profile);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<String?> signIn(String email, String password) async {
    try {
      state = const AsyncValue.loading();
      await _authService.signIn(email: email, password: password);
      final profile = await _authService.getCurrentProfile();
      state = AsyncValue.data(profile);
      return null;
    } catch (e) {
      state = const AsyncValue.data(null);
      return e.toString().replaceAll('Exception: ', '');
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    state = const AsyncValue.data(null);
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<ProfileModel?>>((ref) {
  return AuthNotifier(ref.watch(authServiceProvider));
});
