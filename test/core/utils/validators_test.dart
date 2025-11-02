import 'package:flutter_test/flutter_test.dart';
import 'package:app_turnotrack/core/utils/validators.dart';

void main() {
  group('Validators Tests', () {
    group('Email Validation', () {
      test('should return null for valid email', () {
        expect(Validators.email('test@example.com'), null);
        expect(Validators.email('user.name@domain.co'), null);
        expect(Validators.email('test123@test-domain.com'), null);
      });

      test('should return error for invalid email', () {
        expect(Validators.email(''), isNotNull);
        expect(Validators.email('invalid'), isNotNull);
        expect(Validators.email('test@'), isNotNull);
        expect(Validators.email('@domain.com'), isNotNull);
        expect(Validators.email('test@domain'), isNotNull);
      });
    });

    group('Password Validation', () {
      test('should return null for valid password', () {
        expect(Validators.password('12345678'), null);
        expect(Validators.password('password123'), null);
      });

      test('should return error for invalid password', () {
        expect(Validators.password(''), isNotNull);
        expect(Validators.password('1234567'), isNotNull);
        expect(Validators.password(null), isNotNull);
      });
    });

    group('Required Field Validation', () {
      test('should return null for non-empty value', () {
        expect(Validators.required('test'), null);
        expect(Validators.required('a'), null);
      });

      test('should return error for empty value', () {
        expect(Validators.required(''), isNotNull);
        expect(Validators.required(null), isNotNull);
      });
    });

    group('Phone Validation', () {
      test('should return null for valid phone', () {
        expect(Validators.phone('1234567890'), null);
        expect(Validators.phone('9876543210'), null);
      });

      test('should return error for invalid phone', () {
        expect(Validators.phone(''), isNotNull);
        expect(Validators.phone('123'), isNotNull);
        expect(Validators.phone('abcdefghij'), isNotNull);
        expect(Validators.phone(null), isNotNull);
      });
    });

    group('Min Length Validation', () {
      test('should return null for valid length', () {
        expect(Validators.minLength('test', 3), null);
        expect(Validators.minLength('hello world', 5), null);
      });

      test('should return error for invalid length', () {
        expect(Validators.minLength('ab', 3), isNotNull);
        expect(Validators.minLength('', 1), isNotNull);
        expect(Validators.minLength(null, 1), isNotNull);
      });
    });

    group('Max Length Validation', () {
      test('should return null for valid length', () {
        expect(Validators.maxLength('test', 10), null);
        expect(Validators.maxLength('hello', 5), null);
        expect(Validators.maxLength(null, 5), null);
      });

      test('should return error for invalid length', () {
        expect(Validators.maxLength('hello world', 5), isNotNull);
        expect(Validators.maxLength('testing', 3), isNotNull);
      });
    });
  });
}
