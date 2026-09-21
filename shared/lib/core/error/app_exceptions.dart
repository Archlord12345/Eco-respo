class AppFailure implements Exception {
  const AppFailure(this.message, {this.code});
  final String message;
  final String? code;

  @override
  String toString() => message;
}

class AuthFailure extends AppFailure {
  const AuthFailure(super.message, {super.code});
}

class NetworkFailure extends AppFailure {
  const NetworkFailure(super.message, {super.code});
}
