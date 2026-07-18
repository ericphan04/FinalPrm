// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'store_profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$StoreProfile {

 String get id; String get name; String get phone; String get description; String get address; String get logoUrl; DateTime get createdAt;
/// Create a copy of StoreProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StoreProfileCopyWith<StoreProfile> get copyWith => _$StoreProfileCopyWithImpl<StoreProfile>(this as StoreProfile, _$identity);

  /// Serializes this StoreProfile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StoreProfile&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.description, description) || other.description == description)&&(identical(other.address, address) || other.address == address)&&(identical(other.logoUrl, logoUrl) || other.logoUrl == logoUrl)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,phone,description,address,logoUrl,createdAt);

@override
String toString() {
  return 'StoreProfile(id: $id, name: $name, phone: $phone, description: $description, address: $address, logoUrl: $logoUrl, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $StoreProfileCopyWith<$Res>  {
  factory $StoreProfileCopyWith(StoreProfile value, $Res Function(StoreProfile) _then) = _$StoreProfileCopyWithImpl;
@useResult
$Res call({
 String id, String name, String phone, String description, String address, String logoUrl, DateTime createdAt
});




}
/// @nodoc
class _$StoreProfileCopyWithImpl<$Res>
    implements $StoreProfileCopyWith<$Res> {
  _$StoreProfileCopyWithImpl(this._self, this._then);

  final StoreProfile _self;
  final $Res Function(StoreProfile) _then;

/// Create a copy of StoreProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? phone = null,Object? description = null,Object? address = null,Object? logoUrl = null,Object? createdAt = null,}) {
  return _then(StoreProfile(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,logoUrl: null == logoUrl ? _self.logoUrl : logoUrl // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [StoreProfile].
extension StoreProfilePatterns on StoreProfile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StoreProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StoreProfile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StoreProfile value)  $default,){
final _that = this;
switch (_that) {
case _StoreProfile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StoreProfile value)?  $default,){
final _that = this;
switch (_that) {
case _StoreProfile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String phone,  String description,  String address,  String logoUrl,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StoreProfile() when $default != null:
return $default(_that.id,_that.name,_that.phone,_that.description,_that.address,_that.logoUrl,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String phone,  String description,  String address,  String logoUrl,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _StoreProfile():
return $default(_that.id,_that.name,_that.phone,_that.description,_that.address,_that.logoUrl,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String phone,  String description,  String address,  String logoUrl,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _StoreProfile() when $default != null:
return $default(_that.id,_that.name,_that.phone,_that.description,_that.address,_that.logoUrl,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StoreProfile implements StoreProfile {
  const _StoreProfile({required this.id, required this.name, required this.phone, required this.description, required this.address, this.logoUrl = '', required this.createdAt});
  factory _StoreProfile.fromJson(Map<String, dynamic> json) => _$StoreProfileFromJson(json);

@override final  String id;
@override final  String name;
@override final  String phone;
@override final  String description;
@override final  String address;
@override@JsonKey() final  String logoUrl;
@override final  DateTime createdAt;

/// Create a copy of StoreProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StoreProfileCopyWith<_StoreProfile> get copyWith => __$StoreProfileCopyWithImpl<_StoreProfile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StoreProfileToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StoreProfile&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.description, description) || other.description == description)&&(identical(other.address, address) || other.address == address)&&(identical(other.logoUrl, logoUrl) || other.logoUrl == logoUrl)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,phone,description,address,logoUrl,createdAt);

@override
String toString() {
  return 'StoreProfile(id: $id, name: $name, phone: $phone, description: $description, address: $address, logoUrl: $logoUrl, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$StoreProfileCopyWith<$Res> implements $StoreProfileCopyWith<$Res> {
  factory _$StoreProfileCopyWith(_StoreProfile value, $Res Function(_StoreProfile) _then) = __$StoreProfileCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String phone, String description, String address, String logoUrl, DateTime createdAt
});




}
/// @nodoc
class __$StoreProfileCopyWithImpl<$Res>
    implements _$StoreProfileCopyWith<$Res> {
  __$StoreProfileCopyWithImpl(this._self, this._then);

  final _StoreProfile _self;
  final $Res Function(_StoreProfile) _then;

/// Create a copy of StoreProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? phone = null,Object? description = null,Object? address = null,Object? logoUrl = null,Object? createdAt = null,}) {
  return _then(_StoreProfile(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,logoUrl: null == logoUrl ? _self.logoUrl : logoUrl // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
