import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/providers.dart';
import 'core/theme.dart';
import 'pages/auth_pages.dart';
import 'pages/dashboard_page.dart';
import 'pages/product_pages.dart';
import 'pages/master_pages.dart';
import 'pages/stock_pages.dart';
import 'pages/reports_page.dart';
import 'pages/account_pages.dart';
import 'pages/shop_pages.dart';
import 'pages/enquiries_page.dart';
import 'pages/welcome_page.dart';
import 'pages/users_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
      ChangeNotifierProvider(create: (_) => ThemeProvider()..load()),
    ],
    child: const InventoryApp(),
  ));
}

class InventoryApp extends StatelessWidget {
  const InventoryApp({super.key});

  static Route _route(String name, Widget page) =>
      MaterialPageRoute(builder: (_) => page, settings: RouteSettings(name: name));

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    return MaterialApp(
      title: 'Smart Inventory',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(Brightness.light),
      darkTheme: AppTheme.build(Brightness.dark),
      themeMode: theme.mode,
      initialRoute: '/',
      // Public pages open directly from a link (e.g. .../#/shop)
      onGenerateInitialRoutes: (String name) {
        switch (name) {
          case '/shop':
            return [_route('/shop', const ShopHomePage())];
          case '/contact':
            return [_route('/contact', const ContactPage())];
          case '/welcome':
            return [_route('/welcome', const WelcomePage())];
          default:
            return [_route('/', const SplashPage())];
        }
      },
      routes: {
        '/': (_) => const SplashPage(),
        '/welcome': (_) => const WelcomePage(),
        '/login': (_) => const LoginPage(),
        '/register': (_) => const RegisterPage(),
        '/dashboard': (_) => const DashboardPage(),
        '/products': (_) => const ProductListPage(),
        '/product-detail': (_) => const ProductDetailPage(),
        '/product-form': (_) => const ProductFormPage(),
        '/categories': (_) => const CategoriesPage(),
        '/suppliers': (_) => const SuppliersPage(),
        '/movement': (_) => const StockMovementPage(),
        '/history': (_) => const StockHistoryPage(),
        '/low-stock': (_) => const LowStockPage(),
        '/reports': (_) => const ReportsPage(),
        '/profile': (_) => const ProfilePage(),
        '/settings': (_) => const SettingsPage(),
        '/shop': (_) => const ShopHomePage(),
        '/shop/product': (_) => const ShopProductPage(),
        '/contact': (_) => const ContactPage(),
        '/enquiries': (_) => const EnquiriesPage(),
        '/users': (_) => const UsersPage(),
      },
    );
  }
}