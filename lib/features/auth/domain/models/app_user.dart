import 'package:freezed_annotation/freezed_annotation.dart';
import 'app_user_role.dart';

part 'app_user.freezed.dart';
part 'app_user.g.dart';

@freezed
abstract class AppUser with _$AppUser {
  const AppUser._();

  const factory AppUser({
    required String uid,
    required String email,
    required String displayName,
    required String photoUrl,
    required AppUserRole role,
    @Default('active') String status,
  }) = _AppUser;

  factory AppUser.fromJson(Map<String, dynamic> json) =>
      _$AppUserFromJson(json);

  /// Trạng thái người dùng giả lập trống (chưa đăng nhập/Guest)
  factory AppUser.guest() => const AppUser(
    uid: '',
    email: '',
    displayName: 'Khách',
    photoUrl: '',
    role: AppUserRole.guest,
  );
}
