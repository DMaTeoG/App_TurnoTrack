import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class SupabaseDatasource {
  final SupabaseClient _client;

  SupabaseDatasource(this._client);

  // Exponer el cliente para repositories específicos
  SupabaseClient get client => _client;

  // Auth
  Future<UserModel?> signIn(String email, String password) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user != null) {
      final userModel = await getUserById(response.user!.id);
      return userModel;
    }

    return null;
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  User? getCurrentUser() {
    return _client.auth.currentUser;
  }

  // Users
  Future<UserModel?> getUserById(String id) async {
    try {
      final response = await _client
          .from('users')
          .select()
          .eq('id', id)
          .single();

      return UserModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<UserModel>> getUsersBySupervisor(String supervisorId) async {
    final response = await _client
        .from('users')
        .select()
        .eq('supervisor_id', supervisorId)
        .eq('is_active', true);

    return (response as List).map((json) => UserModel.fromJson(json)).toList();
  }

  Future<List<UserModel>> getAllActiveUsers() async {
    final response = await _client.from('users').select().eq('is_active', true);

    return (response as List).map((json) => UserModel.fromJson(json)).toList();
  }

  Future<UserModel> createUser(UserModel user) async {
    final response = await _client
        .from('users')
        .insert(user.toJson())
        .select()
        .single();

    return UserModel.fromJson(response);
  }

  Future<UserModel> updateUser(UserModel user) async {
    final response = await _client
        .from('users')
        .update(user.toJson())
        .eq('id', user.id)
        .select()
        .single();

    return UserModel.fromJson(response);
  }

  // Attendance
  Future<AttendanceModel> createAttendance(AttendanceModel attendance) async {
    final response = await _client
        .from('attendance')
        .insert(attendance.toJson())
        .select()
        .single();

    return AttendanceModel.fromJson(response);
  }

  Future<List<AttendanceModel>> getAttendanceByUser(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    final response = await _client
        .from('attendance')
        .select()
        .eq('user_id', userId)
        .gte('check_in_time', start.toIso8601String())
        .lte('check_in_time', end.toIso8601String())
        .order('check_in_time', ascending: false);

    return (response as List)
        .map((json) => AttendanceModel.fromJson(json))
        .toList();
  }

  Future<List<AttendanceModel>> getTodayAttendance(String userId) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));

    return getAttendanceByUser(userId, start, end);
  }

  // Photos
  Future<String> uploadPhoto(String bucket, String path, File file) async {
    await _client.storage.from(bucket).upload(path, file);
    return _client.storage.from(bucket).getPublicUrl(path);
  }

  // Locations
  Future<List<LocationModel>> getActiveLocations() async {
    final response = await _client
        .from('locations')
        .select()
        .eq('is_active', true);

    return (response as List)
        .map((json) => LocationModel.fromJson(json))
        .toList();
  }

  // Attendance methods
  Future<List<AttendanceModel>> getAttendance(String userId) async {
    final response = await _client
        .from('attendance')
        .select()
        .eq('user_id', userId)
        .order('check_in_time', ascending: false);

    return (response as List)
        .map((json) => AttendanceModel.fromJson(json))
        .toList();
  }

  Future<String> uploadAttendancePhoto(File file, String fileName) async {
    final bytes = await file.readAsBytes();
    await _client.storage
        .from('attendance-photos')
        .uploadBinary(fileName, bytes);

    final url = _client.storage
        .from('attendance-photos')
        .getPublicUrl(fileName);

    return url;
  }

  // Performance
  Future<PerformanceMetrics> getPerformanceMetrics(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    final response = await _client.rpc(
      'get_performance_metrics',
      params: {
        'p_user_id': userId,
        'p_start_date': start.toIso8601String(),
        'p_end_date': end.toIso8601String(),
      },
    );

    return PerformanceMetrics.fromJson(response);
  }

  Future<List<Map<String, dynamic>>> getRankings(
    DateTime start,
    DateTime end,
  ) async {
    final response = await _client.rpc(
      'get_rankings',
      params: {
        'p_start_date': start.toIso8601String(),
        'p_end_date': end.toIso8601String(),
      },
    );

    return List<Map<String, dynamic>>.from(response);
  }

  // Sales
  Future<List<SalesData>> getSalesByUser(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    final response = await _client
        .from('sales')
        .select()
        .eq('user_id', userId)
        .gte('date', start.toIso8601String())
        .lte('date', end.toIso8601String())
        .order('date', ascending: false);

    return (response as List).map((json) => SalesData.fromJson(json)).toList();
  }

  Future<void> createSale({
    required String userId,
    required DateTime date,
    required double amount,
    required int quantity,
    required String productCategory,
    Map<String, dynamic>? metadata,
  }) async {
    await _client.from('sales').insert({
      'user_id': userId,
      'date': date.toIso8601String(),
      'amount': amount,
      'quantity': quantity,
      'product_category': productCategory,
      'metadata': metadata,
    });
  }
}
