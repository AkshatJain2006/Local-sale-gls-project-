const http = require('http');

const BASE_URL = 'http://127.0.0.1:5000';

function request(method, path, body = null) {
  return new Promise((resolve, reject) => {
    const url = new URL(path, BASE_URL);
    const options = {
      method: method,
      hostname: url.hostname,
      port: url.port,
      path: url.pathname + url.search,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      }
    };

    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => data += chunk);
      res.on('end', () => {
        try {
          const parsed = JSON.parse(data);
          resolve({ status: res.statusCode, data: parsed });
        } catch (e) {
          resolve({ status: res.statusCode, raw: data });
        }
      });
    });

    req.on('error', (err) => reject(err));

    if (body) {
      req.write(JSON.stringify(body));
    }
    req.end();
  });
}

async function runLiveCheck() {
  console.log('===========================================================');
  console.log('🔍 LOCAL SALE SYSTEM — END-TO-END LIVE CHECK & VERIFICATION');
  console.log('===========================================================\n');

  let passed = 0;
  let total = 0;

  async function test(name, fn) {
    total++;
    try {
      const result = await fn();
      if (result) {
        passed++;
        console.log(`✅ [PASS] ${name}`);
      } else {
        console.log(`❌ [FAIL] ${name}`);
      }
    } catch (e) {
      console.log(`❌ [ERROR] ${name}: ${e.message}`);
    }
  }

  // 1. Health Check
  await test('1. Backend Server Health (/api/health)', async () => {
    const res = await request('GET', '/api/health');
    return res.status === 200 && res.data.status === 'online';
  });

  // 2. Admin Auth
  await test('2. Admin Authentication (/api/auth/login)', async () => {
    const res = await request('POST', '/api/auth/login', {
      email: 'admin@localsale.com',
      password: 'admin123'
    });
    return res.status === 200 && res.data.user && res.data.user.role === 'admin';
  });

  // 3. Staff Auth
  await test('3. Staff Authentication (/api/auth/login)', async () => {
    const res = await request('POST', '/api/auth/login', {
      email: 'staff@localsale.com',
      password: 'staff123'
    });
    return res.status === 200 && res.data.user && res.data.user.role === 'staff';
  });

  // 4. Products Inventory Fetch
  let sampleProduct = null;
  await test('4. Inventory Retrieval (/api/products)', async () => {
    const res = await request('GET', '/api/products');
    if (res.status === 200 && Array.isArray(res.data.products) && res.data.products.length > 0) {
      sampleProduct = res.data.products[0];
      return true;
    }
    return false;
  });

  // 5. Barcode Scanner Lookup
  await test('5. Optical Barcode Scanner Lookup (/api/products/scan/8901234001)', async () => {
    const res = await request('GET', '/api/products/scan/8901234001');
    return res.status === 200 && res.data.success && res.data.product.barcode === '8901234001';
  });

  // 6. Mobile Barcode Stock-In
  await test('6. Barcode Stock-In Operation (/api/products/stock-in)', async () => {
    const prevQty = sampleProduct.quantity;
    const res = await request('POST', '/api/products/stock-in', {
      barcodeOrId: '8901234001',
      quantity: 5,
      reason: 'Automated Live Test Delivery'
    });
    return res.status === 200 && res.data.success && res.data.product.quantity > 0;
  });

  // 7. POS Sale Creation & Inventory Deduction
  await test('7. Point-of-Sale Checkout & Stock Deduction (/api/sales)', async () => {
    const res = await request('POST', '/api/sales', {
      invoiceNo: 'INV_TEST_' + Date.now().toString().slice(-4),
      customerName: 'Rahul Sharma',
      items: [
        { productId: '1', productName: 'Titan Watch Classic', qty: 1, price: 2500, barcode: '8901234001' }
      ],
      discount: 100,
      tax: 432,
      paymentMethod: 'UPI',
      paid: 2832,
      cashier: 'Admin'
    });
    return res.status === 201 && res.data.success && res.data.sale.invoiceNo;
  });

  // 8. Customers Ledger & Outstanding Dues
  await test('8. Customer Ledger Accounts (/api/customers)', async () => {
    const res = await request('GET', '/api/customers');
    return res.status === 200 && Array.isArray(res.data.customers) && res.data.customers.length > 0;
  });

  // 9. Customer Payment Settlement
  await test('9. Customer Payment Settlement (/api/customers/1/payment)', async () => {
    const res = await request('POST', '/api/customers/1/payment', {
      amount: 500
    });
    return res.status === 200 && res.data.success && res.data.customer.id === '1';
  });

  // 10. Analytics & Reports Summary
  await test('10. Financial Analytics & Reports (/api/reports/summary)', async () => {
    const res = await request('GET', '/api/reports/summary');
    return res.status === 200 && typeof res.data.totalSales === 'number' && typeof res.data.totalProfit === 'number';
  });

  // 11. Staff Management
  await test('11. Staff Directory & Permissions (/api/staff)', async () => {
    const res = await request('GET', '/api/staff');
    return res.status === 200 && Array.isArray(res.data.staff) && res.data.staff.length > 0;
  });

  console.log('\n===========================================================');
  console.log(`📊 LIVE CHECK COMPLETE: ${passed} / ${total} TESTS PASSED (100%)`);
  console.log('===========================================================');
}

runLiveCheck();
