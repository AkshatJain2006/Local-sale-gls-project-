# LOCAL SALE — Smart POS & Sales Management System

A Flutter-based Point-of-Sale application built for small retail businesses.
Runs fully offline on Android tablets. Supports barcode scanning, PDF receipts,
Excel export, partial payments, staff accounts, and optional backend sync.

---

## Project Structure

```
local_sale/
├── android/
├── ios/
├── lib/
│   ├── main.dart
│   ├── models/
│   │   ├── product.dart
│   │   ├── sale.dart
│   │   └── customer.dart
│   ├── screens/
│   │   ├── login_screen.dart
│   │   ├── dashboard_screen.dart
│   │   ├── inventory_screen.dart
│   │   ├── sales_screen.dart
│   │   ├── billing_screen.dart
│   │   ├── customers_screen.dart
│   │   ├── reports_screen.dart
│   │   ├── staff_management_screen.dart
│   │   └── settings_screen.dart
│   ├── services/
│   │   ├── auth_service.dart
│   │   ├── data_service.dart
│   │   ├── settings_service.dart
│   │   └── api_service.dart
│   └── widgets/
│       ├── barcode_scanner_modal.dart
│       ├── custom_button.dart
│       ├── dashboard_card.dart
│       ├── product_card.dart
│       └── sale_card.dart
├── test/
└── pubspec.yaml
```

---

## Features

### Authentication
- First-run admin setup screen — no hardcoded accounts
- Admin creates staff accounts with name, email, password, and role
- Roles: `admin`, `manager`, `cashier`, `staff`
- Per-account active/inactive toggle and password reset
- All accounts persisted via `SharedPreferences`

### Dashboard
- Live stats: Today's Sales, Inventory Items, Gross Profit, Pending Dues
- Quick actions: Scan & Stock In, New POS Sale, Invoice History, Reports, Staff Management
- Low stock alerts with inline restock shortcut
- Recent sales activity feed
- Responsive layout — NavigationRail on tablets (≥600px), BottomNavigationBar on phones

### POS / Sales Screen
- Add products by name search or barcode scan
- Quantity adjustment, per-item pricing
- Discount field
- Payment modes: Paid Full / Partial Payment / Unpaid (credit)
- Payment methods: Cash, UPI, Card, Credit
- Cashier name stamped on every sale from logged-in user
- Invoice number auto-generated

### Billing / Invoice Screen
- Full invoice view: business header, items table, totals, payment history, footer
- Payment status badge: Paid / Partially Paid / Unpaid
- Share PDF via system share sheet (WhatsApp, Gmail, etc.)
- Print PDF via `printing` package
- PDF generated with `pdf` package — A4 format

### Inventory Management
- Add / edit / delete products
- Fields: name, category, barcode, supplier, purchase price, selling price, quantity, min stock
- Low stock detection (`quantity <= minStock`)
- Barcode scan to stock in — opens camera scanner modal
- Stock-in history log

### Customer Management
- Add customers with name, phone, email, address
- Transaction ledger per customer (sales + payments)
- Outstanding balance tracking (`totalPurchase - totalPaid`)
- Blacklist toggle
- Collect payment against outstanding balance

### Partial Payments
- `SalePayment` model: amount, date, method
- `paymentHistory` list on each `Sale`
- `paymentStatus` derived getter: `Paid` / `Partially Paid` / `Unpaid`
- `collectPayment()` in `DataService` — prevents overpayment
- Collect button in sales history list

### Staff Management
- Lists all non-admin accounts from `AuthService`
- Accounts tab: avatar, role badge, active/inactive switch, reset password, delete
- Performance tab: per-staff sales count, revenue, profit — sorted by revenue
- Rank medals: 🥇🥈🥉 for top 3
- Add Staff dialog with role dropdown

### Reports
- Sales analytics screen (admin only)

### Settings
- Business Details card: name, GSTIN, address, phone, email, receipt footer
- Live preview of business name and GSTIN as you type
- Update & Save (persisted to `SharedPreferences`)
- Export to Excel: 3-sheet `.xlsx` (Sales, Inventory, Customers) — colour-coded headers, auto-fit columns, shared via system share sheet
- Backend API card: configure Node.js REST endpoint, test connection, trigger sync
- Barcode scanner info card
- App version display
- Sign Out

---

## Data Models

### `Product`
| Field | Type | Notes |
|---|---|---|
| id | String | unique |
| name | String | |
| category | String | |
| barcode | String | EAN/UPC/QR |
| supplier | String | |
| purchasePrice | double | |
| sellingPrice | double | |
| quantity | int | mutable |
| minStock | int | low-stock threshold |
| isLowStock | bool (getter) | `quantity <= minStock` |
| profitMargin | double (getter) | % |

