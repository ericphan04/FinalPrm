import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('Clicking register navigates correctly', (tester) async {
    String? capturedPath;
    final router = GoRouter(
      initialLocation: '/login',
      redirect: (context, state) {
        capturedPath = state.uri.path;
        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => Scaffold(
            body: ElevatedButton(
              onPressed: () => context.push('/register'),
              child: const Text('Đăng ký ngay'),
            ),
          ),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) =>
              const Scaffold(body: Text('Register Screen')),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    final registerButton = find.text('Đăng ký ngay');
    expect(registerButton, findsOneWidget);
    await tester.tap(registerButton);
    await tester.pumpAndSettle();

    expect(capturedPath, '/register');
  });
}
