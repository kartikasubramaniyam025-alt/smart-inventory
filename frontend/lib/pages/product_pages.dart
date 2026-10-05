import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api.dart';
import '../core/providers.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import 'dashboard_page.dart';

Color stockColor(Map p) => p['quantity'] == 0
    ? AppColors.danger
    : p['quantity'] <= p['min_stock']
        ? AppColors.warning
        : AppColors.success;

class ProductCard extends StatelessWidget {
  final Map p;
  final VoidCallback onTap;
  const ProductCard(this.p, {super.key, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final color = stockColor(p);
    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(backgroundColor: AppColors.primary.withValues(alpha: .1), child: const Icon(Icons.inventory_2_rounded, color: AppColors.primary)),
        title: Text(p['name'], style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${p['sku']} • ${p['category_name'] ?? 'No category'}\n${money(p['price'])} / ${p['unit']}'),
        isThreeLine: true,
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: color.withValues(alpha: .12), borderRadius: BorderRadius.circular(20)),
          child: Text('${p['quantity']}', style: TextStyle(color: color, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}

/// Page 5 - Product list with search and category filter
class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});
  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  String _search = '';
  String? _category;
  int _tick = 0;
  Timer? _debounce;
  late final Future<List> _cats = Api.get('/categories').then((v) => List.from(v));

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppPage(
        title: 'Products',
        fab: FloatingActionButton(
          onPressed: () async {
            await Navigator.pushNamed(context, '/product-form');
            setState(() => _tick++);
          },
          child: const Icon(Icons.add),
        ),
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              decoration: const InputDecoration(hintText: 'Search by name or SKU', prefixIcon: Icon(Icons.search)),
              onChanged: (v) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 400), () => setState(() => _search = v.trim()));
              },
            ),
          ),
          FutureBuilder<List>(
            future: _cats,
            builder: (_, s) => SizedBox(
              height: 48,
              child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12), children: [
                for (final c in [{'id': null, 'name': 'All'}, ...(s.data ?? [])])
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    child: ChoiceChip(
                      label: Text(c['name']),
                      selected: _category == (c['id']?.toString()),
                      onSelected: (_) => setState(() => _category = c['id']?.toString()),
                    ),
                  ),
              ]),
            ),
          ),
          Expanded(
            child: AsyncView<List>(
              key: ValueKey('$_search-$_category-$_tick'),
              load: () async => List.from(await Api.get('/products', query: {
                if (_search.isNotEmpty) 'search': _search,
                if (_category != null) 'category_id': _category!,
              })),
              builder: (c, list, reload) => list.isEmpty
                  ? const EmptyState('No products found')
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                      itemCount: list.length,
                      itemBuilder: (_, i) => ProductCard(list[i], onTap: () async {
                        await Navigator.pushNamed(context, '/product-detail', arguments: list[i]['id']);
                        setState(() => _tick++);
                      }),
                    ),
            ),
          ),
        ]),
      );
}

/// Page 6 - Product detail with history
class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({super.key});
  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int _tick = 0;

  @override
  Widget build(BuildContext context) {
    final id = ModalRoute.of(context)!.settings.arguments as int;
    final isAdmin = context.read<AuthProvider>().isAdmin;
    return AsyncView<Map>(
      key: ValueKey(_tick),
      load: () async => {
        'p': await Api.get('/products/$id'),
        'moves': await Api.get('/movements', query: {'product_id': '$id'}),
      },
      builder: (c, data, reload) {
        final p = Map.from(data['p']);
        final moves = List.from(data['moves']);
        Widget row(String k, String v) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(k, style: const TextStyle(color: AppColors.muted)),
                Flexible(child: Text(v, style: const TextStyle(fontWeight: FontWeight.w600), textAlign: TextAlign.end)),
              ]),
            );
        return AppPage(
          title: p['name'],
          drawer: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_rounded),
              onPressed: () async {
                await Navigator.pushNamed(context, '/product-form', arguments: p);
                setState(() => _tick++);
              },
            ),
            if (isAdmin)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                onPressed: () async {
                  if (!await confirm(context, 'Delete ${p['name']}?')) return;
                  try {
                    await Api.delete('/products/$id');
                    if (context.mounted) Navigator.pop(context);
                  } catch (e) {
                    if (context.mounted) showMsg(context, '$e', error: true);
                  }
                },
              ),
          ],
          body: ListView(padding: const EdgeInsets.all(16), children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(children: [
                  Text('${p['quantity']} ${p['unit']}',
                      style: TextStyle(fontSize: 38, fontWeight: FontWeight.w700, color: stockColor(p))),
                  Text(p['quantity'] == 0 ? 'Out of stock' : p['quantity'] <= p['min_stock'] ? 'Low stock - reorder soon' : 'In stock',
                      style: TextStyle(color: stockColor(p))),
                  const Divider(height: 28),
                  row('SKU', p['sku']),
                  row('Category', p['category_name'] ?? '-'),
                  row('Supplier', p['supplier_name'] ?? '-'),
                  row('Selling price', money(p['price'])),
                  row('Cost price', money(p['cost'])),
                  row('Minimum stock', '${p['min_stock']}'),
                  if ((p['description'] ?? '') != '') row('Description', p['description']),
                ]),
              ),
            ),
            Row(children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Stock In'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                  onPressed: () async {
                    await Navigator.pushNamed(context, '/movement', arguments: {'product': p, 'type': 'IN'});
                    setState(() => _tick++);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.remove),
                  label: const Text('Stock Out'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                  onPressed: () async {
                    await Navigator.pushNamed(context, '/movement', arguments: {'product': p, 'type': 'OUT'});
                    setState(() => _tick++);
                  },
                ),
              ),
            ]),
            const SizedBox(height: 20),
            const Text('Movement history', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            if (moves.isEmpty) const Padding(padding: EdgeInsets.all(16), child: Text('No movements yet')),
            for (final m in moves) MovementTile(m),
          ]),
        );
      },
    );
  }
}

