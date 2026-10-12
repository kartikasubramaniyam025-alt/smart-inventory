import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/api.dart';
import '../core/theme.dart';
import '../widgets/common.dart';

/// Admin page - customer enquiries
class EnquiriesPage extends StatefulWidget {
  const EnquiriesPage({super.key});
  @override
  State<EnquiriesPage> createState() => _EnquiriesPageState();
}

class _EnquiriesPageState extends State<EnquiriesPage> {
  int _tick = 0;

  Future<void> _setStatus(Map e, String status) async {
    try {
      await Api.put('/enquiries/${e['id']}/status', {'status': status});
      if (mounted) setState(() => _tick++);
    } catch (err) {
      if (mounted) showMsg(context, '$err', error: true);
    }
  }

  @override
  Widget build(BuildContext context) => AppPage(
        title: 'Enquiries',
        body: AsyncView<List>(
          key: ValueKey(_tick),
          load: () async => List.from(await Api.get('/enquiries')),
          builder: (c, list, reload) => list.isEmpty
              ? const EmptyState('No enquiries yet')
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final e = list[i];
                    final done = e['status'] == 'done';
                    final color = done ? AppColors.success : AppColors.warning;
                    final date = DateFormat('dd MMM, hh:mm a').format(DateTime.parse(e['created_at']).toLocal());
                    final contact = [if ((e['email'] ?? '') != '') e['email'], if ((e['phone'] ?? '') != '') e['phone']].join(' • ');
                    return Card(
                      child: ListTile(
                        isThreeLine: true,
                        leading: CircleAvatar(
                          backgroundColor: color.withValues(alpha: .12),
                          child: Icon(done ? Icons.check_rounded : Icons.mail_outline, color: color),
                        ),
                        title: Text(e['name'], style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          '$contact\n${e['product_name'] != null ? 'Product: ${e['product_name']}\n' : ''}${e['message']}\n$date',
                        ),
                        trailing: TextButton(
                          onPressed: () => _setStatus(e, done ? 'new' : 'done'),
                          child: Text(done ? 'Reopen' : 'Mark done'),
                        ),
                      ),
                    );
                  },
                ),
        ),
      );
}