import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api.dart';
import '../core/providers.dart';
import '../core/theme.dart';
import '../widgets/common.dart';

/// Page 14 - Profile (update details + change password)
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final _name = TextEditingController(text: context.read<AuthProvider>().user?['name']);
  late final _email = TextEditingController(text: context.read<AuthProvider>().user?['email']);
  final _cur = TextEditingController();
  final _new = TextEditingController();

  Future<void> _saveProfile() async {
    try {
      await context.read<AuthProvider>().updateProfile(_name.text.trim(), _email.text.trim());
      if (mounted) showMsg(context, 'Profile updated');
    } catch (e) {
      if (mounted) showMsg(context, '$e', error: true);
    }
  }

  Future<void> _changePassword() async {
    try {
      await Api.put('/auth/me/password', {'current_password': _cur.text, 'new_password': _new.text});
      _cur.clear();
      _new.clear();
      if (mounted) showMsg(context, 'Password changed');
    } catch (e) {
      if (mounted) showMsg(context, '$e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return AppPage(
      title: 'Profile',
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Center(
          child: Column(children: [
            CircleAvatar(
                radius: 44,
                backgroundColor: AppColors.primary,
                child: Text((user?['name'] ?? '?').toString().isEmpty ? '?' : user!['name'][0].toUpperCase(),
                    style: const TextStyle(fontSize: 36, color: Colors.white))),
            const SizedBox(height: 8),
            Chip(label: Text((user?['role'] ?? '').toString().toUpperCase())),
          ]),
        ),
        const SizedBox(height: 12),
        const Text('Personal details', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name')),
        const SizedBox(height: 12),
        TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email')),
        const SizedBox(height: 14),
        ElevatedButton(onPressed: _saveProfile, child: const Text('Update Profile')),
        const SizedBox(height: 28),
        const Text('Change password', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        TextField(controller: _cur, obscureText: true, decoration: const InputDecoration(labelText: 'Current password')),
        const SizedBox(height: 12),
        TextField(controller: _new, obscureText: true, decoration: const InputDecoration(labelText: 'New password (min 6)')),
        const SizedBox(height: 14),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary), onPressed: _changePassword, child: const Text('Change Password')),
      ]),
    );
  }
}

/// Page 15 - Settings (theme, server info, users for admin, logout)
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final auth = context.watch<AuthProvider>();
    return AppPage(
      title: 'Settings',
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(
          child: SwitchListTile(
            secondary: const Icon(Icons.dark_mode_rounded),
            title: const Text('Dark mode'),
            value: theme.mode == ThemeMode.dark,
            onChanged: theme.toggle,
          ),
        ),
        Card(child: ListTile(leading: const Icon(Icons.cloud_rounded), title: const Text('API server'), subtitle: Text(Api.baseUrl))),
        if (auth.isAdmin)
          Card(
            child: ListTile(
              leading: const Icon(Icons.group_rounded),
              title: const Text('Manage users'),
              subtitle: const Text('Change roles of team members'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => const _UsersSheet()),
            ),
          ),
        const Card(child: ListTile(leading: Icon(Icons.info_outline), title: Text('Smart Inventory'), subtitle: Text('Version 1.0.0'))),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
          icon: const Icon(Icons.logout),
          label: const Text('Logout'),
          onPressed: () async {
            await auth.logout();
            if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
          },
        ),
      ]),
    );
  }
}

class _UsersSheet extends StatefulWidget {
  const _UsersSheet();
  @override
  State<_UsersSheet> createState() => _UsersSheetState();
}

class _UsersSheetState extends State<_UsersSheet> {
  int _tick = 0;
  @override
  Widget build(BuildContext context) => SizedBox(
        height: MediaQuery.of(context).size.height * .7,
        child: AsyncView<List>(
          key: ValueKey(_tick),
          load: () async => List.from(await Api.get('/users')),
          builder: (c, users, reload) => ListView(padding: const EdgeInsets.all(16), children: [
            const Text('Users', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            for (final u in users)
              ListTile(
                title: Text(u['name']),
                subtitle: Text(u['email']),
                trailing: DropdownButton<String>(
                  value: u['role'],
                  items: const [DropdownMenuItem(value: 'admin', child: Text('admin')), DropdownMenuItem(value: 'staff', child: Text('staff'))],
                  onChanged: (r) async {
                    try {
                      await Api.put('/users/${u['id']}/role', {'role': r});
                      setState(() => _tick++);
                    } catch (e) {
                      if (context.mounted) showMsg(context, '$e', error: true);
                    }
                  },
                ),
              ),
          ]),
        ),
      );
}
