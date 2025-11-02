import '../../data/models/user_model.dart';

/// Repository interface for user operations
/// Methods throw Exception on failure
abstract class IUserRepository {
  /// Get current authenticated user
  Future<UserModel?> getCurrentUser();

  /// Get user by ID
  Future<UserModel> getUserById(String id);

  /// Get workers supervised by a supervisor
  Future<List<UserModel>> getWorkersBySupervisor(String supervisorId);

  /// Create a new worker (supervisor/manager only)
  Future<UserModel> createWorker({
    required String email,
    required String fullName,
    required String supervisorId,
    String? photoUrl,
  });

  /// Update user information
  Future<UserModel> updateUser(String id, Map<String, dynamic> updates);

  /// Deactivate user account
  Future<void> deactivateUser(String id);
}
