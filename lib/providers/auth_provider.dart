// lib/providers/auth_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/auth_service.dart';
import '../response/login_response.dart';

class AuthState {
  final bool isAuthenticated;
  final String? accessToken;
  final String? idToken;
  final String? refreshToken;

  AuthState({
    required this.isAuthenticated,
    this.accessToken,
    this.idToken,
    this.refreshToken,
  });

  factory AuthState.initial() {
    return AuthState(isAuthenticated: false);
  }

  AuthState copyWith({
    bool? isAuthenticated,
    String? accessToken,
    String? idToken,
    String? refreshToken,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      accessToken: accessToken ?? this.accessToken,
      idToken: idToken ?? this.idToken,
      refreshToken: refreshToken ?? this.refreshToken,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  final FlutterSecureStorage _storage = FlutterSecureStorage();

  AuthNotifier(this._authService) : super(AuthState.initial()) {
    _loadTokens();
  }

  Future<void> _loadTokens() async {
    String? accessToken = await _storage.read(key: 'access_token');
    String? idToken = await _storage.read(key: 'id_token');
    String? refreshToken = await _storage.read(key: 'refresh_token');
    if (accessToken != null && idToken != null) {
      state = state.copyWith(
        isAuthenticated: true,
        accessToken: accessToken,
        idToken: idToken,
        refreshToken: refreshToken,
      );
    }
  }

  Future<LoginResponse> login(String username, String password) async {
    try {
      final result = await _authService.login(username, password);
      print('AuthNotifier.login result: $result'); // デバッグ用

      if (result == null) {
        throw Exception('Failed to login');
      }

      print('hello ${result.containsKey('AuthenticationResult')}');

      if (result.containsKey('AuthenticationResult')) {
        print('AuthenticationResult found'); // デバッグ用
        // Successful login
        await _storage.write(key: 'access_token', value: result['AccessToken']);
        await _storage.write(key: 'id_token', value: result['IdToken']);
        await _storage.write(
            key: 'refresh_token', value: result['RefreshToken']);
        state = state.copyWith(
          isAuthenticated: true,
          accessToken: result['AccessToken'],
          idToken: result['IdToken'],
          refreshToken: result['RefreshToken'],
        );
        return LoginResponse.success();
      } else if (result['ChallengeName'] == 'NEW_PASSWORD_REQUIRED') {
        print('NEW_PASSWORD_REQUIRED challenge'); // デバッグ用
        // NEW_PASSWORD_REQUIRED チャレンジが返された場合
        final session = result['Session'];
        if (session != null && session.length >= 20) {
          print('Valid session: $session'); // デバッグ用
          return LoginResponse.newPasswordRequired(session);
        } else {
          throw Exception('Invalid session received');
        }
      } else {
        throw Exception('Unknown challenge');
      }
    } catch (e) {
      print('ログインエラー: $e');
      return LoginResponse.failure(e.toString());
    }
  }

  Future<void> saveTokens(Map<String, dynamic> tokens) async {
    await _storage.write(key: 'access_token', value: tokens['accessToken']);
    await _storage.write(key: 'id_token', value: tokens['idToken']);
    await _storage.write(key: 'refresh_token', value: tokens['refreshToken']);
    state = state.copyWith(
      isAuthenticated: true,
      accessToken: tokens['accessToken'],
      idToken: tokens['idToken'],
      refreshToken: tokens['RefreshToken'],
    );
  }

  Future<void> logout() async {
    await _storage.deleteAll();
    state = state.copyWith(
      isAuthenticated: false,
      accessToken: null,
      idToken: null,
      refreshToken: null,
    );
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = AuthService();
  return AuthNotifier(authService);
});
