import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart' hide Result;
import '../../../../core/error/app_failure.dart';
import '../../../../core/error/error_handler.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/result/result.dart';
import '../../domain/models/app_user.dart';
import '../../domain/models/app_user_role.dart';
import 'auth_repository.dart';

/// Triển khai [AuthRepository] kết nối trực tiếp với Firebase Auth và Firestore.
class FirebaseAuthRepository implements AuthRepository {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  FirebaseAuthRepository({
    firebase_auth.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  }) : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<AppUser> get authStateChanges {
    return _firebaseAuth.idTokenChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) {
        return AppUser.guest();
      }
      return await _mapFirebaseUserToAppUser(firebaseUser);
    });
  }

  @override
  Future<Result<AppUser>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        return const Failure(
          AppFailure(
            code: 'auth_null_user',
            message: 'Không tìm thấy thông tin người dùng sau khi đăng nhập.',
          ),
        );
      }

      // Kiểm tra trạng thái tài khoản trong Firestore
      final userDoc =
          await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final status = userDoc.data()?['status'] as String?;
        if (status == 'locked' || status == 'banned' || status == 'disabled' || status == 'blocked') {
          // Tài khoản bị khóa → đăng xuất ngay và trả về lỗi
          await _firebaseAuth.signOut();
          AppLogger.warning(
            'Tài khoản bị khóa: uid=${user.uid}, status=$status',
          );
          return Failure(
            AppFailure(
              code: 'account_locked',
              message:
                  'Tài khoản của bạn đã bị khóa bởi quản trị viên. Vui lòng liên hệ hỗ trợ.',
            ),
          );
        }
      }

      final appUser = await _mapFirebaseUserToAppUser(user);
      AppLogger.info(
        'Đăng nhập thành công: email=${appUser.email}, role=${appUser.role}',
      );
      return Success(appUser);
    } catch (e) {
      AppLogger.error('Lỗi đăng nhập', e);
      return Failure(ErrorHandler.handle(e));
    }
  }

  @override
  Future<Result<AppUser>> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        return const Failure(
          AppFailure(
            code: 'auth_null_user',
            message: 'Không thể tạo tài khoản mới.',
          ),
        );
      }

      // Cập nhật displayName trong Auth profile
      await user.updateDisplayName(displayName);

      // Tự động phân tích role dựa trên email đăng ký để gán role ban đầu cho tiện test
      String roleString = 'user';
      final emailLower = email.toLowerCase().trim();
      if (emailLower.startsWith('admin') || emailLower.contains('admin@')) {
        roleString = 'admin';
      } else if (emailLower.startsWith('seller') ||
          emailLower.contains('seller@')) {
        roleString = 'seller';
      } else if (emailLower.startsWith('guest') ||
          emailLower.contains('guest@')) {
        roleString = 'guest';
      }

      // Tạo hồ sơ người dùng tương ứng trong Firestore
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': email,
        'displayName': displayName,
        'phone': '',
        'avatarUrl': '',
        'role': roleString,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Làm mới Firebase Auth user state để đồng bộ displayName
      await user.reload();
      final updatedUser = _firebaseAuth.currentUser ?? user;

      final appUser = await _mapFirebaseUserToAppUser(updatedUser);
      AppLogger.info('Đăng ký tài khoản thành công: email=${appUser.email}');
      return Success(appUser);
    } catch (e) {
      AppLogger.error('Lỗi đăng ký tài khoản', e);
      return Failure(ErrorHandler.handle(e));
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await _firebaseAuth.signOut();
      AppLogger.info('Đăng xuất thành công');
      return const Success(null);
    } catch (e) {
      AppLogger.error('Lỗi đăng xuất', e);
      return Failure(ErrorHandler.handle(e));
    }
  }

  @override
  Future<Result<void>> sendPasswordResetEmail({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      AppLogger.info('Đã gửi email khôi phục mật khẩu tới: email=$email');
      return const Success(null);
    } catch (e) {
      AppLogger.error('Lỗi gửi email khôi phục mật khẩu', e);
      return Failure(ErrorHandler.handle(e));
    }
  }

  @override
  Future<Result<AppUser>> getCurrentUser() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        return Success(AppUser.guest());
      }
      final appUser = await _mapFirebaseUserToAppUser(user);
      return Success(appUser);
    } catch (e) {
      AppLogger.error('Lỗi lấy thông tin người dùng hiện tại', e);
      return Failure(ErrorHandler.handle(e));
    }
  }

  @override
  Future<Result<void>> forceRefreshIdToken() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await user.getIdTokenResult(true);
        AppLogger.info('Force refresh ID Token thành công cho uid=${user.uid}');
        return const Success(null);
      }
      return const Failure(
        AppFailure(
          code: 'no_authenticated_user',
          message: 'Không tìm thấy phiên đăng nhập hoạt động.',
        ),
      );
    } catch (e) {
      AppLogger.error('Lỗi force refresh ID Token', e);
      return Failure(ErrorHandler.handle(e));
    }
  }

  /// Suy luận role từ email (dùng cho tài khoản seed/test)
  String _inferRoleFromEmail(String email) {
    final emailLower = email.toLowerCase().trim();
    if (emailLower.startsWith('admin') || emailLower.contains('admin@')) {
      return 'admin';
    } else if (emailLower.startsWith('seller') ||
        emailLower.contains('seller@')) {
      return 'seller';
    }
    return 'user';
  }

  /// Map Firebase User thành AppUser nội bộ kèm theo lấy thông tin role từ Firestore.
  /// Nếu document Firestore chưa tồn tại cho UID này, tự động tạo mới với role
  /// suy luận từ email để đảm bảo Firestore Security Rules hoạt động đúng.
  Future<AppUser> _mapFirebaseUserToAppUser(
    firebase_auth.User firebaseUser,
  ) async {
    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();
      AppUserRole role = AppUserRole.user;

      String status = 'active';
      if (userDoc.exists) {
        final data = userDoc.data();
        if (data != null) {
          final roleClaim =
              data['role'] as String? ?? data['roleMirror'] as String?;
          role = _parseRole(roleClaim);
          status = data['status'] as String? ?? 'active';
        }
      } else {
        // Document Firestore chưa tồn tại cho UID này
        // → Tạo trực tiếp với role suy luận từ email
        final inferredRole = _inferRoleFromEmail(firebaseUser.email ?? '');
        role = _parseRole(inferredRole);
        try {
          await _firestore.collection('users').doc(firebaseUser.uid).set({
            'uid': firebaseUser.uid,
            'email': firebaseUser.email ?? '',
            'displayName': firebaseUser.displayName ?? '',
            'avatarUrl': firebaseUser.photoURL ?? '',
            'role': inferredRole,
            'roleMirror': inferredRole,
            'status': 'active',
            'createdAt': FieldValue.serverTimestamp(),
          });
          AppLogger.info(
            'Tự động tạo document Firestore cho uid=${firebaseUser.uid}, role=$inferredRole',
          );
        } catch (writeErr) {
          AppLogger.error(
            'Không thể tạo document Firestore cho user',
            writeErr,
          );
        }
      }

      return AppUser(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        displayName: firebaseUser.displayName ?? '',
        photoUrl: firebaseUser.photoURL ?? '',
        role: role,
        status: status,
      );
    } catch (e) {
      AppLogger.error('Lỗi ánh xạ Firebase User sang AppUser', e);
      return AppUser(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        displayName: firebaseUser.displayName ?? '',
        photoUrl: firebaseUser.photoURL ?? '',
        role: AppUserRole.user,
        status: 'active',
      );
    }
  }

  AppUserRole _parseRole(String? roleClaim) {
    if (roleClaim == null) return AppUserRole.user;
    switch (roleClaim.toLowerCase()) {
      case 'admin':
        return AppUserRole.admin;
      case 'seller':
        return AppUserRole.seller;
      case 'guest':
        return AppUserRole.guest;
      case 'user':
      default:
        return AppUserRole.user;
    }
  }
}
