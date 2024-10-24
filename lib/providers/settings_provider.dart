// lib/providers/settings_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SettingsState {
  final String apiBaseUri;

  SettingsState({required this.apiBaseUri});

  factory SettingsState.initial() {
    return SettingsState(apiBaseUri: 'https://api.example.com');
  }

  SettingsState copyWith({String? apiBaseUri}) {
    return SettingsState(
      apiBaseUri: apiBaseUri ?? this.apiBaseUri,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final FlutterSecureStorage _storage = FlutterSecureStorage();

  SettingsNotifier() : super(SettingsState.initial()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    String? uri = await _storage.read(key: 'api_base_uri');
    if (uri != null) {
      state = state.copyWith(apiBaseUri: uri);
    }
  }

  Future<void> setApiBaseUri(String uri) async {
    await _storage.write(key: 'api_base_uri', value: uri);
    state = state.copyWith(apiBaseUri: uri);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});
