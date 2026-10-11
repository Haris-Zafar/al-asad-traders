import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'route_paths.dart';
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

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: RoutePaths.dashboard,
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
