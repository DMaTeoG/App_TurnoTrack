import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../datasources/supabase_datasource.dart';
import '../models/user_model.dart';
import '../../domain/repositories/i_attendance_repository.dart';

/// Implementation of IAttendanceRepository
/// Handles check-in/check-out WITHOUT radius validation (exact location only)
class AttendanceRepositoryImpl implements IAttendanceRepository {
  final SupabaseDatasource _datasource;

  AttendanceRepositoryImpl(this._datasource);

  /// Check-in (no radius validation, just exact location)
  @override
  Future<AttendanceModel> checkIn({
    required String userId,
    required double latitude,
    required double longitude,
    required String photoUrl,
    String? address,
  }) async {
    try {
      final now = DateTime.now();

      final response = await _datasource.client
          .from('attendance')
          .insert({
            'user_id': userId,
            'check_in_time': now.toIso8601String(),
            'check_in_latitude': latitude,
            'check_in_longitude': longitude,
            'check_in_photo_url': photoUrl,
            'check_in_address': address,
          })
          .select()
          .single();

      return AttendanceModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('Check-in error: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected check-in error: $e');
    }
  }

  /// Check-out
  @override
  Future<AttendanceModel> checkOut({
    required String userId,
    required double latitude,
    required double longitude,
    required String photoUrl,
    String? address,
  }) async {
    try {
      final now = DateTime.now();

      // First, get the latest check-in record to update it
      final latestCheckIn = await _datasource.client
          .from('attendance')
          .select()
          .eq('user_id', userId)
          .isFilter('check_out_time', null)
          .order('check_in_time', ascending: false)
          .limit(1)
          .maybeSingle();

      if (latestCheckIn == null) {
        throw Exception('No check-in record found to check out');
      }

      final response = await _datasource.client
          .from('attendance')
          .update({
            'check_out_time': now.toIso8601String(),
            'check_out_latitude': latitude,
            'check_out_longitude': longitude,
            'check_out_photo_url': photoUrl,
            'check_out_address': address,
          })
          .eq('id', latestCheckIn['id'])
          .select()
          .single();

      return AttendanceModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('Check-out error: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected check-out error: $e');
    }
  }

  /// Get attendance records for a user
  @override
  Future<List<AttendanceModel>> getAttendanceByUser({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _datasource.client
          .from('attendance')
          .select()
          .eq('user_id', userId);

      if (startDate != null) {
        query = query.gte('check_in_time', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('check_in_time', endDate.toIso8601String());
      }

      final response = await query.order('check_in_time', ascending: false);

      return (response as List)
          .map((json) => AttendanceModel.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Error getting attendance: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// Get pending sync records
  /// (Not applicable with Supabase offline-first, always returns empty list)
  @override
  Future<List<AttendanceModel>> getPendingAttendance() async {
    // With Supabase offline-first, there are no "pending" records
    // Everything syncs automatically
    return [];
  }

  /// Upload attendance photo to Supabase Storage
  @override
  Future<String> uploadPhoto(String localPath) async {
    try {
      final file = File(localPath);
      if (!file.existsSync()) {
        throw Exception('File not found: $localPath');
      }

      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storagePath = 'attendance-photos/$fileName';

      await _datasource.client.storage
          .from('attendance-photos')
          .upload(storagePath, file);

      // Return public URL
      final publicUrl = _datasource.client.storage
          .from('attendance-photos')
          .getPublicUrl(storagePath);

      return publicUrl;
    } on StorageException catch (e) {
      throw Exception('Photo upload error: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected photo upload error: $e');
    }
  }
}
