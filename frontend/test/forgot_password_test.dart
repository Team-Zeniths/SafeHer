import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:frontend/features/auth/providers/auth_provider.dart';
import 'package:frontend/features/auth/screens/forgot_password_screen.dart';

void main() {
  testWidgets('ForgotPasswordScreen renders fields and button', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(),
        child: const MaterialApp(
          home: ForgotPasswordScreen(initialEmail: 'test@example.com'),
        ),
      ),
    );

    // Verify email field is prefilled
    expect(find.text('test@example.com'), findsOneWidget);
    expect(find.text('Reset Password'), findsOneWidget);
    expect(find.text('New password'), findsOneWidget);
    expect(find.text('Confirm new password'), findsOneWidget);
    expect(find.text('Save New Password'), findsOneWidget);

    // Trigger validation error on empty passwords
    await tester.tap(find.text('Save New Password'));
    await tester.pumpAndSettle();

    expect(find.text('Password is required'), findsOneWidget);
  });

  testWidgets('ForgotPasswordScreen validates password mismatch', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(),
        child: const MaterialApp(
          home: ForgotPasswordScreen(initialEmail: 'test@example.com'),
        ),
      ),
    );

    // Enter valid new password and non-matching confirm password
    await tester.enterText(find.widgetWithText(TextFormField, '').first, 'ValidPass1');
    await tester.enterText(find.widgetWithText(TextFormField, '').last, 'MismatchPass2');
    await tester.tap(find.text('Save New Password'));
    await tester.pumpAndSettle();

    expect(find.text('Passwords do not match'), findsOneWidget);
  });
}

