import '../../data/models/user_model.dart';

/// Repository interface for attendance operations
/// Methods throw Exception on failure
abstract class IAttendanceRepository {
  /// Create a new check-in record (NO radius validation, just exact location)
  Future<AttendanceModel> checkIn({
    required String userId,
    required double latitude,
    required double longitude,
    required String photoUrl,
    String? address,
  });

  /// Create a new check-out record
  Future<AttendanceModel> checkOut({
    required String userId,
    required double latitude,
    required double longitude,
    required String photoUrl,
    String? address,
  });

  /// Get attendance records for a user
  Future<List<AttendanceModel>> getAttendanceByUser({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Get pending attendance records (not synced)
  Future<List<AttendanceModel>> getPendingAttendance();

  /// Upload photo to storage
  Future<String> uploadPhoto(String localPath);
}
