// lib/screens/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _apiBaseUri;

  @override
  void initState() {
    super.initState();
    _apiBaseUri = ref.read(settingsProvider).apiBaseUri;
  }

  void _saveSettings() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      ref.read(settingsProvider.notifier).setApiBaseUri(_apiBaseUri);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('設定を保存しました。'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('設定'),
        ),
        body: Padding(
          padding: EdgeInsets.all(16.0),
          child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    initialValue: _apiBaseUri,
                    decoration: InputDecoration(labelText: 'APIベースURI'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'APIベースURIを入力してください';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _apiBaseUri = value!;
                    },
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(onPressed: _saveSettings, child: Text('保存')),
                ],
              )),
        ));
  }
}
