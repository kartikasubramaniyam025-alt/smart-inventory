import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api.dart';
import '../core/providers.dart';
import '../core/theme.dart';
import '../widgets/common.dart';

/// Admin page - manage user roles (customer / staff / admin)
class UsersPage extends StatefulWidget {
  const UsersPage({super.key});
  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  int _tick = 0;

  Future<void> _setRole(Map u, String role) async {
    try {
      await Api.put('/users/${u['id']}/role', {'role': role});
      if (mounted) {
        showMsg(context, 'Role updated');
        setState(() => _tick++);
      }
    } catch (e) {
      if (mounted) showMsg(context, '$e', error: true);
    }
  }

  Future<void> _delete(Map u) async {
    if (!await confirm(context, 'Delete ${u['name']}?')) return;
    try {
      await Api.delete('/users/${u['id']}');
      if (mounted) setState(() => _tick++);
    } catch (e) {
      if (mounted) showMsg(context, '$e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = context.read<AuthProvider>().user?['id'];
    return AppPage(
      title: 'Users',
      body: AsyncView<List>(
        key: ValueKey(_tick),
        load: () async => List.from(await Api.get('/users')),
        builder: (c, list, reload) => list.isEmpty
            ? const EmptyState('No users')
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final u = list[i];
                  final name = '${u['name'] ?? ''}';
                  return Card(
                    child: ListTile(
                      isThreeLine: true,
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withValues(alpha: .12),
                        child: Text(name.isEmpty ? '?' : name[0].toUpperCase(), style: const TextStyle(color: AppColors.primary)),
                      ),
                      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('${u['email']}\nRole: ${u['role']}'),
                      trailing: u['id'] == me
                          ? const Text('You')
                          : PopupMenuButton<String>(
                              onSelected: (v) => v == 'delete' ? _delete(u) : _setRole(u, v),
                              itemBuilder: (_) => [
                                for (final r in ['admin', 'staff', 'customer'])
                                  if (r != u['role']) PopupMenuItem(value: r, child: Text('Make $r')),
                                const PopupMenuItem(value: 'delete', child: Text('Delete user')),
                              ],
                            ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}