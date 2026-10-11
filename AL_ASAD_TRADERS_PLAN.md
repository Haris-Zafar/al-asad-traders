# Wholesaler ERP & B2B Portal: Project Plan & Agent Instructions

> **Source of Truth:** This file defines the architecture, design system, data schema, rules, and step-by-step tasks for the Wholesaler Flutter App (Android & Web). Work **one task at a time**, verify constraints, run static code analysis, and create a Git commit after each step.

---

## 1. Architectural Strategy & Informed Package Choices

This project uses a **Pragmatic Feature-First Architecture**. It keeps features modular and co-located without enterprise over-engineering (no excessive domain/data clean architecture boilerplate).

### Production Packages

| Role | Package | Why Selected? |
|---|---|---|
| **State Management** | `flutter_riverpod` | Pure, compile-time safe providers without code-generation build delays (`build_runner`). |
| **Routing** | `go_router` | Native web route sync, URL parameters, and stateful bottom nav shell support. |
| **Backend** | `firebase_core`, `cloud_firestore`, `firebase_auth` | Real-time database for B2B ordering and instant synchronization. |
| **Media Storage** | `cloudinary_public` | Uploads product and invoice images directly via Cloudinary unsigned API without credit card requirements. |
| **Barcode/QR Scanner** | `mobile_scanner` | High-performance native camera scanner for mobile devices. |
| **PDF & Printing** | `pdf`, `printing` | Builds vector-perfect printable PKR invoice documents in memory. |
| **Social Export** | `share_plus` | Direct sharing of generated invoice PDFs/PNGs via WhatsApp and system share sheets. |
| **UI Aesthetics** | `google_fonts`, `flutter_svg`, `shimmer` | Executive-grade typography, SVG icons, and smooth skeleton loading indicators. |

---

## 2. UI/UX Design System & Theme Engine

The app follows a modern B2B ERP aesthetic built for clarity, fast physical data entry, and touch target accessibility.

### Theme Guidelines (`core/theme`)

- **Typography:** `GoogleFonts.plusJakartaSans()` for clean readability on dense data tables.
- **Color Palette:**
    - `Primary`: Deep Slate Navy (`#1E293B`) — Professional executive tone.
    - `Accent / Success`: Emerald Green (`#059669`) — Used for revenue, completed bills, and stock additions.
    - `Warning / Alert`: Warm Amber (`#D97706`) — Indicates price variations, low stock, or modified orders.
    - `Surface / Background`: Soft Off-White (`#F8FAFC`) on mobile; Crisp Card White (`#FFFFFF`) with subtle borders (`#E2E8F0`).
- **Input Fields:** Large `48px` minimum height text inputs with clear borders and bold label overlays for quick product searches.
- **Responsive Layout:**
    - **Mobile:** Single column, sticky bottom action bar (e.g., "Complete Invoice", "Share PDF").
    - **Web / Desktop:** 2-column split view (Catalog on the left, active invoice cart on the right).

---

## 3. Ground Rules for the AI Agent

1. **Integer PKR Currency Standard:** All monetary amounts MUST be represented as strict `int` values (`1200`, `15500`). **Never use `double` for PKR pricing.**
2. **Centralized Theme System:** Screen files must never hardcode colors or font sizes (`Color(0xFF...)` or `fontSize: 16`). Extract all styles from `Theme.of(context)` or `core/theme`.
3. **Route Safety:** Declare all route paths as static constants inside `core/router/route_paths.dart`.
4. **State Feedback Handling:** Every screen loading async data MUST handle Loading (Shimmer), Error, and Empty states.
5. **Execution Protocol:**
    - Complete **one sub-task at a time**.
    - Run `flutter analyze` after code changes and fix all warnings.
    - Provide a concise semantic Git commit message (e.g., `feat(invoice): add PKR snapshot item generator`).

---

## 4. Folder Structure

