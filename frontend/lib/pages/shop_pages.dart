import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api.dart';
import '../core/providers.dart';
import '../core/theme.dart';
import '../widgets/common.dart';

Color _availColor(String a) => a == 'out' ? AppColors.danger : a == 'low' ? AppColors.warning : AppColors.success;
String _availText(String a) => a == 'out' ? 'Out of stock' : a == 'low' ? 'Few left' : 'In stock';

Widget _availChip(String a) {
  final c = _availColor(a);
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: c.withValues(alpha: .12), borderRadius: BorderRadius.circular(20)),
    child: Text(_availText(a), style: TextStyle(color: c, fontWeight: FontWeight.w600, fontSize: 12)),
  );
}

/// Shared frame for all public pages (no drawer)
class ShopFrame extends StatelessWidget {
  final String title;
  final Widget body;
  const ShopFrame({super.key, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: [
        IconButton(
          tooltip: 'Contact us',
          icon: const Icon(Icons.mail_outline),
          onPressed: () => Navigator.pushNamed(context, '/contact'),
        ),
        if (auth.isStaff)
          IconButton(
            tooltip: 'Dashboard',
            icon: const Icon(Icons.dashboard_rounded),
            onPressed: () => Navigator.pushNamed(context, '/dashboard'),
          ),
        if (auth.loggedIn)
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final nav = Navigator.of(context);
              await auth.logout();
              nav.pushNamedAndRemoveUntil('/welcome', (r) => false);
            },
          )
        else
          IconButton(
            tooltip: 'Sign in',
            icon: const Icon(Icons.login),
            onPressed: () => Navigator.pushNamed(context, '/welcome'),
          ),
      ]),
      body: SafeArea(child: Centered(maxWidth: 1000, child: body)),
    );
  }
}

/// Public page 1 - Shop / catalog
class ShopHomePage extends StatefulWidget {
  const ShopHomePage({super.key});
  @override
  State<ShopHomePage> createState() => _ShopHomePageState();
}

class _ShopHomePageState extends State<ShopHomePage> {
  String _search = '';
  String? _category;
  Timer? _debounce;
  late final Future<List> _cats = Api.get('/public/categories').then((v) => List.from(v));

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ShopFrame(
        title: 'Our Products',
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              decoration: const InputDecoration(hintText: 'Search products', prefixIcon: Icon(Icons.search)),
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
              key: ValueKey('$_search-$_category'),
              load: () async => List.from(await Api.get('/public/products', query: {
                if (_search.isNotEmpty) 'search': _search,
                if (_category != null) 'category_id': _category!,
              })),
              builder: (c, list, reload) => list.isEmpty
                  ? const EmptyState('No products found')
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 260,
                        mainAxisExtent: 165,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: list.length,
                      itemBuilder: (_, i) {
                        final p = list[i];
                        return Card(
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => Navigator.pushNamed(context, '/shop/product', arguments: p['id']),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(p['category_name'] ?? 'General', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                                const SizedBox(height: 4),
                                Text(p['name'], maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                const Spacer(),
                                Text('${money(p['price'])} / ${p['unit']}', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
                                const SizedBox(height: 6),
                                _availChip(p['availability']),
                              ]),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ]),
      );
}

/// Public page 2 - Product details
class ShopProductPage extends StatelessWidget {
  const ShopProductPage({super.key});

  @override
  Widget build(BuildContext context) {
    final id = ModalRoute.of(context)!.settings.arguments as int;
    return ShopFrame(
      title: 'Product details',
      body: AsyncView<Map>(
        load: () async => Map.from(await Api.get('/public/products/$id')),
        builder: (c, p, reload) => ListView(padding: const EdgeInsets.all(16), children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p['category_name'] ?? 'General', style: const TextStyle(color: AppColors.muted)),
                const SizedBox(height: 6),
                Text(p['name'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Text('${money(p['price'])} / ${p['unit']}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary)),
                const SizedBox(height: 10),
                _availChip(p['availability']),
                if ((p['description'] ?? '') != '') ...[
                  const Divider(height: 28),
                  Text(p['description']),
                ],
              ]),
            ),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.mail_outline),
            label: const Text('Enquire about this product'),
            onPressed: () => Navigator.pushNamed(context, '/contact', arguments: {'product_id': p['id'], 'product_name': p['name']}),
          ),
        ]),
      ),
    );
  }
}

/// Public page 3 - Contact / enquiry form
class ContactPage extends StatefulWidget {
  const ContactPage({super.key});
  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  final _f = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _msg = TextEditingController();
  int? _productId;
  bool _init = false, _sending = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_init) return;
    _init = true;
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _name.text = '${user['name'] ?? ''}';
      _email.text = '${user['email'] ?? ''}';
    }
    final a = ModalRoute.of(context)?.settings.arguments;
    if (a is Map) {
      _productId = a['product_id'] as int?;
      final n = a['product_name'];
      if (n != null) _msg.text = 'I am interested in $n. ';
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _msg.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_f.currentState!.validate()) return;
    if (_email.text.trim().isEmpty && _phone.text.trim().isEmpty) {
      showMsg(context, 'Please enter an email or a phone number', error: true);
      return;
    }
    setState(() => _sending = true);
    try {
      await Api.post('/public/enquiries', {
        'name': _name.text.trim(),
        'email': _email.text.trim(),
        'phone': _phone.text.trim(),
        'message': _msg.text.trim(),
        'product_id': _productId,
      });
      if (mounted) {
        showMsg(context, 'Thank you! We will contact you soon.');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) showMsg(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Widget _field(TextEditingController c, String label, {bool required = false, int lines = 1, TextInputType? type}) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextFormField(
          controller: c,
          maxLines: lines,
          keyboardType: type,
          decoration: InputDecoration(labelText: label),
          validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null : null,
        ),
      );

  @override
  Widget build(BuildContext context) => ShopFrame(
        title: 'Contact us',
        body: Form(
          key: _f,
          child: ListView(padding: const EdgeInsets.all(16), children: [
            const Text('Send us an enquiry and we will get back to you.', style: TextStyle(color: AppColors.muted)),
            const SizedBox(height: 16),
            _field(_name, 'Your name', required: true),
            _field(_email, 'Email', type: TextInputType.emailAddress),
            _field(_phone, 'Phone', type: TextInputType.phone),
            _field(_msg, 'Message', required: true, lines: 4),
            ElevatedButton(onPressed: _sending ? null : _send, child: Text(_sending ? 'Sending...' : 'Send enquiry')),
          ]),
        ),
      );
}