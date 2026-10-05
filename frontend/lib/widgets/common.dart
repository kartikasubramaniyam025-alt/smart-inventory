import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers.dart';
import '../core/theme.dart';

void showMsg(BuildContext c, String m, {bool error = false}) {
  ScaffoldMessenger.of(c).showSnackBar(SnackBar(
    content: Text(m),
    backgroundColor: error ? AppColors.danger : AppColors.success,
    behavior: SnackBarBehavior.floating,
  ));
}

Future<bool> confirm(BuildContext c, String text) async =>
    await showDialog<bool>(
      context: c,
      builder: (_) => AlertDialog(
        title: const Text('Please confirm'),
        content: Text(text),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Yes', style: TextStyle(color: AppColors.danger))),
        ],
      ),
    ) ??
    false;

/// Keeps content readable on wide web screens
class Centered extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  const Centered({super.key, required this.child, this.maxWidth = 900});
  @override
  Widget build(BuildContext context) =>
      Align(alignment: Alignment.topCenter, child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth), child: child));
}

class AppPage extends StatelessWidget {
  final String title;
  final Widget body;
  final Widget? fab;
  final List<Widget>? actions;
  final bool drawer;
  const AppPage({super.key, required this.title, required this.body, this.fab, this.actions, this.drawer = true});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title), actions: actions),
        drawer: drawer ? const AppDrawer() : null,
        floatingActionButton: fab,
        body: SafeArea(child: Centered(child: body)),
      );
}

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  static const items = [
    ['Dashboard', Icons.dashboard_rounded, '/dashboard'],
    ['Products', Icons.inventory_2_rounded, '/products'],
    ['Categories', Icons.category_rounded, '/categories'],
    ['Suppliers', Icons.local_shipping_rounded, '/suppliers'],
    ['Stock In / Out', Icons.swap_vert_rounded, '/movement'],
    ['Stock History', Icons.history_rounded, '/history'],
    ['Low Stock Alerts', Icons.warning_amber_rounded, '/low-stock'],
    ['Reports', Icons.bar_chart_rounded, '/reports'],
    ['Profile', Icons.person_rounded, '/profile'],
    ['Settings', Icons.settings_rounded, '/settings'],
  ];

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final current = ModalRoute.of(context)?.settings.name;
    return Drawer(
      child: Column(children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
          decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.primary, AppColors.secondary])),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.inventory_rounded, color: Colors.white, size: 40),
            const SizedBox(height: 12),
            Text(user?['name'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
            Text('${user?['email'] ?? ''}  •  ${user?['role'] ?? ''}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ]),
        ),
        Expanded(
          child: ListView(padding: EdgeInsets.zero, children: [
            for (final i in items)
              ListTile(
                leading: Icon(i[1] as IconData, color: current == i[2] ? AppColors.primary : AppColors.muted),
                title: Text(i[0] as String),
                selected: current == i[2],
                onTap: () {
                  Navigator.pop(context);
                  if (current != i[2]) Navigator.pushReplacementNamed(context, i[2] as String);
                },
              ),
          ]),
        ),
      ]),
    );
  }
}

class StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const StatCard({super.key, required this.label, required this.value, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            CircleAvatar(radius: 22, backgroundColor: color.withValues(alpha: .12), child: Icon(icon, color: color)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
              ]),
            ),
          ]),
        ),
      );
}

/// Loads data from API with loading / error / refresh handling
class AsyncView<T> extends StatefulWidget {
  final Future<T> Function() load;
  final Widget Function(BuildContext, T, Future<void> Function() reload) builder;
  const AsyncView({super.key, required this.load, required this.builder});
  @override
  State<AsyncView<T>> createState() => _AsyncViewState<T>();
}

class _AsyncViewState<T> extends State<AsyncView<T>> {
  late Future<T> _f = widget.load();

  Future<void> reload() async {
    final f = widget.load();
    setState(() => _f = f);
    try {
      await f;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<T>(
        future: _f,
        builder: (c, s) {
          if (s.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (s.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.muted),
                  const SizedBox(height: 8),
                  Text('${s.error}', textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  OutlinedButton(onPressed: reload, child: const Text('Retry')),
                ]),
              ),
            );
          }
          return RefreshIndicator(onRefresh: reload, child: widget.builder(c, s.data as T, reload));
        },
      );
}

class EmptyState extends StatelessWidget {
  final String text;
  const EmptyState(this.text, {super.key});
  @override
  Widget build(BuildContext context) => ListView(children: [
        const SizedBox(height: 120),
        const Icon(Icons.inbox_rounded, size: 56, color: AppColors.muted),
        const SizedBox(height: 8),
        Center(child: Text(text, style: const TextStyle(color: AppColors.muted))),
      ]);
}

String money(dynamic v) {
  final n = double.tryParse('$v') ?? 0;
  return '₹${n.toStringAsFixed(n == n.roundToDouble() ? 0 : 2)}';
}