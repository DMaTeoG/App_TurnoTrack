// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserModelImpl _$$UserModelImplFromJson(Map<String, dynamic> json) =>
    _$UserModelImpl(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['fullName'] as String,
      role: json['role'] as String,
      isActive: json['isActive'] as bool,
      photoUrl: json['photoUrl'] as String?,
      supervisorId: json['supervisorId'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$UserModelImplToJson(_$UserModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'fullName': instance.fullName,
      'role': instance.role,
      'isActive': instance.isActive,
      'photoUrl': instance.photoUrl,
      'supervisorId': instance.supervisorId,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

_$AttendanceModelImpl _$$AttendanceModelImplFromJson(
        Map<String, dynamic> json) =>
    _$AttendanceModelImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      checkInTime: DateTime.parse(json['checkInTime'] as String),
      checkOutTime: json['checkOutTime'] == null
          ? null
          : DateTime.parse(json['checkOutTime'] as String),
      checkInLatitude: (json['checkInLatitude'] as num).toDouble(),
      checkInLongitude: (json['checkInLongitude'] as num).toDouble(),
      checkOutLatitude: (json['checkOutLatitude'] as num?)?.toDouble(),
      checkOutLongitude: (json['checkOutLongitude'] as num?)?.toDouble(),
      checkInPhotoUrl: json['checkInPhotoUrl'] as String,
      checkOutPhotoUrl: json['checkOutPhotoUrl'] as String?,
      checkInAddress: json['checkInAddress'] as String?,
      checkOutAddress: json['checkOutAddress'] as String?,
      isLate: json['isLate'] as bool? ?? false,
      minutesLate: (json['minutesLate'] as num?)?.toInt() ?? 0,
      synced: json['synced'] as bool? ?? true,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$AttendanceModelImplToJson(
        _$AttendanceModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'checkInTime': instance.checkInTime.toIso8601String(),
      'checkOutTime': instance.checkOutTime?.toIso8601String(),
      'checkInLatitude': instance.checkInLatitude,
      'checkInLongitude': instance.checkInLongitude,
      'checkOutLatitude': instance.checkOutLatitude,
      'checkOutLongitude': instance.checkOutLongitude,
      'checkInPhotoUrl': instance.checkInPhotoUrl,
      'checkOutPhotoUrl': instance.checkOutPhotoUrl,
      'checkInAddress': instance.checkInAddress,
      'checkOutAddress': instance.checkOutAddress,
      'isLate': instance.isLate,
      'minutesLate': instance.minutesLate,
      'synced': instance.synced,
      'createdAt': instance.createdAt?.toIso8601String(),
    };

_$LocationModelImpl _$$LocationModelImplFromJson(Map<String, dynamic> json) =>
    _$LocationModelImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String?,
      description: json['description'] as String?,
      isActive: json['isActive'] as bool?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$LocationModelImplToJson(_$LocationModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'address': instance.address,
      'description': instance.description,
      'isActive': instance.isActive,
      'createdAt': instance.createdAt?.toIso8601String(),
    };

_$PerformanceMetricsImpl _$$PerformanceMetricsImplFromJson(
        Map<String, dynamic> json) =>
    _$PerformanceMetricsImpl(
      userId: json['userId'] as String,
      attendanceScore: (json['attendanceScore'] as num).toInt(),
      averageCheckInTime: (json['averageCheckInTime'] as num).toDouble(),
      totalCheckIns: (json['totalCheckIns'] as num).toInt(),
      lateCheckIns: (json['lateCheckIns'] as num).toInt(),
      periodStart: DateTime.parse(json['periodStart'] as String),
      periodEnd: DateTime.parse(json['periodEnd'] as String),
      aiRecommendations: json['aiRecommendations'] as Map<String, dynamic>?,
      ranking: (json['ranking'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$PerformanceMetricsImplToJson(
        _$PerformanceMetricsImpl instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'attendanceScore': instance.attendanceScore,
      'averageCheckInTime': instance.averageCheckInTime,
      'totalCheckIns': instance.totalCheckIns,
      'lateCheckIns': instance.lateCheckIns,
      'periodStart': instance.periodStart.toIso8601String(),
      'periodEnd': instance.periodEnd.toIso8601String(),
      'aiRecommendations': instance.aiRecommendations,
      'ranking': instance.ranking,
    };

_$SalesDataImpl _$$SalesDataImplFromJson(Map<String, dynamic> json) =>
    _$SalesDataImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      date: DateTime.parse(json['date'] as String),
      amount: (json['amount'] as num).toDouble(),
      quantity: (json['quantity'] as num).toInt(),
      productCategory: json['productCategory'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$$SalesDataImplToJson(_$SalesDataImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'date': instance.date.toIso8601String(),
      'amount': instance.amount,
      'quantity': instance.quantity,
      'productCategory': instance.productCategory,
      'metadata': instance.metadata,
    };
