/// Các vai trò người dùng trong hệ thống Marketplace.
enum AppUserRole {
  guest,
  user,
  seller,
  admin;

  String get nameVi {
    switch (this) {
      case AppUserRole.guest:
        return 'Khách';
      case AppUserRole.user:
        return 'Khách hàng';
      case AppUserRole.seller:
        return 'Người bán';
      case AppUserRole.admin:
        return 'Quản trị viên';
    }
  }
}
