import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers.dart';
import '../core/theme.dart';
import '../widgets/common.dart';

/// Profile: edit name / email, change password, log out
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _pf = GlobalKey<FormState>();
  final _pw = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  final _cur = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final u = context.read<AuthProvider>().user;
    _name = TextEditingController(text: '${u?['name'] ?? ''}');
    _email = TextEditingController(text: '${u?['email'] ?? ''}');
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _cur.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_pf.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await context.read<AuthProvider>().updateProfile(_name.text.trim(), _email.text.trim());
      if (mounted) showMsg(context, 'Profile updated');
    } catch (e) {
      if (mounted) showMsg(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _changePassword() async {
    if (!_pw.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await context.read<AuthProvider>().changePassword(_cur.text, _new.text);
      _cur.clear();
      _new.clear();
      _confirm.clear();
      if (mounted) showMsg(context, 'Password updated');
    } catch (e) {
      if (mounted) showMsg(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _logout() async {
    final nav = Navigator.of(context);
    await context.read<AuthProvider>().logout();
    nav.pushNamedAndRemoveUntil('/welcome', (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthProvider>().role;
    return AppPage(
      title: 'Profile',
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _pf,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Text('My details', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Chip(label: Text(role.isEmpty ? '-' : role)),
                ]),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                ),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: _busy ? null : _saveProfile, child: const Text('Save changes')),
              ]),
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _pw,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Change password', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _cur,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Current password'),
                  validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _new,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'New password (min 8 characters)'),
                  validator: (v) => (v == null || v.length < 8) ? 'At least 8 characters' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirm,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Confirm new password'),
                  validator: (v) => v != _new.text ? 'Passwords do not match' : null,
                ),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: _busy ? null : _changePassword, child: const Text('Update password')),
              ]),
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: _logout,
          icon: const Icon(Icons.logout, color: AppColors.danger),
          label: const Text('Log out', style: TextStyle(color: AppColors.danger)),
        ),
      ]),
    );
  }
}

/// Settings: theme and log out
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    return AppPage(
      title: 'Settings',
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Appearance', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(value: ThemeMode.light, label: Text('Light'), icon: Icon(Icons.light_mode)),
                  ButtonSegment(value: ThemeMode.system, label: Text('System'), icon: Icon(Icons.brightness_auto)),
                  ButtonSegment(value: ThemeMode.dark, label: Text('Dark'), icon: Icon(Icons.dark_mode)),
                ],
                selected: {theme.mode},
                onSelectionChanged: (s) => theme.setMode(s.first),
              ),
            ]),
          ),
        ),
        const Card(
          child: ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Smart Inventory'),
            subtitle: Text('Inventory management and customer shop'),
          ),
        ),
        OutlinedButton.icon(
          onPressed: () async {
            final nav = Navigator.of(context);
            await context.read<AuthProvider>().logout();
            nav.pushNamedAndRemoveUntil('/welcome', (r) => false);
          },
          icon: const Icon(Icons.logout, color: AppColors.danger),
          label: const Text('Log out', style: TextStyle(color: AppColors.danger)),
        ),
      ]),
    );
  }
}