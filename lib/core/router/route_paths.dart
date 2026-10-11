/// Centralized route path constants
abstract class RoutePaths {
  static const String initial = '/';
  static const String login = '/login';
  static const String dashboard = '/dashboard';

  // Inventory
  static const String inventory = '/inventory';
  static const String addProduct = '/inventory/add';
  static const String editProduct = '/inventory/edit/:id';
  static const String productDetail = '/inventory/detail/:id';

  // Invoices
  static const String invoices = '/invoices';
  static const String createInvoice = '/invoices/create';
  static const String invoiceDetail = '/invoices/detail/:id';

  // Suppliers
  static const String suppliers = '/suppliers';
  static const String purchaseList = '/suppliers/purchase-list';

  // B2B Customer Portal & Fulfillment
  static const String b2bCatalog = '/b2b/catalog';
  static const String b2bOrder = '/b2b/order';
  static const String b2bLedger = '/b2b/ledger';
  static const String b2bFulfillment = '/b2b/fulfillment';

  // Helpers for dynamic paths
  static String editProductPath(String id) => '/inventory/edit/$id';
  static String productDetailPath(String id) => '/inventory/detail/$id';
  static String invoiceDetailPath(String id) => '/invoices/detail/$id';
}
