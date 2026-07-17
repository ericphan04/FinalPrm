import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:finalprm/features/auth/data/repositories/auth_repository.dart';
import 'package:finalprm/features/auth/domain/models/app_user.dart';
import 'package:finalprm/features/auth/domain/models/app_user_role.dart';
import 'package:finalprm/features/auth/presentation/providers/auth_providers.dart';
import 'package:finalprm/core/result/result.dart';
import 'package:finalprm/core/error/app_failure.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockAuthRepository;
  late StreamController<AppUser> authStateController;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    authStateController = StreamController<AppUser>.broadcast();
    when(
      () => mockAuthRepository.authStateChanges,
    ).thenAnswer((_) => authStateController.stream);
  });

  tearDown(() {
    authStateController.close();
  });

  test(
    'Initial state is guest and loading, then updates on authStateChanges emissions',
    () async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
        ],
      );
      addTearDown(container.dispose);

      // Should start with guest and loading flag enabled by controller
      var state = container.read(authControllerProvider);
      expect(state.user.role, AppUserRole.guest);
      expect(state.isLoading, isTrue);

      final appUser = AppUser(
        uid: 'uid-1',
        email: 'user@example.com',
        displayName: 'Shoe User',
        photoUrl: '',
        role: AppUserRole.user,
      );

      authStateController.add(appUser);
      await Future.delayed(Duration.zero);

      state = container.read(authControllerProvider);
      expect(state.user, appUser);
      expect(state.isLoading, isFalse);
    },
  );

  test(
    'signIn changes state to success when repository call succeeds',
    () async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
        ],
      );
      addTearDown(container.dispose);

      final appUser = AppUser(
        uid: 'uid-1',
        email: 'user@example.com',
        displayName: 'Shoe User',
        photoUrl: '',
        role: AppUserRole.user,
      );

      when(
        () => mockAuthRepository.signInWithEmailAndPassword(
          email: 'user@example.com',
          password: 'password123',
        ),
      ).thenAnswer((_) async => Success(appUser));

      final controller = container.read(authControllerProvider.notifier);
      await controller.signIn(
        email: 'user@example.com',
        password: 'password123',
      );

      final state = container.read(authControllerProvider);
      expect(state.user, appUser);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNull);
    },
  );

  test('signIn sets error message when repository call fails', () async {
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(mockAuthRepository)],
    );
    addTearDown(container.dispose);

    when(
      () => mockAuthRepository.signInWithEmailAndPassword(
        email: 'wrong@example.com',
        password: 'wrongpassword',
      ),
    ).thenAnswer(
      (_) async => const Failure(
        AppFailure(
          code: 'wrong-password',
          message: 'Mật khẩu đăng nhập không chính xác.',
        ),
      ),
    );

    final controller = container.read(authControllerProvider.notifier);
    await controller.signIn(
      email: 'wrong@example.com',
      password: 'wrongpassword',
    );

    final state = container.read(authControllerProvider);
    expect(state.isLoading, isFalse);
    expect(state.errorMessage, 'Mật khẩu đăng nhập không chính xác.');
  });
}