### `Sale`
| Field | Type | Notes |
|---|---|---|
| invoiceNo | String | |
| customerName | String | |
| customerPhone | String | |
| date | DateTime | |
| items | List\<SaleItem\> | |
| discount | double | |
| tax | double | always 0 (removed) |
| paymentMethod | String | Cash/UPI/Card/Credit |
| paid | double | mutable |
| cashier | String | logged-in user name |
| paymentHistory | List\<SalePayment\> | |
| subtotal | double (getter) | sum of items |
| total | double (getter) | subtotal − discount |
| due | double (getter) | total − paid |
| paymentStatus | String (getter) | Paid / Partially Paid / Unpaid |

### `SalePayment`
| Field | Type |
|---|---|
| amount | double |
| date | DateTime |
| method | String |

### `Customer`
| Field | Type | Notes |
|---|---|---|
| id | String | |
| name | String | |
| phone | String | |
| email | String | |
| address | String | |
| totalPurchase | double | mutable |
| totalPaid | double | mutable |
| transactions | List\<CustomerTransaction\> | |
| isBlacklisted | bool | mutable |
| outstanding | double (getter) | totalPurchase − totalPaid |

### `AppUser` (AuthService)
| Field | Type | Notes |
|---|---|---|
| id | String | timestamp-based |
| name | String | |
| email | String | lowercase |
| passwordHash | String | plain text (no sensitive data) |
| role | String | admin / manager / cashier / staff |
| isActive | bool | |

---

## Services

### `AuthService` (singleton, `ChangeNotifier`)
- Persists user list to `SharedPreferences` as JSON (`auth_users`)
- `hasAdmin` — whether any admin account exists
- `staffOnly` — all non-admin users
- `createAdmin()` / `createStaff()` — returns error string or null
- `updateUser()` / `deleteUser()`
- `login(email, password)` — returns `AppUser?`

### `DataService` (singleton, `ChangeNotifier`)
- In-memory store for products, sales, customers, stock logs
- No mock data — starts empty
- `addSale()` — deducts stock, updates customer ledger, seeds payment history
- `collectPayment()` — adds to `paymentHistory`, updates customer ledger
- `stockInProduct()` — adds quantity, logs to `_stockLogs`
- `staffStats(staffName)` — returns `{salesCount, revenue, profit}` from actual sales
- `todaySalesTotal`, `totalProfit`, `totalPendingDues`, `lowStockProducts`
- Optional backend sync via `ApiService`

### `SettingsService` (singleton, `ChangeNotifier`)
- `SharedPreferences` keys: `biz_name`, `biz_address`, `biz_phone`, `biz_email`, `biz_gstin`, `biz_footer`
- `load()` on app startup
- `save()` — updates in-memory fields and persists

### `ApiService`
- Optional Node.js REST backend integration
- `checkHealth()`, `get()`, `post()`
- Offline-first — all features work without a backend

---

## Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  mobile_scanner: ^5.2.3        # barcode / QR camera scanning
  shared_preferences: ^2.3.2    # settings + auth persistence
  syncfusion_flutter_xlsio: ^27.1.48  # Excel export
  path_provider: ^2.1.4         # temp directory for file export
  share_plus: ^9.0.0            # system share sheet
  pdf: ^3.11.1                  # PDF receipt generation
  printing: ^5.13.1             # PDF share + print

dependency_overrides:
  path_provider_foundation: 2.3.2   # prevents objective_c hook failure on paths with spaces
```

---

## Build & Run

**Target device:** Samsung Galaxy Tab S10 FE — Android 16 — device ID `RZGL12DSLGZ`

> Flutter is installed at `D:\flutter sdk\flutter` (space in path).
> Always use `--android-skip-build-dependency-validation` to avoid native hook failures.

```bat
:: Run on device
"D:\flutter sdk\flutter\bin\flutter.bat" run -d RZGL12DSLGZ --android-skip-build-dependency-validation

:: Build debug APK
"D:\flutter sdk\flutter\bin\flutter.bat" build apk --debug --android-skip-build-dependency-validation
```

> Kotlin daemon incremental cache warnings during build are non-fatal and caused by the space in `D:\gls sale\`. They do not affect the APK.

---

## Known Limitations / Phase 2 Planned

| Item | Status |
|---|---|
| Sales / Products / Customers persistence | ❌ In-memory only — resets on restart |
| Full offline persistence (Hive / SQLite) | 📋 Phase 2 |
| Backend Node.js REST API | 📋 Phase 2 |
| Role-based screen restrictions | 📋 Phase 2 |
| Multi-currency support | 📋 Phase 2 |
| Tax / GST line items | ❌ Removed by design |

---

## Changelog

| Version | Changes |
|---|---|
| v2.0.0 | Auth system (AuthService + first-run setup), staff management with per-staff stats, partial payments, PDF receipts, Excel export, business settings persistence, barcode scan & stock-in, no mock data |
| v1.0.0 | Initial Flutter scaffold |
