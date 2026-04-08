import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  ThemeController() {
    _load();
  }

  static const _key = 'theme_mode';
  ThemeMode _mode = ThemeMode.system;

  ThemeMode get mode => _mode;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    switch (saved) {
      case 'light':
        _mode = ThemeMode.light;
      case 'dark':
        _mode = ThemeMode.dark;
      default:
        _mode = ThemeMode.system;
    }
    notifyListeners();
  }

  Future<void> setMode(ThemeMode mode) async {
    _mode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
  }
}

class AuthController extends ChangeNotifier {
  AuthController() {
    _subscription = _auth.authStateChanges().listen((user) {
      _user = user;
      notifyListeners();
    });
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final StreamSubscription<User?> _subscription;

  User? _user;
  bool _busy = false;

  User? get user => _user;
  bool get busy => _busy;
  bool get isSignedIn => _user != null;

  Future<void> signIn({required String email, required String password}) async {
    _busy = true;
    notifyListeners();
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> signUp({
    required String username,
    required String email,
    required String password,
  }) async {
    _busy = true;
    notifyListeners();
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await credential.user?.updateDisplayName(username.trim());

      await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .set({
            'username': username.trim(),
            'email': email.trim(),
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> signOut() => _auth.signOut();

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
