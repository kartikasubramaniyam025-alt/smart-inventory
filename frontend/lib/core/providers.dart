import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api.dart';

class AuthProvider extends ChangeNotifier {
  Map? user;
  bool ready = false;
  Future<void>? _initFuture;

  bool get loggedIn => user != null;
  String get role => (user?['role'] ?? '').toString();
  bool get isAdmin => role == 'admin';
  bool get isStaff => role == 'admin' || role == 'staff';
  bool get isCustomer => role == 'customer';

  /// Restores the saved session once; safe to call many times.
  Future<void> init() => _initFuture ??= _restore();

  Future<void> _restore() async {
    await Api.loadToken();
    if (Api.token != null) {
      try {
        user = Map.from(await Api.get('/auth/me'));
      } on ApiException catch (e) {
        if (!e.message.startsWith('Cannot reach')) await Api.saveToken(null);
      }
    }
    ready = true;
    notifyListeners();
  }

  Future<void> _accept(dynamic r) async {
    await Api.saveToken(r['token']);
    user = Map.from(r['user']);
    notifyListeners();
  }

  Future<void> login(String email, String password) async =>
      _accept(await Api.post('/auth/login', {'email': email, 'password': password}));

  Future<void> register(String name, String email, String password) async =>
      _accept(await Api.post('/auth/register', {'name': name, 'email': email, 'password': password}));

  Future<void> logout() async {
    await Api.saveToken(null);
    user = null;
    notifyListeners();
  }

  Future<void> updateProfile(String name, String email) async {
    user = Map.from(await Api.put('/auth/me', {'name': name, 'email': email}));
    notifyListeners();
  }

  Future<void> changePassword(String current, String next) async {
    await Api.put('/auth/me/password', {'current_password': current, 'new_password': next});
  }
}

class ThemeProvider extends ChangeNotifier {
  ThemeMode mode = ThemeMode.system;

  Future<void> load() async {
    final s = (await SharedPreferences.getInstance()).getString('theme');
    mode = s == 'dark' ? ThemeMode.dark : s == 'light' ? ThemeMode.light : ThemeMode.system;
    notifyListeners();
  }

  Future<void> setMode(ThemeMode m) async {
    mode = m;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setString('theme', m == ThemeMode.dark ? 'dark' : m == ThemeMode.light ? 'light' : 'system');
  }
}