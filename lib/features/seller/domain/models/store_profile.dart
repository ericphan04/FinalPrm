import 'package:freezed_annotation/freezed_annotation.dart';

part 'store_profile.freezed.dart';
part 'store_profile.g.dart';

@freezed
abstract class StoreProfile with _$StoreProfile {
  const factory StoreProfile({
    required String id,
    required String name,
    required String phone,
    required String description,
    required String address,
    @Default('') String logoUrl,
    required DateTime createdAt,
  }) = _StoreProfile;

  factory StoreProfile.fromJson(Map<String, dynamic> json) =>
      _$StoreProfileFromJson(json);
}