/// Page 7 - Add / Edit product
class ProductFormPage extends StatefulWidget {
  const ProductFormPage({super.key});
  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _f = GlobalKey<FormState>();
  final _c = {for (final k in ['name', 'sku', 'description', 'price', 'cost', 'quantity', 'min_stock', 'unit']) k: TextEditingController()};
  int? _cat, _sup;
  Map? _editing;
  List _cats = [], _sups = [];
  bool _init = false, _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_init) return;
    _init = true;
    _editing = ModalRoute.of(context)!.settings.arguments as Map?;
    final e = _editing;
    _c['unit']!.text = e?['unit'] ?? 'pcs';
    _c['min_stock']!.text = '${e?['min_stock'] ?? 10}';
    _c['quantity']!.text = '0';
    if (e != null) {
      for (final k in ['name', 'sku', 'description']) {
        _c[k]!.text = e[k] ?? '';
      }
      _c['price']!.text = '${e['price']}';
      _c['cost']!.text = '${e['cost']}';
      _cat = e['category_id'];
      _sup = e['supplier_id'];
    }
    Future.wait([Api.get('/categories'), Api.get('/suppliers')]).then((r) {
      if (mounted) setState(() { _cats = r[0]; _sups = r[1]; });
    });
  }

  Future<void> _save() async {
    if (!_f.currentState!.validate()) return;
    setState(() => _saving = true);
    final body = {
      'name': _c['name']!.text.trim(),
      'sku': _c['sku']!.text.trim(),
      'description': _c['description']!.text.trim(),
      'price': double.tryParse(_c['price']!.text) ?? 0,
      'cost': double.tryParse(_c['cost']!.text) ?? 0,
      'min_stock': int.tryParse(_c['min_stock']!.text) ?? 10,
      'unit': _c['unit']!.text.trim(),
      'category_id': _cat,
      'supplier_id': _sup,
      if (_editing == null) 'quantity': int.tryParse(_c['quantity']!.text) ?? 0,
    };
    try {
      _editing == null ? await Api.post('/products', body) : await Api.put('/products/${_editing!['id']}', body);
      if (mounted) {
        showMsg(context, _editing == null ? 'Product added' : 'Product updated');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) showMsg(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _field(String k, String label, {bool number = false, bool required = false, int lines = 1}) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextFormField(
          controller: _c[k],
          maxLines: lines,
          keyboardType: number ? const TextInputType.numberWithOptions(decimal: true) : null,
          decoration: InputDecoration(labelText: label),
          validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null : null,
        ),
      );

  @override
  Widget build(BuildContext context) => AppPage(
        title: _editing == null ? 'Add Product' : 'Edit Product',
        drawer: false,
        body: Form(
          key: _f,
          child: ListView(padding: const EdgeInsets.all(16), children: [
            _field('name', 'Product name', required: true),
            _field('sku', 'SKU / Code', required: true),
            _field('description', 'Description', lines: 2),
            Row(children: [
              Expanded(child: _field('price', 'Selling price', number: true)),
              const SizedBox(width: 12),
              Expanded(child: _field('cost', 'Cost price', number: true)),
            ]),
            Row(children: [
              if (_editing == null) ...[
                Expanded(child: _field('quantity', 'Opening qty', number: true)),
                const SizedBox(width: 12),
              ],
              Expanded(child: _field('min_stock', 'Min stock alert', number: true)),
              const SizedBox(width: 12),
              Expanded(child: _field('unit', 'Unit')),
            ]),
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: DropdownButtonFormField<int>(
                initialValue: _cat,
                decoration: const InputDecoration(labelText: 'Category'),
                items: [for (final c in _cats) DropdownMenuItem<int>(value: c['id'], child: Text(c['name']))],
                onChanged: (v) => setState(() => _cat = v),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: DropdownButtonFormField<int>(
                initialValue: _sup,
                decoration: const InputDecoration(labelText: 'Supplier'),
                items: [for (final s in _sups) DropdownMenuItem<int>(value: s['id'], child: Text(s['name']))],
                onChanged: (v) => setState(() => _sup = v),
              ),
            ),
            ElevatedButton(onPressed: _saving ? null : _save, child: Text(_saving ? 'Saving...' : 'Save Product')),
          ]),
        ),
      );
}