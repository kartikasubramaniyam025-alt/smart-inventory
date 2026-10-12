import 'package:flutter/material.dart';
import '../core/theme.dart';

/// First page: choose Customer or Admin / Staff
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  Widget _option(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String text,
    required List<Widget> buttons,
  }) =>
      SizedBox(
        width: 340,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primary.withValues(alpha: .12),
                child: Icon(icon, size: 30, color: AppColors.primary),
              ),
              const SizedBox(height: 14),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(text, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted)),
              const SizedBox(height: 18),
              ...buttons,
            ]),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.inventory_rounded, size: 52, color: AppColors.primary),
                const SizedBox(height: 10),
                const Text('Smart Inventory', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                const Text('How would you like to continue?', style: TextStyle(color: AppColors.muted)),
                const SizedBox(height: 24),
                Wrap(spacing: 16, runSpacing: 16, alignment: WrapAlignment.center, children: [
                  _option(
                    context,
                    icon: Icons.shopping_bag_rounded,
                    title: 'Customer',
                    text: 'Browse products, check availability and send enquiries.',
                    buttons: [
                      ElevatedButton(
                        onPressed: () => Navigator.pushNamed(context, '/login', arguments: {'portal': 'customer'}),
                        child: const Text('Customer login'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () => Navigator.pushNamed(context, '/shop'),
                        child: const Text('Browse as guest'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/register'),
                        child: const Text('Create a customer account'),
                      ),
                    ],
                  ),
                  _option(
                    context,
                    icon: Icons.admin_panel_settings_rounded,
                    title: 'Admin / Staff',
                    text: 'Manage products, stock, reports and customer enquiries.',
                    buttons: [
                      ElevatedButton(
                        onPressed: () => Navigator.pushNamed(context, '/login', arguments: {'portal': 'staff'}),
                        child: const Text('Admin / Staff login'),
                      ),
                    ],
                  ),
                ]),
              ]),
            ),
          ),
        ),
      );
}