import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:electra_flutter/core/storage/storage_service.dart';
import 'package:electra_flutter/core/theme/theme_controller.dart';
import 'package:electra_flutter/core/theme/theme_config.dart';

import 'theme_controller_test.mocks.dart';

@GenerateMocks([StorageService])
void main() {
  late ThemeController themeController;
  late MockStorageService mockStorageService;

  setUp(() {
    mockStorageService = MockStorageService();
    themeController = ThemeController(mockStorageService);
  });

  group('ThemeController', () {
    test('should initialize with KWASU theme by default', () {
      expect(themeController.currentTheme, AppThemeMode.kwasu);
      expect(themeController.initialized, false);
    });

    test('should initialize with persisted theme', () async {
      // Arrange
      when(mockStorageService.readSecure('app_theme_mode'))
          .thenAnswer((_) async => '1'); // Light theme index
      when(mockStorageService.readSecure('accessibility_settings'))
          .thenAnswer((_) async => 'false,false,1.0');

      // Act
      await themeController.initialize();

      // Assert
      expect(themeController.currentTheme, AppThemeMode.light);
      expect(themeController.initialized, true);
    });

    test('should change theme and persist it', () async {
      // Arrange
      when(mockStorageService.readSecure(any))
          .thenAnswer((_) async => null);
      when(mockStorageService.storeSecure(any, any))
          .thenAnswer((_) async {});

      await themeController.initialize();

      // Act
      await themeController.changeTheme(AppThemeMode.dark);

      // Assert
      expect(themeController.currentTheme, AppThemeMode.dark);
      verify(mockStorageService.storeSecure('app_theme_mode', '2')).called(1);
    });

    test('should update accessibility settings', () async {
      // Arrange
      when(mockStorageService.readSecure(any))
          .thenAnswer((_) async => null);
      when(mockStorageService.storeSecure(any, any))
          .thenAnswer((_) async {});

      await themeController.initialize();

      // Act
      await themeController.setAccessibilitySettings(
        reduceMotion: true,
        textScaleFactor: 1.5,
      );

      // Assert
      expect(themeController.reduceMotion, true);
      expect(themeController.textScaleFactor, 1.5);
      verify(mockStorageService.storeSecure('accessibility_settings', 'true,false,1.5')).called(1);
    });

    test('should switch to high contrast when enabled', () async {
      // Arrange
      when(mockStorageService.readSecure(any))
          .thenAnswer((_) async => null);
      when(mockStorageService.storeSecure(any, any))
          .thenAnswer((_) async {});

      await themeController.initialize();

      // Act
      await themeController.setAccessibilitySettings(highContrast: true);

      // Assert
      expect(themeController.highContrast, true);
      expect(themeController.currentTheme, AppThemeMode.highContrast);
    });

    test('should return reduced animation duration when reduce motion is enabled', () async {
      // Arrange
      when(mockStorageService.readSecure(any))
          .thenAnswer((_) async => null);
      when(mockStorageService.storeSecure(any, any))
          .thenAnswer((_) async {});

      await themeController.initialize();
      await themeController.setAccessibilitySettings(reduceMotion: true);

      // Act
      final duration = themeController.getAnimationDuration(
        const Duration(milliseconds: 300),
      );

      // Assert
      expect(duration, AnimationConfig.reducedMotionDuration);
    });

    test('should return normal animation duration when reduce motion is disabled', () async {
      // Arrange
      when(mockStorageService.readSecure(any))
          .thenAnswer((_) async => null);
      when(mockStorageService.storeSecure(any, any))
          .thenAnswer((_) async {});

      await themeController.initialize();
      await themeController.setAccessibilitySettings(reduceMotion: false);

      const originalDuration = Duration(milliseconds: 300);

      // Act
      final duration = themeController.getAnimationDuration(originalDuration);

      // Assert
      expect(duration, originalDuration);
    });
  });
}