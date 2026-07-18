// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'seller_application.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SellerApplication {

 String get id; String get storeName; String get phone; String get description; String get address; SellerApplicationStatus get status; String? get rejectReason; DateTime get createdAt; DateTime? get updatedAt;
/// Create a copy of SellerApplication
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SellerApplicationCopyWith<SellerApplication> get copyWith => _$SellerApplicationCopyWithImpl<SellerApplication>(this as SellerApplication, _$identity);

  /// Serializes this SellerApplication to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SellerApplication&&(identical(other.id, id) || other.id == id)&&(identical(other.storeName, storeName) || other.storeName == storeName)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.description, description) || other.description == description)&&(identical(other.address, address) || other.address == address)&&(identical(other.status, status) || other.status == status)&&(identical(other.rejectReason, rejectReason) || other.rejectReason == rejectReason)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,storeName,phone,description,address,status,rejectReason,createdAt,updatedAt);

@override
String toString() {
  return 'SellerApplication(id: $id, storeName: $storeName, phone: $phone, description: $description, address: $address, status: $status, rejectReason: $rejectReason, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $SellerApplicationCopyWith<$Res>  {
  factory $SellerApplicationCopyWith(SellerApplication value, $Res Function(SellerApplication) _then) = _$SellerApplicationCopyWithImpl;
@useResult
$Res call({
 String id, String storeName, String phone, String description, String address, SellerApplicationStatus status, String? rejectReason, DateTime createdAt, DateTime? updatedAt
});




}
/// @nodoc
class _$SellerApplicationCopyWithImpl<$Res>
    implements $SellerApplicationCopyWith<$Res> {
  _$SellerApplicationCopyWithImpl(this._self, this._then);

  final SellerApplication _self;
  final $Res Function(SellerApplication) _then;

/// Create a copy of SellerApplication
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? storeName = null,Object? phone = null,Object? description = null,Object? address = null,Object? status = null,Object? rejectReason = freezed,Object? createdAt = null,Object? updatedAt = freezed,}) {
  return _then(SellerApplication(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,storeName: null == storeName ? _self.storeName : storeName // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SellerApplicationStatus,rejectReason: freezed == rejectReason ? _self.rejectReason : rejectReason // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [SellerApplication].
extension SellerApplicationPatterns on SellerApplication {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SellerApplication value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SellerApplication() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SellerApplication value)  $default,){
final _that = this;
switch (_that) {
case _SellerApplication():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SellerApplication value)?  $default,){
final _that = this;
switch (_that) {
case _SellerApplication() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String storeName,  String phone,  String description,  String address,  SellerApplicationStatus status,  String? rejectReason,  DateTime createdAt,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SellerApplication() when $default != null:
return $default(_that.id,_that.storeName,_that.phone,_that.description,_that.address,_that.status,_that.rejectReason,_that.createdAt,_that.updatedAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String storeName,  String phone,  String description,  String address,  SellerApplicationStatus status,  String? rejectReason,  DateTime createdAt,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _SellerApplication():
return $default(_that.id,_that.storeName,_that.phone,_that.description,_that.address,_that.status,_that.rejectReason,_that.createdAt,_that.updatedAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String storeName,  String phone,  String description,  String address,  SellerApplicationStatus status,  String? rejectReason,  DateTime createdAt,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _SellerApplication() when $default != null:
return $default(_that.id,_that.storeName,_that.phone,_that.description,_that.address,_that.status,_that.rejectReason,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SellerApplication implements SellerApplication {
  const _SellerApplication({required this.id, required this.storeName, required this.phone, required this.description, required this.address, this.status = SellerApplicationStatus.pending, this.rejectReason, required this.createdAt, this.updatedAt});
  factory _SellerApplication.fromJson(Map<String, dynamic> json) => _$SellerApplicationFromJson(json);

@override final  String id;
@override final  String storeName;
@override final  String phone;
@override final  String description;
@override final  String address;
@override@JsonKey() final  SellerApplicationStatus status;
@override final  String? rejectReason;
@override final  DateTime createdAt;
@override final  DateTime? updatedAt;

/// Create a copy of SellerApplication
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SellerApplicationCopyWith<_SellerApplication> get copyWith => __$SellerApplicationCopyWithImpl<_SellerApplication>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SellerApplicationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SellerApplication&&(identical(other.id, id) || other.id == id)&&(identical(other.storeName, storeName) || other.storeName == storeName)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.description, description) || other.description == description)&&(identical(other.address, address) || other.address == address)&&(identical(other.status, status) || other.status == status)&&(identical(other.rejectReason, rejectReason) || other.rejectReason == rejectReason)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,storeName,phone,description,address,status,rejectReason,createdAt,updatedAt);

@override
String toString() {
  return 'SellerApplication(id: $id, storeName: $storeName, phone: $phone, description: $description, address: $address, status: $status, rejectReason: $rejectReason, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$SellerApplicationCopyWith<$Res> implements $SellerApplicationCopyWith<$Res> {
  factory _$SellerApplicationCopyWith(_SellerApplication value, $Res Function(_SellerApplication) _then) = __$SellerApplicationCopyWithImpl;
@override @useResult
$Res call({
 String id, String storeName, String phone, String description, String address, SellerApplicationStatus status, String? rejectReason, DateTime createdAt, DateTime? updatedAt
});




}
/// @nodoc
class __$SellerApplicationCopyWithImpl<$Res>
    implements _$SellerApplicationCopyWith<$Res> {
  __$SellerApplicationCopyWithImpl(this._self, this._then);

  final _SellerApplication _self;
  final $Res Function(_SellerApplication) _then;

/// Create a copy of SellerApplication
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? storeName = null,Object? phone = null,Object? description = null,Object? address = null,Object? status = null,Object? rejectReason = freezed,Object? createdAt = null,Object? updatedAt = freezed,}) {
  return _then(_SellerApplication(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,storeName: null == storeName ? _self.storeName : storeName // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SellerApplicationStatus,rejectReason: freezed == rejectReason ? _self.rejectReason : rejectReason // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
