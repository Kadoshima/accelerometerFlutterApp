// lib/services/auth_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthService {
  final String userPoolId =
      dotenv.env['COGNITO_USER_POOL_ID'] ?? 'ap-northeast-1_3kIbsk5Qv';
  final String clientId =
      dotenv.env['COGNITO_CLIENT_ID'] ?? '2h68mns23hkisbaite954hljqr';
  final String region = 'ap-northeast-1'; // 例として東京リージョン

  Future<String> login(String username, String password) async {
    print('1');

    final url = Uri.https('cognito-idp.$region.amazonaws.com', '/');
    final headers = {
      'Content-Type': 'application/x-amz-json-1.1',
      'X-Amz-Target': 'AWSCognitoIdentityProviderService.InitiateAuth',
    };
    final body = jsonEncode({
      'AuthFlow': 'USER_PASSWORD_AUTH',
      'ClientId': clientId,
      'AuthParameters': {
        'USERNAME': username,
        'PASSWORD': password,
      },
    });

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );

      print('2');
      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['AuthenticationResult']['AccessToken'];
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to login');
      }
    } catch (e, stackTrace) {
      print('エラーが発生しました: $e');
      print('スタックトレース: $stackTrace');
      rethrow;
    }
  }
}
