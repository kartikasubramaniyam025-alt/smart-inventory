import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api.dart';

class AuthProvider extends ChangeNotifier {
  Map<String, dynamic>? user;
  bool get isAdmin => user?['role'] == 'admin';

  Future<bool> restore() async {
    await Api.loadToken();
    if (Api.token == null) return false;
    try {
      user = Map<String, dynamic>.from(await Api.get('/auth/me'));
      notifyListeners();
      return true;
    } catch (_) {
      await Api.saveToken(null);
      return false;
    }
  }

  Future<void> login(String email, String password) async {
    final r = await Api.post('/auth/login', {'email': email, 'password': password});
    await Api.saveToken(r['token']);
    user = Map<String, dynamic>.from(r['user']);
    notifyListeners();
  }

  Future<void> register(String name, String email, String password) async {
    final r = await Api.post('/auth/register', {'name': name, 'email': email, 'password': password});
    await Api.saveToken(r['token']);
    user = Map<String, dynamic>.from(r['user']);
    notifyListeners();
  }

  Future<void> updateProfile(String name, String email) async {
    user = Map<String, dynamic>.from(await Api.put('/auth/me', {'name': name, 'email': email}));
    notifyListeners();
  }

  Future<void> logout() async {
    await Api.saveToken(null);
    user = null;
    notifyListeners();
  }
}

class ThemeProvider extends ChangeNotifier {
  ThemeMode mode = ThemeMode.light;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    mode = (p.getBool('dark') ?? false) ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  Future<void> toggle(bool dark) async {
    mode = dark ? ThemeMode.dark : ThemeMode.light;
    (await SharedPreferences.getInstance()).setBool('dark', dark);
    notifyListeners();
  }
}
