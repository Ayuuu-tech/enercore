import 'dart:async' show TimeoutException;
import 'dart:io' show SocketException, HandshakeException;
import 'package:http/http.dart' show ClientException;

/// The request never reached the server (no internet, server down, DNS/TLS
/// failure, or it timed out). Distinct from a server that answered with an
/// error — the user's next step is different.
class NetworkException implements Exception {
  final String message;
  const NetworkException([this.message = 'network']);
}

/// The server answered, but with an error status. Carries the HTTP status and
/// the server's own message so callers can react to specific cases (e.g. 401).
class ApiException implements Exception {
  final int statusCode;
  final String message;
  const ApiException(this.statusCode, this.message);
}

/// True when [error] means "couldn't reach the server" rather than "the server
/// said no". Covers the raw dart:io/http failures and our own NetworkException.
bool isNetworkError(Object error) =>
    error is NetworkException ||
    error is SocketException ||
    error is HandshakeException ||
    error is ClientException ||
    error is TimeoutException;

/// Turns any thrown error into a short, human message safe to show a user —
/// never a raw stack trace, "Exception:", or a dev instruction.
///
/// [context] tunes a couple of cases: pass `'login'` so a 401 reads
/// "Incorrect email or password" instead of the generic server text.
String friendlyMessage(Object error, {String? context}) {
  if (isNetworkError(error)) {
    if (error is TimeoutException) {
      return 'The server took too long to respond. Check your connection and try again.';
    }
    return 'Can\'t connect. Check your internet connection and try again.';
  }

  if (error is ApiException) {
    if (context == 'login' && error.statusCode == 401) {
      return 'Incorrect email or password.';
    }
    if (error.statusCode == 401) return 'Please sign in again.';
    if (error.statusCode == 403) return 'You don\'t have access to do that.';
    if (error.statusCode == 429) {
      return 'Too many attempts. Please wait a minute and try again.';
    }
    if (error.statusCode >= 500) {
      return 'Something went wrong on our end. Please try again in a moment.';
    }
    return _clean(error.message);
  }

  // A plain Exception carrying a message from a repository.
  final raw = error.toString().replaceAll('Exception:', '').trim();
  return _clean(raw);
}

/// Strips technical noise; falls back to a generic message when what's left
/// still looks like an internal error rather than something user-meaningful.
String _clean(String message) {
  final m = message.trim();
  if (m.isEmpty ||
      m.contains('SocketException') ||
      m.contains('TimeoutException') ||
      m.contains('ClientException') ||
      m.contains('HandshakeException') ||
      m.contains('Failed host lookup') ||
      m.contains('Connection refused') ||
      m.contains('status code') ||
      m.contains('XMLHttpRequest') ||
      m.startsWith('Server error') ||
      m.startsWith('type ') ||
      m.startsWith('Null check')) {
    return 'Something went wrong. Please try again.';
  }
  return m;
}
