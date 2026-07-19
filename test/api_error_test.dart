import 'dart:async' show TimeoutException;
import 'dart:io' show SocketException;
import 'package:flutter_test/flutter_test.dart';
import 'package:enercore_app/core/http/api_error.dart';

void main() {
  group('friendlyMessage', () {
    test('network failures read as a connection problem', () {
      expect(friendlyMessage(const NetworkException()),
          contains('internet connection'));
      expect(friendlyMessage(const SocketException('boom')),
          contains('internet connection'));
    });

    test('a timeout reads as the server being slow', () {
      expect(friendlyMessage(TimeoutException('slow')),
          contains('took too long'));
    });

    test('a 401 on login is spelled out as bad credentials', () {
      expect(friendlyMessage(const ApiException(401, 'Unauthorized'),
              context: 'login'),
          'Incorrect email or password.');
    });

    test('a server-side error is not leaked verbatim', () {
      expect(friendlyMessage(const ApiException(500, 'Prisma exploded')),
          contains('our end'));
    });

    test('a meaningful server message passes through', () {
      expect(friendlyMessage(const ApiException(409, 'Email already registered')),
          'Email already registered');
    });

    test('a raw technical string is replaced with a generic message', () {
      expect(friendlyMessage(Exception('Server error: 502')),
          'Something went wrong. Please try again.');
    });

    test('a plain user-facing Exception keeps its text', () {
      expect(friendlyMessage(Exception('Your cart is empty')),
          'Your cart is empty');
    });
  });
}
