import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:electra_flutter/features/auth/presentation/widgets/auth_widgets.dart';

void main() {
  group('Authentication Widgets Tests', () {
    testWidgets('NeomorphicTextFormField displays correctly', (WidgetTester tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NeomorphicTextFormField(
              labelText: 'Email',
              hintText: 'Enter your email',
              controller: controller,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: const Icon(Icons.email),
            ),
          ),
        ),
      );

      // Verify the field is displayed
      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.byIcon(Icons.email), findsOneWidget);

      // Test input
      await tester.enterText(find.byType(TextFormField), 'test@example.com');
      expect(controller.text, 'test@example.com');
    });

    testWidgets('NeomorphicTextFormField validation works', (WidgetTester tester) async {
      const fieldKey = Key('test_field');
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              child: NeomorphicTextFormField(
                fieldKey: fieldKey,
                labelText: 'Email',
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Email is required';
                  }
                  return null;
                },
              ),
            ),
          ),
        ),
      );

      // Find the form field
      final formField = tester.widget<TextFormField>(
        find.byKey(fieldKey),
      );

      // Test validation
      expect(formField.validator!(''), 'Email is required');
      expect(formField.validator!('test@example.com'), null);
    });

    testWidgets('NeomorphicElevatedButton displays correctly', (WidgetTester tester) async {
      bool buttonPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NeomorphicElevatedButton(
              onPressed: () => buttonPressed = true,
              child: const Text('Sign In'),
            ),
          ),
        ),
      );

      // Verify button is displayed
      expect(find.byType(NeomorphicElevatedButton), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);

      // Test button press
      await tester.tap(find.byType(NeomorphicElevatedButton));
      expect(buttonPressed, true);
    });

    testWidgets('NeomorphicElevatedButton shows loading state', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NeomorphicElevatedButton(
              isLoading: true,
              child: Text('Sign In'),
            ),
          ),
        ),
      );

      // Verify loading indicator is shown
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Sign In'), findsNothing);
    });

    testWidgets('NeomorphicElevatedButton disabled state', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NeomorphicElevatedButton(
              onPressed: null, // Disabled
              child: Text('Sign In'),
            ),
          ),
        ),
      );

      // Button should still render but be visually disabled
      expect(find.byType(NeomorphicElevatedButton), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets('AnimatedErrorMessage shows and hides correctly', (WidgetTester tester) async {
      String? errorMessage;
      
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: Column(
                  children: [
                    AnimatedErrorMessage(error: errorMessage),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          errorMessage = errorMessage == null 
                              ? 'Test error message' 
                              : null;
                        });
                      },
                      child: const Text('Toggle Error'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );

      // Initially no error
      expect(find.text('Test error message'), findsNothing);

      // Show error
      await tester.tap(find.text('Toggle Error'));
      await tester.pumpAndSettle();
      expect(find.text('Test error message'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);

      // Hide error
      await tester.tap(find.text('Toggle Error'));
      await tester.pumpAndSettle();
      expect(find.text('Test error message'), findsNothing);
    });

    testWidgets('AnimatedSuccessMessage shows correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedSuccessMessage(
              message: 'Success message',
            ),
          ),
        ),
      );

      expect(find.text('Success message'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('BiometricButton displays correctly', (WidgetTester tester) async {
      bool buttonPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BiometricButton(
              onPressed: () => buttonPressed = true,
              label: 'Use Fingerprint',
            ),
          ),
        ),
      );

      // Verify button is displayed
      expect(find.text('Use Fingerprint'), findsOneWidget);
      expect(find.byIcon(Icons.fingerprint), findsOneWidget);

      // Test button press
      await tester.tap(find.byType(BiometricButton));
      await tester.pump();
      expect(buttonPressed, true);
    });

    testWidgets('BiometricButton disabled state', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BiometricButton(
              isEnabled: false,
              label: 'Use Fingerprint',
            ),
          ),
        ),
      );

      // Button should render in disabled state
      expect(find.text('Use Fingerprint'), findsOneWidget);
      expect(find.byIcon(Icons.fingerprint), findsOneWidget);
      
      // Verify disabled styling by checking if onTap is null
      final gestureDetector = tester.widget<GestureDetector>(
        find.byType(GestureDetector),
      );
      expect(gestureDetector.onTap, isNull);
    });

    testWidgets('BiometricButton animation works', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BiometricButton(
              onPressed: () {},
              isEnabled: true,
            ),
          ),
        ),
      );

      // Test tap down animation
      final gesture = await tester.createGesture();
      await gesture.down(tester.getCenter(find.byType(BiometricButton)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 75)); // Half animation
      
      // Animation controller should be running
      expect(find.byType(BiometricButton), findsOneWidget);

      // Complete the gesture
      await gesture.up();
      await tester.pumpAndSettle();
    });

    group('Accessibility Tests', () {
      testWidgets('NeomorphicTextFormField has semantic labels', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: NeomorphicTextFormField(
                labelText: 'Email Address',
                hintText: 'Enter your email',
              ),
            ),
          ),
        );

        final textField = tester.widget<TextFormField>(find.byType(TextFormField));
        expect(textField.decoration!.labelText, 'Email Address');
        expect(textField.decoration!.hintText, 'Enter your email');
      });

      testWidgets('Buttons are accessible', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  NeomorphicElevatedButton(
                    onPressed: () {},
                    child: const Text('Sign In'),
                  ),
                  BiometricButton(
                    onPressed: () {},
                    label: 'Use Biometric',
                  ),
                ],
              ),
            ),
          ),
        );

        // Verify buttons can be found by semantic labels
        expect(find.text('Sign In'), findsOneWidget);
        expect(find.text('Use Biometric'), findsOneWidget);
      });
    });

    group('Form Integration Tests', () {
      testWidgets('Form validation works with custom widgets', (WidgetTester tester) async {
        final formKey = GlobalKey<FormState>();
        final emailController = TextEditingController();
        final passwordController = TextEditingController();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Form(
                key: formKey,
                child: Column(
                  children: [
                    NeomorphicTextFormField(
                      labelText: 'Email',
                      controller: emailController,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Email is required';
                        }
                        return null;
                      },
                    ),
                    NeomorphicTextFormField(
                      labelText: 'Password',
                      controller: passwordController,
                      obscureText: true,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Password is required';
                        }
                        return null;
                      },
                    ),
                    NeomorphicElevatedButton(
                      onPressed: () {
                        formKey.currentState?.validate();
                      },
                      child: const Text('Submit'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        // Test form validation
        await tester.tap(find.text('Submit'));
        await tester.pump();

        expect(find.text('Email is required'), findsOneWidget);
        expect(find.text('Password is required'), findsOneWidget);

        // Fill form and test again
        await tester.enterText(find.byType(TextFormField).first, 'test@example.com');
        await tester.enterText(find.byType(TextFormField).last, 'password123');
        
        await tester.tap(find.text('Submit'));
        await tester.pump();

        expect(find.text('Email is required'), findsNothing);
        expect(find.text('Password is required'), findsNothing);
      });
    });
  });
}