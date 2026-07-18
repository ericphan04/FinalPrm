import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finalprm/features/auth/presentation/views/register_view.dart';
import 'package:finalprm/features/auth/presentation/providers/auth_providers.dart';
import 'package:finalprm/features/auth/data/repositories/auth_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  testWidgets('RegisterScreen renders correctly', (tester) async {
    final mockRepo = MockAuthRepository();
    when(
      () => mockRepo.authStateChanges,
    ).thenAnswer((_) => const Stream.empty());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(mockRepo)],
        child: const MaterialApp(home: RegisterScreen()),
      ),
    );

    await tester.pump();

    expect(find.text('Tạo tài khoản mới'), findsOneWidget);
  });
}
