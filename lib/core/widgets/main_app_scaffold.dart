import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../router/route_paths.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Responsive Main Scaffold for Wholesalers & ERP Admins
class MainAppScaffold extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const MainAppScaffold({
    super.key,
    required this.navigationShell,
  });

  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  void _handleSignOut(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to log out of your session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            onPressed: () {
              Navigator.pop(dialogContext);
              ref.read(authControllerProvider.notifier).logout();
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userModelAsync = ref.watch(currentUserModelProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/app_logo.png',
              height: 32,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.store_mall_directory_rounded,
                color: AppColors.textOnPrimary,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Al Asad Traders',
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.textOnPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          // User Profile Chip
          userModelAsync.when(
            data: (user) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 12,
                    backgroundColor: AppColors.success,
                    child: Icon(
                      Icons.person,
                      size: 14,
                      color: AppColors.textOnPrimary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    user?.name.isNotEmpty == true ? user!.name : 'Wholesaler',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textOnPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Logout Button
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign Out',
            onPressed: () => _handleSignOut(context, ref),
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: AppColors.primary),
              currentAccountPicture: CircleAvatar(
                backgroundColor: AppColors.surface,
                child: Image.asset(
                  'assets/images/app_logo.png',
                  height: 40,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.store_mall_directory_rounded,
                    color: AppColors.primary,
                  ),
                ),
              ),
              accountName: userModelAsync.when(
                data: (user) => Text(
                  user?.name ?? 'Wholesaler ERP',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.textOnPrimary,
                  ),
                ),
                loading: () => const Text('Loading...'),
                error: (_, __) => const Text('Wholesaler'),
              ),
              accountEmail: userModelAsync.when(
                data: (user) => Text(
                  user?.email ?? '',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                loading: () => const Text(''),
                error: (_, __) => const Text(''),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard_rounded),
              title: const Text('Dashboard'),
              selected: navigationShell.currentIndex == 0,
              onTap: () {
                Navigator.pop(context);
                _onDestinationSelected(0);
              },
            ),
            ListTile(
              leading: const Icon(Icons.people_alt_rounded),
              title: const Text('B2B Customer Directory'),
              onTap: () {
                Navigator.pop(context);
                context.push(RoutePaths.customers);
              },
            ),
            ListTile(
              leading: const Icon(Icons.inventory_2_rounded),
              title: const Text('Inventory Management'),
              selected: navigationShell.currentIndex == 1,
              onTap: () {
                Navigator.pop(context);
                _onDestinationSelected(1);
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long_rounded),
              title: const Text('Invoices & Billing'),
              selected: navigationShell.currentIndex == 2,
              onTap: () {
                Navigator.pop(context);
                _onDestinationSelected(2);
              },
            ),
            ListTile(
              leading: const Icon(Icons.local_shipping_rounded),
              title: const Text('Suppliers & Purchases'),
              selected: navigationShell.currentIndex == 3,
              onTap: () {
                Navigator.pop(context);
                _onDestinationSelected(3);
              },
            ),
            ListTile(
              leading: const Icon(Icons.assignment_turned_in_rounded),
              title: const Text('B2B Order Fulfillment'),
              selected: navigationShell.currentIndex == 4,
              onTap: () {
                Navigator.pop(context);
                _onDestinationSelected(4);
              },
            ),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: AppColors.error),
              title: const Text(
                'Sign Out',
                style: TextStyle(color: AppColors.error),
              ),
              onTap: () {
                Navigator.pop(context);
                _handleSignOut(context, ref);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      body: isDesktop
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: navigationShell.currentIndex,
                  onDestinationSelected: _onDestinationSelected,
                  labelType: NavigationRailLabelType.all,
                  backgroundColor: AppColors.surface,
                  indicatorColor: AppColors.primaryContainer,
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard_rounded, color: AppColors.primary),
                      label: Text('Dashboard'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.inventory_2_outlined),
                      selectedIcon: Icon(Icons.inventory_2_rounded, color: AppColors.primary),
                      label: Text('Inventory'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.receipt_long_outlined),
                      selectedIcon: Icon(Icons.receipt_long_rounded, color: AppColors.primary),
                      label: Text('Invoices'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.local_shipping_outlined),
                      selectedIcon: Icon(Icons.local_shipping_rounded, color: AppColors.primary),
                      label: Text('Suppliers'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.assignment_outlined),
                      selectedIcon: Icon(Icons.assignment_turned_in_rounded, color: AppColors.primary),
                      label: Text('B2B Orders'),
                    ),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(child: navigationShell),
              ],
            )
          : navigationShell,
      bottomNavigationBar: isDesktop
          ? null
          : NavigationBar(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: _onDestinationSelected,
              backgroundColor: AppColors.surface,
              indicatorColor: AppColors.primaryContainer,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard_rounded, color: AppColors.primary),
                  label: 'Dashboard',
                ),
                NavigationDestination(
                  icon: Icon(Icons.inventory_2_outlined),
                  selectedIcon: Icon(Icons.inventory_2_rounded, color: AppColors.primary),
                  label: 'Inventory',
                ),
                NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long_rounded, color: AppColors.primary),
                  label: 'Invoices',
                ),
                NavigationDestination(
                  icon: Icon(Icons.local_shipping_outlined),
                  selectedIcon: Icon(Icons.local_shipping_rounded, color: AppColors.primary),
                  label: 'Suppliers',
                ),
                NavigationDestination(
                  icon: Icon(Icons.assignment_outlined),
                  selectedIcon: Icon(Icons.assignment_turned_in_rounded, color: AppColors.primary),
                  label: 'Orders',
                ),
              ],
            ),
    );
  }
}
