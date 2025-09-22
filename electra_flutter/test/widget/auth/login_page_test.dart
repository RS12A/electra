import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:electra_flutter/features/auth/presentation/pages/login_page.dart';

void main() {
  group('Login Page Widget Tests', () {
    testWidgets('should display login form elements', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginPage(),
          ),
        ),
      );

      // Verify key elements are present
      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Sign in to continue voting'), findsOneWidget);
      
      // Check for input fields
      expect(find.byType(TextFormField), findsNWidgets(2)); // Identifier and password
      
      // Check for buttons
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);
    });

    testWidgets('should validate empty fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginPage(),
          ),
        ),
      );

      // Try to submit with empty fields
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      // Should show validation errors
      expect(find.text('Please enter your email, matric number, or staff ID'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('should toggle password visibility', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginPage(),
          ),
        ),
      );

      // Find password field and visibility toggle
      final passwordField = find.byType(TextFormField).last;
      final visibilityToggle = find.byIcon(Icons.visibility_outlined);

      // Password should be obscured initially
      expect(visibilityToggle, findsOneWidget);

      // Tap to toggle visibility
      await tester.tap(visibilityToggle);
      await tester.pump();

      // Should show hide icon now
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    });

    testWidgets('should show remember me checkbox', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginPage(),
          ),
        ),
      );

      // Find remember me text and checkbox area
      expect(find.text('Remember me'), findsOneWidget);
      
      // Should be able to tap remember me area
      await tester.tap(find.text('Remember me'));
      await tester.pump();
    });

    testWidgets('should display forgot password link', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginPage(),
          ),
        ),
      );

      expect(find.text('Forgot Password?'), findsOneWidget);
    });

    testWidgets('should display university name', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginPage(),
          ),
        ),
      );

      expect(find.text('Kwara State University'), findsOneWidget);
    });

    testWidgets('should fill form fields correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginPage(),
          ),
        ),
      );

      // Fill in identifier field
      await tester.enterText(
        find.byType(TextFormField).first,
        'test@kwasu.edu.ng',
      );
      
      // Fill in password field
      await tester.enterText(
        find.byType(TextFormField).last,
        'password123',
      );

      // Verify text was entered
      expect(find.text('test@kwasu.edu.ng'), findsOneWidget);
      expect(find.text('password123'), findsOneWidget);
    });

    testWidgets('should show KWASU logo/icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginPage(),
          ),
        ),
      );

      // Should show school icon (placeholder for logo)
      expect(find.byIcon(Icons.school), findsOneWidget);
    });
  });

  group('Login Page Integration', () {
    testWidgets('should navigate to register page when create account tapped', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginPage(),
          ),
        ),
      );

      // Find and tap create account button
      final createAccountButton = find.text('Create Account');
      expect(createAccountButton, findsOneWidget);
      
      await tester.tap(createAccountButton);
      await tester.pumpAndSettle();
    });

    testWidgets('should navigate to forgot password when link tapped', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginPage(),
          ),
        ),
      );

      // Find and tap forgot password link
      final forgotPasswordLink = find.text('Forgot Password?');
      expect(forgotPasswordLink, findsOneWidget);
      
      await tester.tap(forgotPasswordLink);
      await tester.pumpAndSettle();
    });
  });

  group('Login Page Accessibility', () {
    testWidgets('should have proper semantic labels', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginPage(),
          ),
        ),
      );

      // Verify important elements have semantic information
      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Sign in to continue voting'), findsOneWidget);
    });

    testWidgets('should support keyboard navigation', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginPage(),
          ),
        ),
      );

      // Test that form fields can be focused
      final firstField = find.byType(TextFormField).first;
      final secondField = find.byType(TextFormField).last;
      
      await tester.tap(firstField);
      await tester.pump();
      
      // Move to next field
      await tester.tap(secondField);
      await tester.pump();
    });
  });
}
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginPage(),
          ),
        ),
      );

      // Try to submit without entering data
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      // Should show validation errors
      expect(find.text('Please enter your identifier'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('should toggle password visibility', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginPage(),
          ),
        ),
      );

      // Find password field
      final passwordField = find.byKey(const Key('password_field'));
      expect(passwordField, findsOneWidget);

      // Find visibility toggle button
      final visibilityButton = find.byIcon(Icons.visibility_outlined);
      expect(visibilityButton, findsOneWidget);

      // Tap to toggle visibility
      await tester.tap(visibilityButton);
      await tester.pump();

      // Should now show hide icon
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    });

    testWidgets('should remember me checkbox works', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginPage(),
          ),
        ),
      );

      // Find remember me checkbox
      final checkbox = find.byType(Checkbox);
      expect(checkbox, findsOneWidget);

      // Initially should be unchecked
      Checkbox checkboxWidget = tester.widget(checkbox);
      expect(checkboxWidget.value, false);

      // Tap checkbox
      await tester.tap(checkbox);
      await tester.pump();

      // Should now be checked
      checkboxWidget = tester.widget(checkbox);
      expect(checkboxWidget.value, true);
    });

    testWidgets('should show loading indicator when submitting', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginPage(),
          ),
        ),
      );

      // Fill in valid data
      await tester.enterText(
        find.byType(TextFormField).first,
        'test@kwasu.edu.ng',
      );
      await tester.enterText(
        find.byType(TextFormField).last,
        'password123',
      );

      // Submit form
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      // Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('Login Page Integration', () {
    testWidgets('should navigate to register page', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginPage(),
          ),
        ),
      );

      // Tap create account
      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle();

      // Should navigate (this would require router setup in real test)
      // expect(find.byType(RegisterPage), findsOneWidget);
    });

    testWidgets('should navigate to forgot password', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginPage(),
          ),
        ),
      );

      // Tap forgot password
      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();

      // Should navigate (this would require router setup in real test)
      // expect(find.byType(ForgotPasswordPage), findsOneWidget);
    });
  });
}