```text
lib/
├── main.dart                      // Firebase init, ProviderScope, runApp
├── app.dart                       // MaterialApp.router, theme initialization
│
├── core/
│   ├── theme/                     // Theme palette, styles, buttons, text fields
│   │   ├── app_colors.dart
│   │   ├── app_text_styles.dart
│   │   └── app_theme.dart
│   ├── router/                    // GoRouter configuration & routes
│   │   ├── app_router.dart
│   │   └── route_paths.dart
│   ├── services/                  // Shared Cloudinary & PDF export services
│   │   ├── cloudinary_service.dart
│   │   └── pdf_invoice_service.dart
│   ├── widgets/                   // Shared buttons, text inputs, shimmer loaders
│   └── utils/                     // PKR currency formatters, date formatters
│
└── features/
    ├── auth/                      // Login, role checking, user models
    ├── inventory/                 // Products, Supplier Costs, Barcode Scanner
    │   ├── models/                // ProductModel, SupplierCostModel
    │   ├── providers/             // InventoryNotifier
    │   ├── screens/               // InventoryListScreen, AddProductScreen
    │   ├── services/              // InventoryFirestoreService
    │   └── widgets/               // ProductCard, CostTile
    ├── invoices/                  // Billing, Scanner integration, PDF & WhatsApp
    │   ├── models/                // InvoiceModel, InvoiceItemSnapshot
    │   ├── providers/             // InvoiceBuilderNotifier
    │   ├── screens/               // CreateInvoiceScreen, InvoiceDetailScreen
    │   └── widgets/               // ScannerModal, InvoiceSummaryCard
    ├── suppliers/                 // Supplier Directory & Purchase List Generator
    │   ├── models/                // SupplierModel, PurchaseRequirement
    │   └── screens/               // SupplierListScreen, PurchaseListScreen
    └── b2b_portal/                // Customer Portal (10-20 Clients)
        ├── models/                // CustomerOrderModel
        ├── screens/               // CustomerCatalogScreen, LedgerScreen
        └── widgets/               // EstimatedBillCard, PayableSummary
```

---

## 5. Data Architecture (Firestore Schemas)

### `products/{productId}`

```json
{
  "id": "prod_101",
  "name": "Basmati Rice 5kg",
  "barcode": "8901234567890",
  "defaultWholesalePricePkr": 1200,
  "retailPricePkr": 1400,
  "currentStock": 150,
  "isArchived": false,
  "imageUrl": "https://res.cloudinary.com/...",
  "supplierCosts": {
    "supp_01": 1020,
    "supp_02": 1000
  },
  "customerPrices": {
    "cust_789": 1180
  }
}
```

### `invoices/{invoiceId}`

```json
{
  "id": "inv_5001",
  "customerId": "cust_789",
  "customerName": "Metro Supermarket",
  "createdAt": "2026-10-11T09:30:00Z",
  "items": [
    {
      "productId": "prod_101",
      "productName": "Basmati Rice 5kg",
      "unitPricePkr": 1180,
      "purchaseCostPkr": 1000,
      "quantity": 10,
      "subtotalPkr": 11800
    }
  ],
  "grandTotalPkr": 11800,
  "pdfCloudinaryUrl": ""
}
```

### `orders/{orderId}` (Customer B2B Portal)

```jsonc
{
  "id": "ord_881",
  "customerId": "cust_789",
  "status": "pending", // pending, adjusted, delivered, cancelled
  "requestedItems": [
    { "productId": "prod_101", "quantity": 10, "estimatedPricePkr": 1180 }
  ],
  "estimatedTotalPkr": 11800,
  "actualDeliveredTotalPkr": 11800,
  "adjustmentNote": "Full quantity fulfilled."
}
```

---

## 6. Phased Implementation Plan (Checklist)

### Phase 1: Project Skeleton & UI System

