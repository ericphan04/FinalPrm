import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finalprm/core/widgets/app_button.dart';
import 'package:finalprm/core/widgets/app_text_field.dart';
import 'package:finalprm/features/profile/domain/models/user_profile.dart';

void main() {
  group('UserProfile Model Tests', () {
    test('copyWith updates fields correctly', () {
      const profile = UserProfile(
        uid: '123',
        email: 'test@example.com',
        displayName: 'Old Name',
        phone: '1234567890',
        avatarUrl: 'old_url',
      );

      final updated = profile.copyWith(
        displayName: 'New Name',
        phone: '0987654321',
      );

      expect(updated.uid, '123');
      expect(updated.email, 'test@example.com');
      expect(updated.displayName, 'New Name');
      expect(updated.phone, '0987654321');
      expect(updated.avatarUrl, 'old_url');
    });

    test('Serialization and deserialization work', () {
      final now = DateTime.now();
      final profile = UserProfile(
        uid: '123',
        email: 'test@example.com',
        displayName: 'Test User',
        phone: '1234567890',
        avatarUrl: 'url',
        updatedAt: now,
      );

      final map = profile.toMap();
      final fromMap = UserProfile.fromMap(map);

      expect(fromMap.uid, profile.uid);
      expect(fromMap.email, profile.email);
      expect(fromMap.displayName, profile.displayName);
      expect(fromMap.phone, profile.phone);
      expect(fromMap.avatarUrl, profile.avatarUrl);
      // Compare ISO strings due to datetime precision in serialization
      expect(fromMap.updatedAt?.toIso8601String(), now.toIso8601String());
    });
  });

  group('AppButton Widget Tests', () {
    testWidgets('AppButton renders text and triggers callback', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              text: 'Tap Me',
              onPressed: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      // Verify text renders
      expect(find.text('Tap Me'), findsOneWidget);

      // Tap button and verify callback triggers
      await tester.tap(find.text('Tap Me'));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('AppButton in loading state shows spinner and does not tap', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              text: 'Tap Me',
              isLoading: true,
              onPressed: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      // Verify spinner exists
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // Text is hidden during loading in our AppButton
      expect(find.text('Tap Me'), findsNothing);

      // Tap button and verify callback is NOT triggered
      await tester.tap(find.byType(CircularProgressIndicator));
      await tester.pump();

      expect(tapped, isFalse);
    });

    testWidgets('Disabled AppButton does not trigger callback', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              text: 'Tap Me',
              isDisabled: true,
              onPressed: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tap Me'));
      await tester.pump();

      expect(tapped, isFalse);
    });
  });

  group('AppTextField Widget Tests', () {
    testWidgets('AppTextField updates text controller', (WidgetTester tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppTextField(
              controller: controller,
              labelText: 'Name',
              hintText: 'Enter name',
            ),
          ),
        ),
      );

      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Enter name'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), 'John Doe');
      expect(controller.text, 'John Doe');
    });

    testWidgets('AppTextField toggle password visibility works', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppTextField(
              labelText: 'Password',
              isPassword: true,
            ),
          ),
        ),
      );

      // Initially obscured (value is true)
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.obscureText, isTrue);

      // Find eye icon and tap
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
      await tester.tap(find.byIcon(Icons.visibility_off_outlined));
      await tester.pump();

      // Should toggle state and show visibility icon
      final textFieldToggled = tester.widget<TextField>(find.byType(TextField));
      expect(textFieldToggled.obscureText, isFalse);
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    });
  });
}
