// lib/screens/login/login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../response/login_response.dart'; // インポートを追加
import 'new_password_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String _username = '';
  String _password = '';
  bool _isLoading = false;
  String? _errorMessage;

  void _login() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final authNotifier = ref.read(authProvider.notifier);
      final loginResponse = await authNotifier.login(_username, _password);

      print('LoginResponse Status: ${loginResponse.status}'); // デバッグ用
      print('LoginResponse Session: ${loginResponse.session}'); // デバッグ用

      setState(() {
        _isLoading = false;
      });

      switch (loginResponse.status) {
        case LoginStatus.success:
          Navigator.pushReplacementNamed(context, '/home');
          break;
        case LoginStatus.newPasswordRequired:
          if (loginResponse.session != null) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => NewPasswordScreen(
                  username: _username,
                  session: loginResponse.session!,
                ),
              ),
            );
          } else {
            setState(() {
              _errorMessage = 'セッション情報が取得できませんでした。再度ログインしてください。';
            });
          }
          break;
        case LoginStatus.failure:
          setState(() {
            _errorMessage = 'ログインに失敗しました: ${loginResponse.errorMessage}';
          });
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('ログイン'),
        ),
        body: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: SingleChildScrollView(
              child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        decoration: InputDecoration(labelText: 'ユーザー名'),
                        onSaved: (value) {
                          _username = value!;
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'ユーザー名を入力してください';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        decoration: InputDecoration(labelText: 'パスワード'),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'パスワードを入力してください';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          _password = value!;
                        },
                      ),
                      SizedBox(height: 20),
                      _isLoading
                          ? CircularProgressIndicator()
                          : ElevatedButton(
                              onPressed: _login, child: Text('ログイン')),
                      if (_errorMessage != null) ...[
                        SizedBox(height: 20),
                        Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ],
                  )),
            ),
          ),
        ));
  }
}
