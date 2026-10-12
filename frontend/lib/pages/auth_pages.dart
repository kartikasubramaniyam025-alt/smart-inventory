import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api.dart';
import '../core/providers.dart';
import '../core/theme.dart';
import '../widgets/common.dart';

/// Decides where to go when the app opens
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _go());
  }

  Future<void> _go() async {
    final auth = context.read<AuthProvider>();
    await auth.init();
    if (!mounted) return;
    final route = auth.isStaff ? '/dashboard' : auth.isCustomer ? '/shop' : '/welcome';
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.inventory_rounded, size: 52, color: AppColors.primary),
            SizedBox(height: 16),
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Loading...', style: TextStyle(color: AppColors.muted)),
          ]),
        ),
      );
}

/// Login for customers or admin/staff (chosen on the welcome page)
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _f = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String _portal = 'customer';
  bool _init = false, _busy = false, _hide = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_init) return;
    _init = true;
    final a = ModalRoute.of(context)?.settings.arguments;
    if (a is Map && a['portal'] == 'staff') _portal = 'staff';
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_f.currentState!.validate()) return;
    setState(() => _busy = true);
    final auth = context.read<AuthProvider>();
    try {
      await auth.login(_email.text.trim(), _password.text);
      final staffPortal = _portal == 'staff';
      if (staffPortal && !auth.isStaff) {
        await auth.logout();
        throw ApiException('This is a customer account. Please use Customer login.');
      }
      if (!staffPortal && auth.isStaff) {
        await auth.logout();
        throw ApiException('This is a staff account. Please use Admin / Staff login.');
      }
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, staffPortal ? '/dashboard' : '/shop', (r) => false);
    } catch (e) {
      if (mounted) showMsg(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final staff = _portal == 'staff';
    return Scaffold(
      appBar: AppBar(title: Text(staff ? 'Admin / Staff login' : 'Customer login')),
      body: SafeArea(
        child: Centered(
          maxWidth: 440,
          child: Form(
            key: _f,
            child: ListView(padding: const EdgeInsets.all(20), children: [
              const SizedBox(height: 12),
              Icon(staff ? Icons.admin_panel_settings_rounded : Icons.shopping_bag_rounded, size: 52, color: AppColors.primary),
              const SizedBox(height: 10),
              Text(staff ? 'Sign in to manage the inventory' : 'Sign in to your account',
                  textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 22),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _password,
                obscureText: _hide,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_hide ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _hide = !_hide),
                  ),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Enter your password' : null,
                onFieldSubmitted: (_) => _busy ? null : _login(),
              ),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _busy ? null : _login, child: Text(_busy ? 'Signing in...' : 'Sign in')),
              const SizedBox(height: 8),
              if (!staff)
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/register'),
                  child: const Text('New customer? Create an account'),
                )
              else
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text('Staff accounts are created by an administrator.',
                      textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted, fontSize: 12)),
                ),
              TextButton(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/welcome', (r) => false),
                child: const Text('Back to start'),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Customer sign-up (always creates a customer account)
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _f = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false, _hide = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_f.currentState!.validate()) return;
    setState(() => _busy = true);
    final auth = context.read<AuthProvider>();
    try {
      await auth.register(_name.text.trim(), _email.text.trim(), _password.text);
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, auth.isStaff ? '/dashboard' : '/shop', (r) => false);
    } catch (e) {
      if (mounted) showMsg(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Create customer account')),
        body: SafeArea(
          child: Centered(
            maxWidth: 440,
            child: Form(
              key: _f,
              child: ListView(padding: const EdgeInsets.all(20), children: [
                const SizedBox(height: 8),
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Icons.person_outline)),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your name' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                  validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _password,
                  obscureText: _hide,
                  decoration: InputDecoration(
                    labelText: 'Password (min 8 characters)',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_hide ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _hide = !_hide),
                    ),
                  ),
                  validator: (v) => (v == null || v.length < 8) ? 'At least 8 characters' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _confirm,
                  obscureText: _hide,
                  decoration: const InputDecoration(labelText: 'Confirm password', prefixIcon: Icon(Icons.lock_outline)),
                  validator: (v) => v != _password.text ? 'Passwords do not match' : null,
                ),
                const SizedBox(height: 20),
                ElevatedButton(onPressed: _busy ? null : _register, child: Text(_busy ? 'Creating...' : 'Create account')),
                TextButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, '/login', arguments: {'portal': 'customer'}),
                  child: const Text('Already have an account? Sign in'),
                ),
              ]),
            ),
          ),
        ),
      );
}