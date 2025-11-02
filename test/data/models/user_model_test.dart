import 'package:flutter_test/flutter_test.dart';
import 'package:app_turnotrack/data/models/user_model.dart';

void main() {
  group('UserModel Tests', () {
    test('should create UserModel instance', () {
      final user = UserModel(
        id: 'user123',
        email: 'test@example.com',
        fullName: 'Test User',
        role: 'worker',
        isActive: true,
        createdAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
      );

      expect(user.id, 'user123');
      expect(user.email, 'test@example.com');
      expect(user.fullName, 'Test User');
      expect(user.role, 'worker');
      expect(user.isActive, true);
    });

    test('should handle optional fields', () {
      final user = UserModel(
        id: 'user123',
        email: 'test@example.com',
        fullName: 'Test User',
        role: 'worker',
        isActive: true,
        photoUrl: null,
        supervisorId: null,
      );

      expect(user.photoUrl, null);
      expect(user.supervisorId, null);
    });
  });
}
