import 'package:flutter/material.dart';

class NavigationService {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  NavigatorState? get navigator => navigatorKey.currentState;

  Future<dynamic> navigateTo(String routeName, {Object? arguments}) {
    return navigator!.pushNamed(routeName, arguments: arguments);
  }

  Future<dynamic> navigateToAndClearStack(String routeName, {Object? arguments}) {
    return navigator!.pushNamedAndRemoveUntil(
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }

  Future<dynamic> navigateToReplacement(String routeName, {Object? arguments}) {
    return navigator!.pushReplacementNamed(routeName, arguments: arguments);
  }

  void goBack({dynamic result}) {
    navigator!.pop(result);
  }

  bool canGoBack() {
    return navigator!.canPop();
  }

  Future<dynamic> showDialog({
    required Widget dialog,
    bool barrierDismissible = true,
  }) {
    return showDialog<dynamic>(
      context: navigator!.context,
      barrierDismissible: barrierDismissible,
      builder: (context) => dialog,
    );
  }

  void showSnackBar({
    required String message,
    Duration duration = const Duration(seconds: 3),
    Color? backgroundColor,
    Color? textColor,
  }) {
    final context = navigator!.context;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: textColor),
        ),
        duration: duration,
        backgroundColor: backgroundColor,
      ),
    );
  }
}