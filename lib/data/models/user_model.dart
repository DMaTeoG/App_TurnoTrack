import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    required String id,
    required String email,
    required String fullName,
    required String role,
    required bool isActive,
    String? photoUrl,
    String? phone,
    String? supervisorId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Convertir snake_case a camelCase
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      role: json['role'] as String,
      isActive: json['is_active'] as bool,
      photoUrl: json['photo_url'] as String?,
      phone: json['phone'] as String?,
      supervisorId: json['supervisor_id'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }
}

@freezed
class AttendanceModel with _$AttendanceModel {
  const factory AttendanceModel({
    required String id,
    required String userId,
    required DateTime checkInTime,
    DateTime? checkOutTime,
    required double checkInLatitude,
    required double checkInLongitude,
    double? checkOutLatitude,
    double? checkOutLongitude,
    required String checkInPhotoUrl,
    String? checkOutPhotoUrl,
    String? checkInAddress,
    String? checkOutAddress,
    @Default(false) bool isLate,
    @Default(0) int minutesLate,
    @Default(true) bool synced,
    DateTime? createdAt,
  }) = _AttendanceModel;

  factory AttendanceModel.fromJson(Map<String, dynamic> json) =>
      _$AttendanceModelFromJson(json);
}

@freezed
class LocationModel with _$LocationModel {
  const factory LocationModel({
    required String id,
    required String name,
    required double latitude,
    required double longitude,
    String? address,
    String? description,
    bool? isActive,
    DateTime? createdAt,
  }) = _LocationModel;

  factory LocationModel.fromJson(Map<String, dynamic> json) =>
      _$LocationModelFromJson(json);
}

@freezed
class PerformanceMetrics with _$PerformanceMetrics {
  const factory PerformanceMetrics({
    required String userId,
    required int attendanceScore,
    required double averageCheckInTime,
    required int totalCheckIns,
    required int lateCheckIns,
    required DateTime periodStart,
    required DateTime periodEnd,
    Map<String, dynamic>? aiRecommendations,
    int? ranking,
  }) = _PerformanceMetrics;

  factory PerformanceMetrics.fromJson(Map<String, dynamic> json) =>
      _$PerformanceMetricsFromJson(json);
}

@freezed
class SalesData with _$SalesData {
  const factory SalesData({
    required String id,
    required String userId,
    required DateTime date,
    required double amount,
    required int quantity,
    String? productCategory,
    Map<String, dynamic>? metadata,
  }) = _SalesData;

  factory SalesData.fromJson(Map<String, dynamic> json) =>
      _$SalesDataFromJson(json);
}
