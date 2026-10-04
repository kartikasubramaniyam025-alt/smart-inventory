import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/theme.dart';
import '../widgets/common.dart';

/// Page 13 - Reports (stock value by category)
class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) => AppPage(
        title: 'Reports',
        body: AsyncView<List>(
          load: () async => List.from(await Api.get('/reports/stock-by-category')),
          builder: (c, rows, reload) {
            final maxV = rows.fold<double>(1, (m, r) => (r['value'] as num) > m ? (r['value'] as num).toDouble() : m);
            final total = rows.fold<double>(0, (s, r) => s + (r['value'] as num));
            return ListView(padding: const EdgeInsets.all(16), children: [
              StatCard(label: 'Total inventory value (at cost)', value: money(total), icon: Icons.account_balance_wallet_rounded, color: AppColors.primary),
              const SizedBox(height: 8),
              const Text('Stock value by category', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              for (final r in rows)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text(r['category'], style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(money(r['value']), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
                      ]),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(value: (r['value'] as num) / maxV, minHeight: 10, backgroundColor: AppColors.primary.withOpacity(.1)),
                      ),
                      const SizedBox(height: 6),
                      Text('${r['products']} products • ${r['units']} units', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                    ]),
                  ),
                ),
            ]);
          },
        ),
      );
}
