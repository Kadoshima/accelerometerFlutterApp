// lib/providers/auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/auth_service.dart';

// 認証状態を表すモデル
class AuthState {
  final bool isAuthenticated;
  final String? token;

  AuthState({required this.isAuthenticated, this.token});

  factory AuthState.initial() {
    return AuthState(isAuthenticated: false, token: null);
  }

  AuthState copyWith({bool? isAuthenticated, String? token}) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      token: token ?? this.token,
    );
  }
}

// AuthNotifierの実装
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  final FlutterSecureStorage _storage = FlutterSecureStorage();

  AuthNotifier(this._authService) : super(AuthState.initial()) {
    _loadToken();
  }

  Future<void> _loadToken() async {
    String? token = await _storage.read(key: 'bearer_token');
    if (token != null) {
      state = state.copyWith(isAuthenticated: true, token: token);
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      String token = await _authService.login(email, password);
      await _storage.write(key: 'bearer_token', value: token);
      state = state.copyWith(isAuthenticated: true, token: token);
      return true;
    } catch (e) {
      // エラーハンドリング
      return false;
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'bearer_token');
    state = state.copyWith(isAuthenticated: false, token: null);
  }
}

// プロバイダーの定義
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = AuthService();
  return AuthNotifier(authService);
});
