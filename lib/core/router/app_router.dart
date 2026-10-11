import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'route_paths.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/inventory/screens/inventory_list_screen.dart';
import '../../features/inventory/screens/add_product_screen.dart';
import '../../features/inventory/screens/product_detail_screen.dart';
import '../../features/invoices/screens/invoice_list_screen.dart';
import '../../features/invoices/screens/create_invoice_screen.dart';
import '../../features/invoices/screens/invoice_detail_screen.dart';
import '../../features/suppliers/screens/supplier_list_screen.dart';
import '../../features/suppliers/screens/purchase_list_screen.dart';
import '../../features/b2b_portal/screens/customer_catalog_screen.dart';
import '../../features/b2b_portal/screens/ledger_screen.dart';
import '../../features/b2b_portal/screens/b2b_fulfillment_screen.dart';

/// Listenable that notifies GoRouter when Auth state changes
class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen(authStateStreamProvider, (_, __) => notifyListeners());
    _ref.listen(currentUserModelProvider, (_, __) => notifyListeners());
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    initialLocation: RoutePaths.dashboard,
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authStateStreamProvider);
      final userModelAsync = ref.read(currentUserModelProvider);

      final user = authState.asData?.value;
      final userModel = userModelAsync.asData?.value;

      final isLoggingIn = state.matchedLocation == RoutePaths.login;

      // 1. Not logged in -> Redirect to login screen
      if (user == null) {
        return isLoggingIn ? null : RoutePaths.login;
      }

      // 2. Logged in and trying to go to login screen or initial path
      if (isLoggingIn || state.matchedLocation == RoutePaths.initial) {
        if (userModel != null && userModel.isCustomer) {
          return RoutePaths.b2bCatalog;
        }
        return RoutePaths.dashboard;
      }

      // 3. Role-based restriction: Customers attempting to access Wholesaler screens
      if (userModel != null && userModel.isCustomer) {
        final wholesalerPaths = [
          RoutePaths.dashboard,
          RoutePaths.inventory,
          RoutePaths.invoices,
          RoutePaths.suppliers,
          RoutePaths.b2bFulfillment,
        ];

        final isAccessingWholesalerPath = wholesalerPaths.any(
          (path) => state.matchedLocation.startsWith(path),
        );

        if (isAccessingWholesalerPath) {
          return RoutePaths.b2bCatalog;
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: RoutePaths.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RoutePaths.dashboard,
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: RoutePaths.inventory,
        builder: (context, state) => const InventoryListScreen(),
        routes: [
          GoRoute(
            path: 'add',
            builder: (context, state) => const AddProductScreen(),
          ),
          GoRoute(
            path: 'edit/:id',
            builder: (context, state) {
              final id = state.pathParameters['id'];
              return AddProductScreen(productId: id);
            },
          ),
          GoRoute(
            path: 'detail/:id',
            builder: (context, state) {
              final id = state.pathParameters['id'] ?? '';
              return ProductDetailScreen(productId: id);
            },
          ),
        ],
      ),
      GoRoute(
        path: RoutePaths.invoices,
        builder: (context, state) => const InvoiceListScreen(),
        routes: [
          GoRoute(
            path: 'create',
            builder: (context, state) => const CreateInvoiceScreen(),
          ),
          GoRoute(
            path: 'detail/:id',
            builder: (context, state) {
              final id = state.pathParameters['id'] ?? '';
              return InvoiceDetailScreen(invoiceId: id);
            },
          ),
        ],
      ),
      GoRoute(
        path: RoutePaths.suppliers,
        builder: (context, state) => const SupplierListScreen(),
        routes: [
          GoRoute(
            path: 'purchase-list',
            builder: (context, state) => const PurchaseListScreen(),
          ),
        ],
      ),
      GoRoute(
        path: RoutePaths.b2bCatalog,
        builder: (context, state) => const CustomerCatalogScreen(),
      ),
      GoRoute(
        path: RoutePaths.b2bLedger,
        builder: (context, state) => const LedgerScreen(),
      ),
      GoRoute(
        path: RoutePaths.b2bFulfillment,
        builder: (context, state) => const B2bFulfillmentScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri}'),
      ),
    ),
  );
});
