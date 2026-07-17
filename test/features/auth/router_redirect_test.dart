import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:finalprm/core/router/app_router.dart';
import 'package:finalprm/features/auth/data/repositories/auth_repository.dart';
import 'package:finalprm/features/auth/domain/models/app_user.dart';
import 'package:finalprm/features/auth/domain/models/app_user_role.dart';
import 'package:finalprm/features/auth/presentation/providers/auth_providers.dart';

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

  Widget buildTestApp(ProviderContainer container) {
    return UncontrolledProviderScope(
      container: container,
      child: Consumer(
        builder: (context, ref, _) {
          final router = ref.watch(routerProvider);
          return MaterialApp.router(routerConfig: router);
        },
      ),
    );
  }

  testWidgets('Guest trying to access /profile is redirected to /login', (
    WidgetTester tester,
  ) async {
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(mockAuthRepository)],
    );
    addTearDown(container.dispose);

    // Initial state is guest
    authStateController.add(AppUser.guest());

    await tester.pumpWidget(buildTestApp(container));
    await tester.pump();

    final router = container.read(routerProvider);
    router.go('/profile');
    await tester.pump();

    expect(router.state.matchedLocation, '/login');
  });

  testWidgets(
    'Authenticated user trying to access /login is redirected to home (/)',
    (WidgetTester tester) async {
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

      await tester.pumpWidget(buildTestApp(container));

      // Emit authenticated user and let state fully propagate
      authStateController.add(appUser);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Trigger navigation to login
      final router = container.read(routerProvider);
      router.go('/login');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Should redirect back to home
      expect(router.state.matchedLocation, '/');
    },
  );
}
