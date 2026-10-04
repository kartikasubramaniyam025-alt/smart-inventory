import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers.dart';
import '../core/theme.dart';
import '../widgets/common.dart';

/// Page 1 - Splash (checks saved login)
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.restore();
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, ok ? '/dashboard' : '/login');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Container(
          decoration: const BoxDecoration(
              gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight)),
          child: const Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.inventory_rounded, size: 84, color: Colors.white),
              SizedBox(height: 16),
              Text('Smart Inventory',
                  style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700)),
              SizedBox(height: 6),
              Text('Track. Manage. Grow.', style: TextStyle(color: Colors.white70)),
              SizedBox(height: 32),
              CircularProgressIndicator(color: Colors.white),
            ]),
          ),
        ),
      );
}

class _AuthShell extends StatelessWidget {
  final String title, subtitle;
  final List<Widget> children;
  const _AuthShell({required this.title, required this.subtitle, required this.children});
  @override
  Widget build(BuildContext context) => Scaffold(
        body: Container(
          decoration: const BoxDecoration(
              gradient: LinearGradient(
                  colors: [Color(0xFFE0E7FF), Color(0xFFCFFAFE)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight)),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const CircleAvatar(
                          radius: 28,
                          backgroundColor: AppColors.primary,
                          child: Icon(Icons.inventory_rounded, color: Colors.white, size: 30)),
                      const SizedBox(height: 18),
                      Text(title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
                      Text(subtitle, style: const TextStyle(color: AppColors.muted)),
                      const SizedBox(height: 24),
                      ...children,
                    ]),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

/// Page 2 - Login
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController(text: 'admin@inventory.com');
  final _pass = TextEditingController(text: 'Admin@123');
  bool _loading = false, _hide = true;

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      await context.read<AuthProvider>().login(_email.text.trim(), _pass.text);
      if (mounted) Navigator.pushReplacementNamed(context, '/dashboard');
    } catch (e) {
      if (mounted) showMsg(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => _AuthShell(
        title: 'Welcome back',
        subtitle: 'Sign in to manage your inventory',
        children: [
          TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined))),
          const SizedBox(height: 14),
          TextField(
            controller: _pass,
            obscureText: _hide,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                    icon: Icon(_hide ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _hide = !_hide))),
          ),
          const SizedBox(height: 22),
          ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Sign In')),
          const SizedBox(height: 8),
          Center(
              child: TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/register'),
                  child: const Text("Don't have an account? Register"))),
        ],
      );
}

/// Page 3 - Register
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      await context.read<AuthProvider>().register(_name.text.trim(), _email.text.trim(), _pass.text);
      if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (_) => false);
    } catch (e) {
      if (mounted) showMsg(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => _AuthShell(
        title: 'Create account',
        subtitle: 'Start tracking your stock today',
        children: [
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Icons.person_outline))),
          const SizedBox(height: 14),
          TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined))),
          const SizedBox(height: 14),
          TextField(
              controller: _pass,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password (min 6)', prefixIcon: Icon(Icons.lock_outline))),
          const SizedBox(height: 22),
          ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Register')),
          const SizedBox(height: 8),
          Center(child: TextButton(onPressed: () => Navigator.pop(context), child: const Text('Already have an account? Sign in'))),
        ],
      );
}
