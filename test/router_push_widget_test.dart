import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finalprm/main.dart';
import 'package:finalprm/features/auth/domain/models/app_user.dart';
import 'package:finalprm/core/router/app_router.dart';
import 'package:finalprm/features/auth/presentation/providers/auth_providers.dart';
import 'package:finalprm/features/auth/data/repositories/auth_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'dart:async';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  testWidgets('Clicking register navigates correctly', (tester) async {
    final mockRepo = MockAuthRepository();
    final authStream = StreamController<AppUser>.broadcast();
    when(() => mockRepo.authStateChanges).thenAnswer((_) => authStream.stream);
    
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockRepo)
      ],
      child: const MyApp()
    ));
    
    // Default start should go to ShowroomScreen
    authStream.add(AppUser.guest());
    await tester.pumpAndSettle();
    
    print('Initial Route: /');
    
    final container = ProviderScope.containerOf(tester.element(find.byType(MyApp)));
    final router = container.read(routerProvider);
    
    // Now we are at ShowroomScreen. Let's go to /login
    router.go('/login');
    await tester.pumpAndSettle();
    
    print('Current route before click: ${router.state.uri.path}');
    
    final registerButton = find.text('Đăng ký ngay');
    if (registerButton.evaluate().isNotEmpty) {
      print('Found Đăng ký ngay, tapping...');
      await tester.tap(registerButton);
      await tester.pumpAndSettle();
      print('After tap, route: ${router.state.uri.path}');
    } else {
      print('Could not find Đăng ký ngay');
    }
  });
}
