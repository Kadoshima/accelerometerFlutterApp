// lib/screens/new_password_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';

class NewPasswordScreen extends ConsumerStatefulWidget {
  final String username;
  final String session;

  NewPasswordScreen({required this.username, required this.session});

  @override
  _NewPasswordScreenState createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends ConsumerState<NewPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  String _newPassword = '';
  bool _isLoading = false;
  String? _errorMessage;

  void _submitNewPassword() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final authService = AuthService();
        final tokens = await authService.respondToAuthChallenge(
          widget.username,
          widget.session,
          _newPassword,
        );

        if (tokens != null) {
          // トークンを保存・認証状態を更新
          final authNotifier = ref.read(authProvider.notifier);
          await authNotifier.saveTokens(tokens);
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          setState(() {
            _errorMessage = 'パスワードの更新に失敗しました。';
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'エラーが発生しました: $e';
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('新しいパスワードの設定'),
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
                        decoration: InputDecoration(labelText: '新しいパスワード'),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '新しいパスワードを入力してください';
                          }
                          if (value.length < 8) {
                            return 'パスワードは8文字以上にしてください';
                          }
                          // 追加のパスワードポリシーをここに実装可能
                          return null;
                        },
                        onSaved: (value) {
                          _newPassword = value!;
                        },
                      ),
                      SizedBox(height: 20),
                      _isLoading
                          ? CircularProgressIndicator()
                          : ElevatedButton(
                              onPressed: _submitNewPassword, child: Text('更新')),
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
