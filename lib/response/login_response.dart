// lib/response/login_response.dart
enum LoginStatus { success, newPasswordRequired, failure }

class LoginResponse {
  final LoginStatus status;
  final String? session;
  final String? errorMessage;

  LoginResponse.success()
      : status = LoginStatus.success,
        session = null,
        errorMessage = null;

  LoginResponse.newPasswordRequired(this.session)
      : status = LoginStatus.newPasswordRequired,
        errorMessage = null;

  LoginResponse.failure(this.errorMessage)
      : status = LoginStatus.failure,
        session = null;
}
