# Local Sale REST API Backend

A lightweight, zero-external-dependency Node.js REST API server with persistent JSON storage designed for the **Local Sale – Smart Sales Management System**.

---

## 🚀 Quick Start

### Start Server
```bash
# In project root:
node backend/server.js

# Or inside backend directory:
cd backend
npm start
```

Default server URL: `http://127.0.0.1:5000`

---

## 📡 API Endpoints Reference

### 1. System Health
- **`GET /api/health`**
  - Response: `{ status: "online", server: "Local Sale REST API", version: "2.0.0" }`

### 2. Authentication
- **`POST /api/auth/login`**
  - Body: `{ "email": "admin@localsale.com", "password": "admin123" }`
  - Response: `{ token: "...", user: { name: "Admin", role: "admin" } }`

### 3. Products & Barcode Scanning
- **`GET /api/products`** — Retrieve full product inventory.
- **`GET /api/products/scan/:barcode`** — Instant lookup of product by barcode / SKU.
- **`POST /api/products/stock-in`** — Add stock units to a product via barcode.
  - Body: `{ "barcodeOrId": "8901234001", "quantity": 10, "reason": "Restock Batch" }`
- **`POST /api/products`** — Create new product with barcode.
- **`POST /api/products/:id`** — Update existing product.

### 4. Sales & POS
- **`GET /api/sales`** — Retrieve sales history with itemized breakdown.
- **`POST /api/sales`** — Process new sale, deduct inventory, and update customer accounts.

### 5. Customers & Ledger
- **`GET /api/customers`** — List all customer accounts with outstanding dues.
- **`POST /api/customers`** — Register new customer account.
- **`POST /api/customers/:id/payment`** — Record customer payment and reduce outstanding balance.

### 6. Reports & Analytics
- **`GET /api/reports/summary`** — Retrieve revenue, net profit, pending dues, and inventory counts.

### 7. Staff Management
- **`GET /api/staff`** — List staff members, roles, and active status.
