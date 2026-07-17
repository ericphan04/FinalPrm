import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('Test state.uri.path on push', (tester) async {
    String? capturedPath;
    final router = GoRouter(
      initialLocation: '/login',
      redirect: (context, state) {
        print('Redirect evaluated for: ${state.uri.path}, matchedLocation: ${state.matchedLocation}');
        capturedPath = state.uri.path;
        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => Scaffold(
            body: ElevatedButton(
              onPressed: () => context.push('/register'),
              child: const Text('Push'),
            ),
          ),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const Scaffold(body: Text('Register')),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    
    await tester.tap(find.text('Push'));
    await tester.pumpAndSettle();
    
    expect(capturedPath, '/register');
  });
}
