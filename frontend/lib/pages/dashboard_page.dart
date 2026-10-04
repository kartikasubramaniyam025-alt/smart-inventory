import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/api.dart';
import '../core/theme.dart';
import '../widgets/common.dart';

/// Page 4 - Dashboard
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) => AppPage(
        title: 'Dashboard',
        body: AsyncView<Map>(
          load: () async => Map.from(await Api.get('/dashboard')),
          builder: (c, d, reload) {
            final cards = [
              StatCard(label: 'Total Products', value: '${d['total_products']}', icon: Icons.inventory_2_rounded, color: AppColors.primary),
              StatCard(label: 'Units in Stock', value: '${d['total_units']}', icon: Icons.layers_rounded, color: AppColors.secondary),
              StatCard(label: 'Stock Value', value: money(d['stock_value']), icon: Icons.currency_rupee_rounded, color: AppColors.success),
              StatCard(label: 'Low Stock', value: '${d['low_stock']}', icon: Icons.warning_amber_rounded, color: AppColors.warning),
              StatCard(label: 'Out of Stock', value: '${d['out_of_stock']}', icon: Icons.remove_shopping_cart_rounded, color: AppColors.danger),
              StatCard(label: 'Suppliers', value: '${d['suppliers']}', icon: Icons.local_shipping_rounded, color: AppColors.muted),
            ];
            final recent = List.from(d['recent']);
            return ListView(padding: const EdgeInsets.all(16), children: [
              LayoutBuilder(builder: (_, box) {
                final cols = box.maxWidth > 600 ? 3 : 2;
                final w = (box.maxWidth - (cols - 1) * 10) / cols;
                return Wrap(spacing: 10, children: [for (final x in cards) SizedBox(width: w, child: x)]);
              }),
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Recent Activity', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                TextButton(onPressed: () => Navigator.pushReplacementNamed(context, '/history'), child: const Text('See all')),
              ]),
              if (recent.isEmpty) const Padding(padding: EdgeInsets.all(20), child: Text('No stock movements yet')),
              for (final m in recent) MovementTile(m),
              const SizedBox(height: 80),
            ]);
          },
        ),
        fab: FloatingActionButton.extended(
          onPressed: () => Navigator.pushNamed(context, '/movement'),
          icon: const Icon(Icons.swap_vert_rounded),
          label: const Text('Stock In/Out'),
        ),
      );
}

class MovementTile extends StatelessWidget {
  final Map m;
  const MovementTile(this.m, {super.key});
  @override
  Widget build(BuildContext context) {
    final t = m['type'];
    final color = t == 'IN' ? AppColors.success : t == 'OUT' ? AppColors.danger : AppColors.warning;
    final sign = t == 'IN' ? '+' : t == 'OUT' ? '-' : '=';
    final date = DateFormat('dd MMM, hh:mm a').format(DateTime.parse(m['created_at']).toLocal());
    return Card(
      child: ListTile(
        leading: CircleAvatar(
            backgroundColor: color.withOpacity(.12),
            child: Icon(t == 'IN' ? Icons.south_west_rounded : t == 'OUT' ? Icons.north_east_rounded : Icons.tune_rounded, color: color)),
        title: Text(m['product_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text([date, if ((m['note'] ?? '') != '') m['note'], if (m['user_name'] != null) 'by ${m['user_name']}'].join(' • '),
            maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: Text('$sign${m['quantity']}', style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 16)),
      ),
    );
  }
}
