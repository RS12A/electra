import 'package:flutter/material.dart';

class AuthBloc {
  final _stateController = StreamController<AuthState>.broadcast();
  Stream<AuthState> get stream => _stateController.stream;
  
  void add(AuthEvent event) {
    if (event is AuthCheckRequested) {
      _stateController.add(AuthUnauthenticated());
    }
  }
  
  void dispose() {
    _stateController.close();
  }
}

abstract class AuthEvent {}
class AuthCheckRequested extends AuthEvent {}

abstract class AuthState {}
class AuthLoading extends AuthState {}
class AuthAuthenticated extends AuthState {}
class AuthUnauthenticated extends AuthState {}

import 'dart:async';