import 'package:shelf/shelf.dart';

/// Simple password authentication handler
class AuthHandler {
  final String? password;

  AuthHandler({this.password});

  /// Middleware to check authentication
  Middleware get middleware {
    if (password == null || password!.isEmpty) {
      return (innerHandler) => innerHandler;
    }

    return (innerHandler) {
      return (Request request) async {
        // Check for password in query parameter or header
        final providedPassword = request.url.queryParameters['password'] ??
            request.headers['x-password'];

        if (providedPassword != password) {
          return Response.forbidden('Authentication required');
        }

        return innerHandler(request);
      };
    };
  }

  /// Check if request is authenticated
  bool isAuthenticated(Request request) {
    if (password == null || password!.isEmpty) return true;

    final providedPassword = request.url.queryParameters['password'] ??
        request.headers['x-password'];

    return providedPassword == password;
  }
}

