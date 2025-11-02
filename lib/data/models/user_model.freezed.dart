// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

UserModel _$UserModelFromJson(Map<String, dynamic> json) {
  return _UserModel.fromJson(json);
}

/// @nodoc
mixin _$UserModel {
  String get id => throw _privateConstructorUsedError;
  String get email => throw _privateConstructorUsedError;
  String get fullName => throw _privateConstructorUsedError;
  String get role => throw _privateConstructorUsedError;
  bool get isActive => throw _privateConstructorUsedError;
  String? get photoUrl => throw _privateConstructorUsedError;
  String? get supervisorId => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $UserModelCopyWith<UserModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserModelCopyWith<$Res> {
  factory $UserModelCopyWith(UserModel value, $Res Function(UserModel) then) =
      _$UserModelCopyWithImpl<$Res, UserModel>;
  @useResult
  $Res call(
      {String id,
      String email,
      String fullName,
      String role,
      bool isActive,
      String? photoUrl,
      String? supervisorId,
      DateTime? createdAt,
      DateTime? updatedAt});
}

/// @nodoc
class _$UserModelCopyWithImpl<$Res, $Val extends UserModel>
    implements $UserModelCopyWith<$Res> {
  _$UserModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? email = null,
    Object? fullName = null,
    Object? role = null,
    Object? isActive = null,
    Object? photoUrl = freezed,
    Object? supervisorId = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      fullName: null == fullName
          ? _value.fullName
          : fullName // ignore: cast_nullable_to_non_nullable
              as String,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as String,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      photoUrl: freezed == photoUrl
          ? _value.photoUrl
          : photoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      supervisorId: freezed == supervisorId
          ? _value.supervisorId
          : supervisorId // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UserModelImplCopyWith<$Res>
    implements $UserModelCopyWith<$Res> {
  factory _$$UserModelImplCopyWith(
          _$UserModelImpl value, $Res Function(_$UserModelImpl) then) =
      __$$UserModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String email,
      String fullName,
      String role,
      bool isActive,
      String? photoUrl,
      String? supervisorId,
      DateTime? createdAt,
      DateTime? updatedAt});
}

/// @nodoc
class __$$UserModelImplCopyWithImpl<$Res>
    extends _$UserModelCopyWithImpl<$Res, _$UserModelImpl>
    implements _$$UserModelImplCopyWith<$Res> {
  __$$UserModelImplCopyWithImpl(
      _$UserModelImpl _value, $Res Function(_$UserModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? email = null,
    Object? fullName = null,
    Object? role = null,
    Object? isActive = null,
    Object? photoUrl = freezed,
    Object? supervisorId = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_$UserModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      fullName: null == fullName
          ? _value.fullName
          : fullName // ignore: cast_nullable_to_non_nullable
              as String,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as String,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      photoUrl: freezed == photoUrl
          ? _value.photoUrl
          : photoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      supervisorId: freezed == supervisorId
          ? _value.supervisorId
          : supervisorId // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserModelImpl implements _UserModel {
  const _$UserModelImpl(
      {required this.id,
      required this.email,
      required this.fullName,
      required this.role,
      required this.isActive,
      this.photoUrl,
      this.supervisorId,
      this.createdAt,
      this.updatedAt});

  factory _$UserModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserModelImplFromJson(json);

  @override
  final String id;
  @override
  final String email;
  @override
  final String fullName;
  @override
  final String role;
  @override
  final bool isActive;
  @override
  final String? photoUrl;
  @override
  final String? supervisorId;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, fullName: $fullName, role: $role, isActive: $isActive, photoUrl: $photoUrl, supervisorId: $supervisorId, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.fullName, fullName) ||
                other.fullName == fullName) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            (identical(other.photoUrl, photoUrl) ||
                other.photoUrl == photoUrl) &&
            (identical(other.supervisorId, supervisorId) ||
                other.supervisorId == supervisorId) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, email, fullName, role,
      isActive, photoUrl, supervisorId, createdAt, updatedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$UserModelImplCopyWith<_$UserModelImpl> get copyWith =>
      __$$UserModelImplCopyWithImpl<_$UserModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserModelImplToJson(
      this,
    );
  }
}

abstract class _UserModel implements UserModel {
  const factory _UserModel(
      {required final String id,
      required final String email,
      required final String fullName,
      required final String role,
      required final bool isActive,
      final String? photoUrl,
      final String? supervisorId,
      final DateTime? createdAt,
      final DateTime? updatedAt}) = _$UserModelImpl;

  factory _UserModel.fromJson(Map<String, dynamic> json) =
      _$UserModelImpl.fromJson;

