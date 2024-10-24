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

  Future<Map<String, dynamic>?> login(String username, String password) async {
    try {
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

      final response = await http.post(url, headers: headers, body: body);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data.containsKey('AuthenticationResult')) {
          return data;
        } else if (data['ChallengeName'] == 'NEW_PASSWORD_REQUIRED') {
          print('Session: ${data['Session']}'); // デバッグ用
          return {
            'ChallengeName': data['ChallengeName'],
            'Session': data['Session'],
            'UserAttributes': data['ChallengeParameters']['userAttributes'],
          };
        }
      } else {
        throw Exception(data['message'] ?? 'Failed to login');
      }
    } catch (e) {
      print('エラーが発生しました: $e');
      rethrow;
    }
    return null;
  }

  Future<Map<String, dynamic>?> respondToAuthChallenge(
      String username, String session, String newPassword) async {
    final url = Uri.https('cognito-idp.$region.amazonaws.com', '/');
    final headers = {
      'Content-Type': 'application/x-amz-json-1.1',
      'X-Amz-Target':
          'AWSCognitoIdentityProviderService.RespondToAuthChallenge',
    };
    final body = jsonEncode({
      'ClientId': clientId,
      'ChallengeName': 'NEW_PASSWORD_REQUIRED',
      'Session': session,
      'ChallengeResponses': {
        'USERNAME': username,
        'NEW_PASSWORD': newPassword,
      },
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      print('RespondToAuthChallenge Response Status: ${response.statusCode}');
      print('RespondToAuthChallenge Response Body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data.containsKey('AuthenticationResult')) {
          return data['AuthenticationResult'];
        }
      } else {
        final error = jsonDecode(response.body);
        throw Exception(
            error['message'] ?? 'Failed to respond to auth challenge');
      }
    } catch (e) {
      print('エラーが発生しました: $e');
      rethrow;
    }
    return null;
  }
}
