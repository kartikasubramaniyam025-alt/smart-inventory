import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api.dart';
import '../core/providers.dart';
import '../core/theme.dart';
import '../widgets/common.dart';

class _Field {
  final String key, label;
  const _Field(this.key, this.label);
}

/// Reusable list + add/edit/delete screen
class _MasterPage extends StatefulWidget {
  final String title, endpoint, singular;
  final IconData icon;
  final List<_Field> fields;
  const _MasterPage({required this.title, required this.endpoint, required this.singular, required this.icon, required this.fields});
  @override
  State<_MasterPage> createState() => _MasterPageState();
}

class _MasterPageState extends State<_MasterPage> {
  int _tick = 0;

  Future<void> _edit([Map? item]) async {
    final ctrls = {for (final f in widget.fields) f.key: TextEditingController(text: item?[f.key]?.toString() ?? '')};
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(item == null ? 'Add ${widget.singular}' : 'Edit ${widget.singular}'),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 380,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              for (final f in widget.fields)
                Padding(padding: const EdgeInsets.only(top: 10), child: TextField(controller: ctrls[f.key], decoration: InputDecoration(labelText: f.label))),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')),
          ElevatedButton(style: ElevatedButton.styleFrom(minimumSize: const Size(90, 42)), onPressed: () => Navigator.pop(d, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok != true) return;
    final body = {for (final f in widget.fields) f.key: ctrls[f.key]!.text.trim()};
    try {
      item == null ? await Api.post(widget.endpoint, body) : await Api.put('${widget.endpoint}/${item['id']}', body);
      if (mounted) {
        showMsg(context, item == null ? 'Added' : 'Updated');
        setState(() => _tick++);
      }
    } catch (e) {
      if (mounted) showMsg(context, '$e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.read<AuthProvider>().isAdmin;
    return AppPage(
      title: widget.title,
      fab: FloatingActionButton(onPressed: () => _edit(), child: const Icon(Icons.add)),
      body: AsyncView<List>(
        key: ValueKey(_tick),
        load: () async => List.from(await Api.get(widget.endpoint)),
        builder: (c, list, reload) => list.isEmpty
            ? EmptyState('No ${widget.title.toLowerCase()} yet')
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final it = list[i];
                  final sub = widget.fields.skip(1).map((f) => it[f.key]?.toString() ?? '').where((s) => s.isNotEmpty).join(' • ');
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(backgroundColor: AppColors.secondary.withValues(alpha: .12), child: Icon(widget.icon, color: AppColors.secondary)),
                      title: Text(it['name'], style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: sub.isEmpty ? null : Text(sub),
                      onTap: () => _edit(it),
                      trailing: isAdmin
                          ? IconButton(
                              icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                              onPressed: () async {
                                if (!await confirm(context, 'Delete ${it['name']}?')) return;
                                try {
                                  await Api.delete('${widget.endpoint}/${it['id']}');
                                  setState(() => _tick++);
                                } catch (e) {
                                  if (context.mounted) showMsg(context, '$e', error: true);
                                }
                              })
                          : null,
                    ),
                  );
                },
              ),
      ),
    );
  }
}

/// Page 8 - Categories
class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});
  @override
  Widget build(BuildContext context) => const _MasterPage(
        title: 'Categories',
        singular: 'category',
        endpoint: '/categories',
        icon: Icons.category_rounded,
        fields: [_Field('name', 'Name'), _Field('description', 'Description')],
      );
}

/// Page 9 - Suppliers
class SuppliersPage extends StatelessWidget {
  const SuppliersPage({super.key});
  @override
  Widget build(BuildContext context) => const _MasterPage(
        title: 'Suppliers',
        singular: 'supplier',
        endpoint: '/suppliers',
        icon: Icons.local_shipping_rounded,
        fields: [_Field('name', 'Name'), _Field('email', 'Email'), _Field('phone', 'Phone'), _Field('address', 'Address')],
      );
}