- [ ] **1.1 Folder Setup:** Create exact feature-first folder structure.
- [ ] **1.2 Package Dependencies:** Update `pubspec.yaml` with `flutter_riverpod`, `go_router`, `cloud_firestore`, `firebase_auth`, `cloudinary_public`, `mobile_scanner`, `pdf`, `printing`, `share_plus`, `google_fonts`, `flutter_svg`, `shimmer`.
- [ ] **1.3 Central Theme:** Create `app_colors.dart`, `app_text_styles.dart`, and `app_theme.dart` using Plus Jakarta Sans typography, dark slate primary color, rounded input fields, and emerald success states.
- [ ] **1.4 Currency Formatter:** Create `pkr_formatter.dart` utility (e.g., `1200` -> `Rs. 1,200`).
- [ ] **1.5 Route Config:** Set up `go_router` with static constants in `route_paths.dart`.

### Phase 2: Auth & Role Architecture

- [ ] **2.1 Auth Service & Riverpod:** Implement `FirebaseAuthService` and `authStateProvider`.
- [ ] **2.2 Login & Navigation Guards:** Build executive Login UI and route Wholesalers to Admin Dashboard and Customers (10–20 clients) to the B2B Order Catalog.

### Phase 3: Inventory, Archiving & Supplier Linkage

- [ ] **3.1 Product & Supplier Models:** Create `ProductModel` and `SupplierCostModel` using strict integer fields for all PKR amounts.
- [ ] **3.2 Cloudinary Service:** Implement direct unsigned image upload service via `cloudinary_public`.
- [ ] **3.3 Inventory UI:**
    - Product list with search bar, low-stock badge, and active/archived toggle filter.
    - Product creation form (Name, Barcode, Default Wholesale Price PKR, Retail Price PKR, Image Picker).
    - Archiving trigger (retains historical data while hiding product from active catalog).
- [ ] **3.4 Supplier Costs:** UI section on the product detail page to link multiple suppliers and record their specific purchase costs in PKR.

### Phase 4: Invoice Engine, Scanner & WhatsApp Export

- [ ] **4.1 Barcode Scanner Modal:** Integrate `mobile_scanner` modal sheet for fast item adding via camera feed.
- [ ] **4.2 Invoice Creator Screen:**
    - Customer select dropdown (automatically applies customer-specific price or default wholesale price).
    - Manual product lookup + QR/Barcode scanner trigger.
    - Dynamic invoice cart with quantity adjustment and integer PKR sum calculation.
    - Price Snapshot logic: snapshot exact unit price and purchase cost into invoice payload.
- [ ] **4.3 PDF Generator & WhatsApp Integration:**
    - Implement dynamic PDF builder layout using `pdf` & `printing` packages (Company branding, Customer details, Itemized table with PKR totals, and QR verification code).
    - Direct share trigger via `share_plus` sending PDF/PNG binaries directly to WhatsApp contact numbers.

### Phase 5: Supplier Registry & Purchase List Builder

- [ ] **5.1 Supplier Directory:** CRUD view for managing seller contact info and catalog items.
- [ ] **5.2 Automated Purchase List:**
    - Screen calculating total stock deficiencies.
    - Compare supplier options for each low-stock item to highlight the cheapest supplier cost option.

### Phase 6: B2B Customer Portal & Ledger (10–20 Clients)

- [ ] **6.1 B2B Product Catalog:** Simplified grid view for logged-in B2B customers showing available products with their specific custom wholesale price.
- [ ] **6.2 B2B Order Placement:** Customer order cart with estimated total PKR warning note.
- [ ] **6.3 Wholesaler Fulfillment Portal:**
    - Review incoming B2B orders.
    - Modify actual delivered quantity during dispatch.
    - Convert approved order directly into a finalized PKR Invoice.
- [ ] **6.4 Customer Ledger View:** Simple balance statement screen showing pending orders, payment history, and total outstanding payable PKR balance.

### Phase 7: Web/Mobile Polish & Code Quality

- [ ] **7.1 Responsive Web Layout Pass:** Implement split-screen layouts for Web screens (> 900px).
- [ ] **7.2 Error & Skeleton States:** Ensure all async Firestore feeds implement shimmer placeholders for loading states.
- [ ] **7.3 Static Analysis:** Run `flutter analyze` across the project, eliminate warnings, enforce `const` usage, and complete final testing.