  @override
  String get id;
  @override
  String get email;
  @override
  String get fullName;
  @override
  String get role;
  @override
  bool get isActive;
  @override
  String? get photoUrl;
  @override
  String? get supervisorId;
  @override
  DateTime? get createdAt;
  @override
  DateTime? get updatedAt;
  @override
  @JsonKey(ignore: true)
  _$$UserModelImplCopyWith<_$UserModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AttendanceModel _$AttendanceModelFromJson(Map<String, dynamic> json) {
  return _AttendanceModel.fromJson(json);
}

/// @nodoc
mixin _$AttendanceModel {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  DateTime get checkInTime => throw _privateConstructorUsedError;
  DateTime? get checkOutTime => throw _privateConstructorUsedError;
  double get checkInLatitude => throw _privateConstructorUsedError;
  double get checkInLongitude => throw _privateConstructorUsedError;
  double? get checkOutLatitude => throw _privateConstructorUsedError;
  double? get checkOutLongitude => throw _privateConstructorUsedError;
  String get checkInPhotoUrl => throw _privateConstructorUsedError;
  String? get checkOutPhotoUrl => throw _privateConstructorUsedError;
  String? get checkInAddress => throw _privateConstructorUsedError;
  String? get checkOutAddress => throw _privateConstructorUsedError;
  bool get isLate => throw _privateConstructorUsedError;
  int get minutesLate => throw _privateConstructorUsedError;
  bool get synced => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $AttendanceModelCopyWith<AttendanceModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AttendanceModelCopyWith<$Res> {
  factory $AttendanceModelCopyWith(
          AttendanceModel value, $Res Function(AttendanceModel) then) =
      _$AttendanceModelCopyWithImpl<$Res, AttendanceModel>;
  @useResult
  $Res call(
      {String id,
      String userId,
      DateTime checkInTime,
      DateTime? checkOutTime,
      double checkInLatitude,
      double checkInLongitude,
      double? checkOutLatitude,
      double? checkOutLongitude,
      String checkInPhotoUrl,
      String? checkOutPhotoUrl,
      String? checkInAddress,
      String? checkOutAddress,
      bool isLate,
      int minutesLate,
      bool synced,
      DateTime? createdAt});
}

/// @nodoc
class _$AttendanceModelCopyWithImpl<$Res, $Val extends AttendanceModel>
    implements $AttendanceModelCopyWith<$Res> {
  _$AttendanceModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? checkInTime = null,
    Object? checkOutTime = freezed,
    Object? checkInLatitude = null,
    Object? checkInLongitude = null,
    Object? checkOutLatitude = freezed,
    Object? checkOutLongitude = freezed,
    Object? checkInPhotoUrl = null,
    Object? checkOutPhotoUrl = freezed,
    Object? checkInAddress = freezed,
    Object? checkOutAddress = freezed,
    Object? isLate = null,
    Object? minutesLate = null,
    Object? synced = null,
    Object? createdAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      checkInTime: null == checkInTime
          ? _value.checkInTime
          : checkInTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      checkOutTime: freezed == checkOutTime
          ? _value.checkOutTime
          : checkOutTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      checkInLatitude: null == checkInLatitude
          ? _value.checkInLatitude
          : checkInLatitude // ignore: cast_nullable_to_non_nullable
              as double,
      checkInLongitude: null == checkInLongitude
          ? _value.checkInLongitude
          : checkInLongitude // ignore: cast_nullable_to_non_nullable
              as double,
      checkOutLatitude: freezed == checkOutLatitude
          ? _value.checkOutLatitude
          : checkOutLatitude // ignore: cast_nullable_to_non_nullable
              as double?,
      checkOutLongitude: freezed == checkOutLongitude
          ? _value.checkOutLongitude
          : checkOutLongitude // ignore: cast_nullable_to_non_nullable
              as double?,
      checkInPhotoUrl: null == checkInPhotoUrl
          ? _value.checkInPhotoUrl
          : checkInPhotoUrl // ignore: cast_nullable_to_non_nullable
              as String,
      checkOutPhotoUrl: freezed == checkOutPhotoUrl
          ? _value.checkOutPhotoUrl
          : checkOutPhotoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      checkInAddress: freezed == checkInAddress
          ? _value.checkInAddress
          : checkInAddress // ignore: cast_nullable_to_non_nullable
              as String?,
      checkOutAddress: freezed == checkOutAddress
          ? _value.checkOutAddress
          : checkOutAddress // ignore: cast_nullable_to_non_nullable
              as String?,
      isLate: null == isLate
          ? _value.isLate
          : isLate // ignore: cast_nullable_to_non_nullable
              as bool,
      minutesLate: null == minutesLate
          ? _value.minutesLate
          : minutesLate // ignore: cast_nullable_to_non_nullable
              as int,
      synced: null == synced
          ? _value.synced
          : synced // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AttendanceModelImplCopyWith<$Res>
    implements $AttendanceModelCopyWith<$Res> {
  factory _$$AttendanceModelImplCopyWith(_$AttendanceModelImpl value,
          $Res Function(_$AttendanceModelImpl) then) =
      __$$AttendanceModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String userId,
      DateTime checkInTime,
      DateTime? checkOutTime,
      double checkInLatitude,
      double checkInLongitude,
      double? checkOutLatitude,
      double? checkOutLongitude,
      String checkInPhotoUrl,
      String? checkOutPhotoUrl,
      String? checkInAddress,
      String? checkOutAddress,
      bool isLate,
      int minutesLate,
      bool synced,
      DateTime? createdAt});
}

/// @nodoc
class __$$AttendanceModelImplCopyWithImpl<$Res>
    extends _$AttendanceModelCopyWithImpl<$Res, _$AttendanceModelImpl>
    implements _$$AttendanceModelImplCopyWith<$Res> {
  __$$AttendanceModelImplCopyWithImpl(
      _$AttendanceModelImpl _value, $Res Function(_$AttendanceModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? checkInTime = null,
    Object? checkOutTime = freezed,
    Object? checkInLatitude = null,
    Object? checkInLongitude = null,
    Object? checkOutLatitude = freezed,
    Object? checkOutLongitude = freezed,
    Object? checkInPhotoUrl = null,
    Object? checkOutPhotoUrl = freezed,
    Object? checkInAddress = freezed,
    Object? checkOutAddress = freezed,
    Object? isLate = null,
    Object? minutesLate = null,
    Object? synced = null,
    Object? createdAt = freezed,
  }) {
    return _then(_$AttendanceModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      checkInTime: null == checkInTime
          ? _value.checkInTime
          : checkInTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      checkOutTime: freezed == checkOutTime
          ? _value.checkOutTime
          : checkOutTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      checkInLatitude: null == checkInLatitude
          ? _value.checkInLatitude
          : checkInLatitude // ignore: cast_nullable_to_non_nullable
              as double,
      checkInLongitude: null == checkInLongitude
          ? _value.checkInLongitude
          : checkInLongitude // ignore: cast_nullable_to_non_nullable
              as double,
      checkOutLatitude: freezed == checkOutLatitude
          ? _value.checkOutLatitude
          : checkOutLatitude // ignore: cast_nullable_to_non_nullable
              as double?,
      checkOutLongitude: freezed == checkOutLongitude
          ? _value.checkOutLongitude
          : checkOutLongitude // ignore: cast_nullable_to_non_nullable
              as double?,
      checkInPhotoUrl: null == checkInPhotoUrl
          ? _value.checkInPhotoUrl
          : checkInPhotoUrl // ignore: cast_nullable_to_non_nullable
              as String,
      checkOutPhotoUrl: freezed == checkOutPhotoUrl
          ? _value.checkOutPhotoUrl
          : checkOutPhotoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      checkInAddress: freezed == checkInAddress
          ? _value.checkInAddress
          : checkInAddress // ignore: cast_nullable_to_non_nullable
              as String?,
      checkOutAddress: freezed == checkOutAddress
          ? _value.checkOutAddress
          : checkOutAddress // ignore: cast_nullable_to_non_nullable
              as String?,
      isLate: null == isLate
          ? _value.isLate
          : isLate // ignore: cast_nullable_to_non_nullable
              as bool,
      minutesLate: null == minutesLate
          ? _value.minutesLate
          : minutesLate // ignore: cast_nullable_to_non_nullable
              as int,
      synced: null == synced
          ? _value.synced
          : synced // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AttendanceModelImpl implements _AttendanceModel {
  const _$AttendanceModelImpl(
      {required this.id,
      required this.userId,
      required this.checkInTime,
      this.checkOutTime,
      required this.checkInLatitude,
      required this.checkInLongitude,
      this.checkOutLatitude,
      this.checkOutLongitude,
      required this.checkInPhotoUrl,
      this.checkOutPhotoUrl,
      this.checkInAddress,
      this.checkOutAddress,
      this.isLate = false,
      this.minutesLate = 0,
      this.synced = true,
      this.createdAt});

  factory _$AttendanceModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$AttendanceModelImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  final DateTime checkInTime;
  @override
  final DateTime? checkOutTime;
  @override
  final double checkInLatitude;
  @override
  final double checkInLongitude;
  @override
  final double? checkOutLatitude;
  @override
  final double? checkOutLongitude;
  @override
  final String checkInPhotoUrl;
  @override
  final String? checkOutPhotoUrl;
  @override
  final String? checkInAddress;
  @override
  final String? checkOutAddress;
  @override
  @JsonKey()
  final bool isLate;
  @override
  @JsonKey()
  final int minutesLate;
  @override
  @JsonKey()
  final bool synced;
  @override
  final DateTime? createdAt;

  @override
  String toString() {
    return 'AttendanceModel(id: $id, userId: $userId, checkInTime: $checkInTime, checkOutTime: $checkOutTime, checkInLatitude: $checkInLatitude, checkInLongitude: $checkInLongitude, checkOutLatitude: $checkOutLatitude, checkOutLongitude: $checkOutLongitude, checkInPhotoUrl: $checkInPhotoUrl, checkOutPhotoUrl: $checkOutPhotoUrl, checkInAddress: $checkInAddress, checkOutAddress: $checkOutAddress, isLate: $isLate, minutesLate: $minutesLate, synced: $synced, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AttendanceModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.checkInTime, checkInTime) ||
                other.checkInTime == checkInTime) &&
            (identical(other.checkOutTime, checkOutTime) ||
                other.checkOutTime == checkOutTime) &&
            (identical(other.checkInLatitude, checkInLatitude) ||
                other.checkInLatitude == checkInLatitude) &&
            (identical(other.checkInLongitude, checkInLongitude) ||
                other.checkInLongitude == checkInLongitude) &&
            (identical(other.checkOutLatitude, checkOutLatitude) ||
                other.checkOutLatitude == checkOutLatitude) &&
            (identical(other.checkOutLongitude, checkOutLongitude) ||
                other.checkOutLongitude == checkOutLongitude) &&
            (identical(other.checkInPhotoUrl, checkInPhotoUrl) ||
                other.checkInPhotoUrl == checkInPhotoUrl) &&
            (identical(other.checkOutPhotoUrl, checkOutPhotoUrl) ||
                other.checkOutPhotoUrl == checkOutPhotoUrl) &&
            (identical(other.checkInAddress, checkInAddress) ||
                other.checkInAddress == checkInAddress) &&
            (identical(other.checkOutAddress, checkOutAddress) ||
                other.checkOutAddress == checkOutAddress) &&
            (identical(other.isLate, isLate) || other.isLate == isLate) &&
            (identical(other.minutesLate, minutesLate) ||
                other.minutesLate == minutesLate) &&
            (identical(other.synced, synced) || other.synced == synced) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      userId,
      checkInTime,
      checkOutTime,
      checkInLatitude,
      checkInLongitude,
      checkOutLatitude,
      checkOutLongitude,
      checkInPhotoUrl,
      checkOutPhotoUrl,
      checkInAddress,
      checkOutAddress,
      isLate,
      minutesLate,
      synced,
      createdAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AttendanceModelImplCopyWith<_$AttendanceModelImpl> get copyWith =>
      __$$AttendanceModelImplCopyWithImpl<_$AttendanceModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AttendanceModelImplToJson(
      this,
    );
  }
}

abstract class _AttendanceModel implements AttendanceModel {
  const factory _AttendanceModel(
      {required final String id,
      required final String userId,
      required final DateTime checkInTime,
      final DateTime? checkOutTime,
      required final double checkInLatitude,
      required final double checkInLongitude,
      final double? checkOutLatitude,
      final double? checkOutLongitude,
      required final String checkInPhotoUrl,
      final String? checkOutPhotoUrl,
      final String? checkInAddress,
      final String? checkOutAddress,
      final bool isLate,
      final int minutesLate,
      final bool synced,
      final DateTime? createdAt}) = _$AttendanceModelImpl;

  factory _AttendanceModel.fromJson(Map<String, dynamic> json) =
      _$AttendanceModelImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  DateTime get checkInTime;
  @override
  DateTime? get checkOutTime;
  @override
  double get checkInLatitude;
  @override
  double get checkInLongitude;
  @override
  double? get checkOutLatitude;
  @override
  double? get checkOutLongitude;
  @override
  String get checkInPhotoUrl;
  @override
  String? get checkOutPhotoUrl;
  @override
  String? get checkInAddress;
  @override
  String? get checkOutAddress;
  @override
  bool get isLate;
  @override
  int get minutesLate;
  @override
  bool get synced;
  @override
  DateTime? get createdAt;
  @override
  @JsonKey(ignore: true)
  _$$AttendanceModelImplCopyWith<_$AttendanceModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

LocationModel _$LocationModelFromJson(Map<String, dynamic> json) {
  return _LocationModel.fromJson(json);
}

/// @nodoc
mixin _$LocationModel {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  double get latitude => throw _privateConstructorUsedError;
  double get longitude => throw _privateConstructorUsedError;
  String? get address => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  bool? get isActive => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $LocationModelCopyWith<LocationModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LocationModelCopyWith<$Res> {
  factory $LocationModelCopyWith(
          LocationModel value, $Res Function(LocationModel) then) =
      _$LocationModelCopyWithImpl<$Res, LocationModel>;
  @useResult
  $Res call(
      {String id,
      String name,
      double latitude,
      double longitude,
      String? address,
      String? description,
      bool? isActive,
      DateTime? createdAt});
}

/// @nodoc
class _$LocationModelCopyWithImpl<$Res, $Val extends LocationModel>
    implements $LocationModelCopyWith<$Res> {
  _$LocationModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? latitude = null,
    Object? longitude = null,
    Object? address = freezed,
    Object? description = freezed,
    Object? isActive = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      latitude: null == latitude
          ? _value.latitude
          : latitude // ignore: cast_nullable_to_non_nullable
              as double,
      longitude: null == longitude
          ? _value.longitude
          : longitude // ignore: cast_nullable_to_non_nullable
              as double,
      address: freezed == address
          ? _value.address
          : address // ignore: cast_nullable_to_non_nullable
              as String?,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      isActive: freezed == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$LocationModelImplCopyWith<$Res>
    implements $LocationModelCopyWith<$Res> {
  factory _$$LocationModelImplCopyWith(
          _$LocationModelImpl value, $Res Function(_$LocationModelImpl) then) =
      __$$LocationModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      double latitude,
      double longitude,
      String? address,
      String? description,
      bool? isActive,
      DateTime? createdAt});
}

/// @nodoc
class __$$LocationModelImplCopyWithImpl<$Res>
    extends _$LocationModelCopyWithImpl<$Res, _$LocationModelImpl>
    implements _$$LocationModelImplCopyWith<$Res> {
  __$$LocationModelImplCopyWithImpl(
      _$LocationModelImpl _value, $Res Function(_$LocationModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? latitude = null,
    Object? longitude = null,
    Object? address = freezed,
    Object? description = freezed,
    Object? isActive = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_$LocationModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      latitude: null == latitude
          ? _value.latitude
          : latitude // ignore: cast_nullable_to_non_nullable
              as double,
      longitude: null == longitude
          ? _value.longitude
          : longitude // ignore: cast_nullable_to_non_nullable
              as double,
      address: freezed == address
          ? _value.address
          : address // ignore: cast_nullable_to_non_nullable
              as String?,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      isActive: freezed == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$LocationModelImpl implements _LocationModel {
  const _$LocationModelImpl(
      {required this.id,
      required this.name,
      required this.latitude,
      required this.longitude,
      this.address,
      this.description,
      this.isActive,
      this.createdAt});

  factory _$LocationModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$LocationModelImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final double latitude;
  @override
  final double longitude;
  @override
  final String? address;
  @override
  final String? description;
  @override
  final bool? isActive;
  @override
  final DateTime? createdAt;

  @override
  String toString() {
    return 'LocationModel(id: $id, name: $name, latitude: $latitude, longitude: $longitude, address: $address, description: $description, isActive: $isActive, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LocationModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude) &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, latitude, longitude,
      address, description, isActive, createdAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$LocationModelImplCopyWith<_$LocationModelImpl> get copyWith =>
      __$$LocationModelImplCopyWithImpl<_$LocationModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LocationModelImplToJson(
      this,
    );
  }
}

abstract class _LocationModel implements LocationModel {
  const factory _LocationModel(
      {required final String id,
      required final String name,
      required final double latitude,
      required final double longitude,
      final String? address,
      final String? description,
      final bool? isActive,
      final DateTime? createdAt}) = _$LocationModelImpl;

  factory _LocationModel.fromJson(Map<String, dynamic> json) =
      _$LocationModelImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  double get latitude;
  @override
  double get longitude;
  @override
  String? get address;
  @override
  String? get description;
  @override
  bool? get isActive;
  @override
  DateTime? get createdAt;
  @override
  @JsonKey(ignore: true)
  _$$LocationModelImplCopyWith<_$LocationModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PerformanceMetrics _$PerformanceMetricsFromJson(Map<String, dynamic> json) {
  return _PerformanceMetrics.fromJson(json);
}

/// @nodoc
mixin _$PerformanceMetrics {
  String get userId => throw _privateConstructorUsedError;
  int get attendanceScore => throw _privateConstructorUsedError;
  double get averageCheckInTime => throw _privateConstructorUsedError;
  int get totalCheckIns => throw _privateConstructorUsedError;
  int get lateCheckIns => throw _privateConstructorUsedError;
  DateTime get periodStart => throw _privateConstructorUsedError;
  DateTime get periodEnd => throw _privateConstructorUsedError;
  Map<String, dynamic>? get aiRecommendations =>
      throw _privateConstructorUsedError;
  int? get ranking => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $PerformanceMetricsCopyWith<PerformanceMetrics> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PerformanceMetricsCopyWith<$Res> {
  factory $PerformanceMetricsCopyWith(
          PerformanceMetrics value, $Res Function(PerformanceMetrics) then) =
      _$PerformanceMetricsCopyWithImpl<$Res, PerformanceMetrics>;
  @useResult
  $Res call(
      {String userId,
      int attendanceScore,
      double averageCheckInTime,
      int totalCheckIns,
      int lateCheckIns,
      DateTime periodStart,
      DateTime periodEnd,
      Map<String, dynamic>? aiRecommendations,
      int? ranking});
}

/// @nodoc
class _$PerformanceMetricsCopyWithImpl<$Res, $Val extends PerformanceMetrics>
    implements $PerformanceMetricsCopyWith<$Res> {
  _$PerformanceMetricsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? attendanceScore = null,
    Object? averageCheckInTime = null,
    Object? totalCheckIns = null,
    Object? lateCheckIns = null,
    Object? periodStart = null,
    Object? periodEnd = null,
    Object? aiRecommendations = freezed,
    Object? ranking = freezed,
  }) {
    return _then(_value.copyWith(
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      attendanceScore: null == attendanceScore
          ? _value.attendanceScore
          : attendanceScore // ignore: cast_nullable_to_non_nullable
              as int,
      averageCheckInTime: null == averageCheckInTime
          ? _value.averageCheckInTime
          : averageCheckInTime // ignore: cast_nullable_to_non_nullable
              as double,
      totalCheckIns: null == totalCheckIns
          ? _value.totalCheckIns
          : totalCheckIns // ignore: cast_nullable_to_non_nullable
              as int,
      lateCheckIns: null == lateCheckIns
          ? _value.lateCheckIns
          : lateCheckIns // ignore: cast_nullable_to_non_nullable
              as int,
      periodStart: null == periodStart
          ? _value.periodStart
          : periodStart // ignore: cast_nullable_to_non_nullable
              as DateTime,
      periodEnd: null == periodEnd
          ? _value.periodEnd
          : periodEnd // ignore: cast_nullable_to_non_nullable
              as DateTime,
      aiRecommendations: freezed == aiRecommendations
          ? _value.aiRecommendations
          : aiRecommendations // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      ranking: freezed == ranking
          ? _value.ranking
          : ranking // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PerformanceMetricsImplCopyWith<$Res>
    implements $PerformanceMetricsCopyWith<$Res> {
  factory _$$PerformanceMetricsImplCopyWith(_$PerformanceMetricsImpl value,
          $Res Function(_$PerformanceMetricsImpl) then) =
      __$$PerformanceMetricsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String userId,
      int attendanceScore,
      double averageCheckInTime,
      int totalCheckIns,
      int lateCheckIns,
      DateTime periodStart,
      DateTime periodEnd,
      Map<String, dynamic>? aiRecommendations,
      int? ranking});
}

/// @nodoc
class __$$PerformanceMetricsImplCopyWithImpl<$Res>
    extends _$PerformanceMetricsCopyWithImpl<$Res, _$PerformanceMetricsImpl>
    implements _$$PerformanceMetricsImplCopyWith<$Res> {
  __$$PerformanceMetricsImplCopyWithImpl(_$PerformanceMetricsImpl _value,
      $Res Function(_$PerformanceMetricsImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? attendanceScore = null,
    Object? averageCheckInTime = null,
    Object? totalCheckIns = null,
    Object? lateCheckIns = null,
    Object? periodStart = null,
    Object? periodEnd = null,
    Object? aiRecommendations = freezed,
    Object? ranking = freezed,
  }) {
    return _then(_$PerformanceMetricsImpl(
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      attendanceScore: null == attendanceScore
          ? _value.attendanceScore
          : attendanceScore // ignore: cast_nullable_to_non_nullable
              as int,
      averageCheckInTime: null == averageCheckInTime
          ? _value.averageCheckInTime
          : averageCheckInTime // ignore: cast_nullable_to_non_nullable
              as double,
      totalCheckIns: null == totalCheckIns
          ? _value.totalCheckIns
          : totalCheckIns // ignore: cast_nullable_to_non_nullable
              as int,
      lateCheckIns: null == lateCheckIns
          ? _value.lateCheckIns
          : lateCheckIns // ignore: cast_nullable_to_non_nullable
              as int,
      periodStart: null == periodStart
          ? _value.periodStart
          : periodStart // ignore: cast_nullable_to_non_nullable
              as DateTime,
      periodEnd: null == periodEnd
          ? _value.periodEnd
          : periodEnd // ignore: cast_nullable_to_non_nullable
              as DateTime,
      aiRecommendations: freezed == aiRecommendations
          ? _value._aiRecommendations
          : aiRecommendations // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      ranking: freezed == ranking
          ? _value.ranking
          : ranking // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PerformanceMetricsImpl implements _PerformanceMetrics {
  const _$PerformanceMetricsImpl(
      {required this.userId,
      required this.attendanceScore,
      required this.averageCheckInTime,
      required this.totalCheckIns,
      required this.lateCheckIns,
      required this.periodStart,
      required this.periodEnd,
      final Map<String, dynamic>? aiRecommendations,
      this.ranking})
      : _aiRecommendations = aiRecommendations;

  factory _$PerformanceMetricsImpl.fromJson(Map<String, dynamic> json) =>
      _$$PerformanceMetricsImplFromJson(json);

  @override
  final String userId;
  @override
  final int attendanceScore;
  @override
  final double averageCheckInTime;
  @override
  final int totalCheckIns;
  @override
  final int lateCheckIns;
  @override
  final DateTime periodStart;
  @override
  final DateTime periodEnd;
  final Map<String, dynamic>? _aiRecommendations;
  @override
  Map<String, dynamic>? get aiRecommendations {
    final value = _aiRecommendations;
    if (value == null) return null;
    if (_aiRecommendations is EqualUnmodifiableMapView)
      return _aiRecommendations;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  final int? ranking;

  @override
  String toString() {
    return 'PerformanceMetrics(userId: $userId, attendanceScore: $attendanceScore, averageCheckInTime: $averageCheckInTime, totalCheckIns: $totalCheckIns, lateCheckIns: $lateCheckIns, periodStart: $periodStart, periodEnd: $periodEnd, aiRecommendations: $aiRecommendations, ranking: $ranking)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PerformanceMetricsImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.attendanceScore, attendanceScore) ||
                other.attendanceScore == attendanceScore) &&
            (identical(other.averageCheckInTime, averageCheckInTime) ||
                other.averageCheckInTime == averageCheckInTime) &&
            (identical(other.totalCheckIns, totalCheckIns) ||
                other.totalCheckIns == totalCheckIns) &&
            (identical(other.lateCheckIns, lateCheckIns) ||
                other.lateCheckIns == lateCheckIns) &&
            (identical(other.periodStart, periodStart) ||
                other.periodStart == periodStart) &&
            (identical(other.periodEnd, periodEnd) ||
                other.periodEnd == periodEnd) &&
            const DeepCollectionEquality()
                .equals(other._aiRecommendations, _aiRecommendations) &&
            (identical(other.ranking, ranking) || other.ranking == ranking));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      userId,
      attendanceScore,
      averageCheckInTime,
      totalCheckIns,
      lateCheckIns,
      periodStart,
      periodEnd,
      const DeepCollectionEquality().hash(_aiRecommendations),
      ranking);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PerformanceMetricsImplCopyWith<_$PerformanceMetricsImpl> get copyWith =>
      __$$PerformanceMetricsImplCopyWithImpl<_$PerformanceMetricsImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PerformanceMetricsImplToJson(
      this,
    );
  }
}

abstract class _PerformanceMetrics implements PerformanceMetrics {
  const factory _PerformanceMetrics(
      {required final String userId,
      required final int attendanceScore,
      required final double averageCheckInTime,
      required final int totalCheckIns,
      required final int lateCheckIns,
      required final DateTime periodStart,
      required final DateTime periodEnd,
      final Map<String, dynamic>? aiRecommendations,
      final int? ranking}) = _$PerformanceMetricsImpl;

  factory _PerformanceMetrics.fromJson(Map<String, dynamic> json) =
      _$PerformanceMetricsImpl.fromJson;

  @override
  String get userId;
  @override
  int get attendanceScore;
  @override
  double get averageCheckInTime;
  @override
  int get totalCheckIns;
  @override
  int get lateCheckIns;
  @override
  DateTime get periodStart;
  @override
  DateTime get periodEnd;
  @override
  Map<String, dynamic>? get aiRecommendations;
  @override
  int? get ranking;
  @override
  @JsonKey(ignore: true)
  _$$PerformanceMetricsImplCopyWith<_$PerformanceMetricsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SalesData _$SalesDataFromJson(Map<String, dynamic> json) {
  return _SalesData.fromJson(json);
}

/// @nodoc
mixin _$SalesData {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  DateTime get date => throw _privateConstructorUsedError;
  double get amount => throw _privateConstructorUsedError;
  int get quantity => throw _privateConstructorUsedError;
  String? get productCategory => throw _privateConstructorUsedError;
  Map<String, dynamic>? get metadata => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $SalesDataCopyWith<SalesData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SalesDataCopyWith<$Res> {
  factory $SalesDataCopyWith(SalesData value, $Res Function(SalesData) then) =
      _$SalesDataCopyWithImpl<$Res, SalesData>;
  @useResult
  $Res call(
      {String id,
      String userId,
      DateTime date,
      double amount,
      int quantity,
      String? productCategory,
      Map<String, dynamic>? metadata});
}

/// @nodoc
class _$SalesDataCopyWithImpl<$Res, $Val extends SalesData>
    implements $SalesDataCopyWith<$Res> {
  _$SalesDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? date = null,
    Object? amount = null,
    Object? quantity = null,
    Object? productCategory = freezed,
    Object? metadata = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as double,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as int,
      productCategory: freezed == productCategory
          ? _value.productCategory
          : productCategory // ignore: cast_nullable_to_non_nullable
              as String?,
      metadata: freezed == metadata
          ? _value.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SalesDataImplCopyWith<$Res>
    implements $SalesDataCopyWith<$Res> {
  factory _$$SalesDataImplCopyWith(
          _$SalesDataImpl value, $Res Function(_$SalesDataImpl) then) =
      __$$SalesDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String userId,
      DateTime date,
      double amount,
      int quantity,
      String? productCategory,
      Map<String, dynamic>? metadata});
}

/// @nodoc
class __$$SalesDataImplCopyWithImpl<$Res>
    extends _$SalesDataCopyWithImpl<$Res, _$SalesDataImpl>
    implements _$$SalesDataImplCopyWith<$Res> {
  __$$SalesDataImplCopyWithImpl(
      _$SalesDataImpl _value, $Res Function(_$SalesDataImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? date = null,
    Object? amount = null,
    Object? quantity = null,
    Object? productCategory = freezed,
    Object? metadata = freezed,
  }) {
    return _then(_$SalesDataImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as double,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as int,
      productCategory: freezed == productCategory
          ? _value.productCategory
          : productCategory // ignore: cast_nullable_to_non_nullable
              as String?,
      metadata: freezed == metadata
          ? _value._metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SalesDataImpl implements _SalesData {
  const _$SalesDataImpl(
      {required this.id,
      required this.userId,
      required this.date,
      required this.amount,
      required this.quantity,
      this.productCategory,
      final Map<String, dynamic>? metadata})
      : _metadata = metadata;

  factory _$SalesDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$SalesDataImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  final DateTime date;
  @override
  final double amount;
  @override
  final int quantity;
  @override
  final String? productCategory;
  final Map<String, dynamic>? _metadata;
  @override
  Map<String, dynamic>? get metadata {
    final value = _metadata;
    if (value == null) return null;
    if (_metadata is EqualUnmodifiableMapView) return _metadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  String toString() {
    return 'SalesData(id: $id, userId: $userId, date: $date, amount: $amount, quantity: $quantity, productCategory: $productCategory, metadata: $metadata)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SalesDataImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.productCategory, productCategory) ||
                other.productCategory == productCategory) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      userId,
      date,
      amount,
      quantity,
      productCategory,
      const DeepCollectionEquality().hash(_metadata));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SalesDataImplCopyWith<_$SalesDataImpl> get copyWith =>
      __$$SalesDataImplCopyWithImpl<_$SalesDataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SalesDataImplToJson(
      this,
    );
  }
}

abstract class _SalesData implements SalesData {
  const factory _SalesData(
      {required final String id,
      required final String userId,
      required final DateTime date,
      required final double amount,
      required final int quantity,
      final String? productCategory,
      final Map<String, dynamic>? metadata}) = _$SalesDataImpl;

  factory _SalesData.fromJson(Map<String, dynamic> json) =
      _$SalesDataImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  DateTime get date;
  @override
  double get amount;
  @override
  int get quantity;
  @override
  String? get productCategory;
  @override
  Map<String, dynamic>? get metadata;
  @override
  @JsonKey(ignore: true)
  _$$SalesDataImplCopyWith<_$SalesDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
