import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import 'dashboard_page.dart';
import 'product_pages.dart';

/// Page 10 - Stock In / Out / Adjust
class StockMovementPage extends StatefulWidget {
  const StockMovementPage({super.key});
  @override
  State<StockMovementPage> createState() => _StockMovementPageState();
}

class _StockMovementPageState extends State<StockMovementPage> {
  List _products = [];
  int? _productId;
  String _type = 'IN';
  final _qty = TextEditingController();
  final _note = TextEditingController();
  bool _init = false, _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_init) return;
    _init = true;
    final args = ModalRoute.of(context)!.settings.arguments;
    if (args is Map) {
      _productId = args['product']['id'];
      _type = args['type'] ?? 'IN';
    }
    Api.get('/products').then((v) {
      if (mounted) setState(() => _products = v);
    });
  }

  Future<void> _save() async {
    if (_productId == null || _qty.text.trim().isEmpty) {
      showMsg(context, 'Select a product and enter quantity', error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      final r = await Api.post('/movements', {'product_id': _productId, 'type': _type, 'quantity': int.tryParse(_qty.text), 'note': _note.text.trim()});
      if (mounted) {
        showMsg(context, 'Done. New stock: ${r['new_quantity']}');
        _qty.clear();
        _note.clear();
        final v = await Api.get('/products');
        setState(() => _products = v);
      }
    } catch (e) {
      if (mounted) showMsg(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = _products.where((p) => p['id'] == _productId).toList();
    return AppPage(
      title: 'Stock In / Out',
      body: ListView(padding: const EdgeInsets.all(16), children: [
        DropdownButtonFormField<int>(
          initialValue: _productId,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Product'),
          items: [for (final p in _products) DropdownMenuItem<int>(value: p['id'], child: Text('${p['name']} (${p['sku']})', overflow: TextOverflow.ellipsis))],
          onChanged: (v) => setState(() => _productId = v),
        ),
        if (current.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Text('Current stock: ${current.first['quantity']} ${current.first['unit']}', style: const TextStyle(color: AppColors.muted)),
          ),
        const SizedBox(height: 16),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'IN', label: Text('Stock In'), icon: Icon(Icons.add)),
            ButtonSegment(value: 'OUT', label: Text('Stock Out'), icon: Icon(Icons.remove)),
            ButtonSegment(value: 'ADJUST', label: Text('Set'), icon: Icon(Icons.tune)),
          ],
          selected: {_type},
          onSelectionChanged: (s) => setState(() => _type = s.first),
        ),
        const SizedBox(height: 16),
        TextField(controller: _qty, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: _type == 'ADJUST' ? 'New exact quantity' : 'Quantity')),
        const SizedBox(height: 14),
        TextField(controller: _note, decoration: const InputDecoration(labelText: 'Note (optional)')),
        const SizedBox(height: 22),
        ElevatedButton(onPressed: _saving ? null : _save, child: Text(_saving ? 'Saving...' : 'Submit')),
      ]),
    );
  }
}

/// Page 11 - Stock history
class StockHistoryPage extends StatelessWidget {
  const StockHistoryPage({super.key});
  @override
  Widget build(BuildContext context) => AppPage(
        title: 'Stock History',
        body: AsyncView<List>(
          load: () async => List.from(await Api.get('/movements')),
          builder: (c, list, reload) => list.isEmpty
              ? const EmptyState('No movements recorded')
              : ListView.builder(padding: const EdgeInsets.all(16), itemCount: list.length, itemBuilder: (_, i) => MovementTile(list[i])),
        ),
      );
}

/// Page 12 - Low stock alerts
class LowStockPage extends StatelessWidget {
  const LowStockPage({super.key});
  @override
  Widget build(BuildContext context) => AppPage(
        title: 'Low Stock Alerts',
        body: AsyncView<List>(
          load: () async => List.from(await Api.get('/products', query: {'low': 'true'})),
          builder: (c, list, reload) => list.isEmpty
              ? const EmptyState('All products are well stocked')
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  itemBuilder: (_, i) => ProductCard(list[i], onTap: () => Navigator.pushNamed(context, '/product-detail', arguments: list[i]['id'])),
                ),
        ),
      );
}
