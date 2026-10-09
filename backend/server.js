require('dotenv').config();
const express = require('express');
const cors = require('cors');
const mongoose = require('mongoose');

const app = express();
app.use(cors());
app.use(express.json());

// ── MongoDB Connection ────────────────────────────────────────────────────────

mongoose.connect(process.env.MONGODB_URI)
  .then(() => console.log('✅ MongoDB Atlas connected'))
  .catch(err => { console.error('❌ MongoDB connection failed:', err.message); process.exit(1); });

// ── Schemas ───────────────────────────────────────────────────────────────────

const ProductSchema = new mongoose.Schema({
  id:            { type: String, required: true, unique: true },
  name:          { type: String, required: true },
  category:      { type: String, default: 'General' },
  purchasePrice: { type: Number, default: 0 },
  sellingPrice:  { type: Number, default: 0 },
  quantity:      { type: Number, default: 0 },
  minStock:      { type: Number, default: 5 },
  supplier:      { type: String, default: '' },
  barcode:       { type: String, default: '' },
}, { timestamps: true });

const SaleItemSchema = new mongoose.Schema({
  productId:   { type: String, default: '' },
  productName: { type: String, required: true },
  qty:         { type: Number, required: true },
  price:       { type: Number, required: true },
  barcode:     { type: String, default: '' },
}, { _id: false });

const SalePaymentSchema = new mongoose.Schema({
  amount: { type: Number, required: true },
  date:   { type: Date, default: Date.now },
  method: { type: String, default: 'Cash' },
}, { _id: false });

const SaleSchema = new mongoose.Schema({
  invoiceNo:      { type: String, required: true, unique: true },
  customerName:   { type: String, default: 'Walk-in Customer' },
  customerPhone:  { type: String, default: '' },
  date:           { type: Date, default: Date.now },
  items:          [SaleItemSchema],
  discount:       { type: Number, default: 0 },
  tax:            { type: Number, default: 0 },
  paymentMethod:  { type: String, default: 'Cash' },
  paid:           { type: Number, default: 0 },
  cashier:        { type: String, default: 'Admin' },
  paymentHistory: [SalePaymentSchema],
}, { timestamps: true });

const TransactionSchema = new mongoose.Schema({
  id:          { type: String },
  date:        { type: String },
  amount:      { type: Number },
  description: { type: String },
  type:        { type: String },
}, { _id: false });

const CustomerSchema = new mongoose.Schema({
  id:            { type: String, required: true, unique: true },
  name:          { type: String, required: true },
  phone:         { type: String, default: '' },
  email:         { type: String, default: '' },
  address:       { type: String, default: '' },
  totalPurchase: { type: Number, default: 0 },
  totalPaid:     { type: Number, default: 0 },
  isBlacklisted: { type: Boolean, default: false },
  transactions:  [TransactionSchema],
}, { timestamps: true });

const StaffSchema = new mongoose.Schema({
  id:         { type: String, required: true, unique: true },
  name:       { type: String, required: true },
  role:       { type: String, default: 'Staff' },
  email:      { type: String, default: '' },
  active:     { type: Boolean, default: true },
  salesCount: { type: Number, default: 0 },
}, { timestamps: true });

const StockLogSchema = new mongoose.Schema({
  productId:     String,
  productName:   String,
  barcode:       String,
  quantityAdded: Number,
  newQuantity:   Number,
  reason:        { type: String, default: 'Stock In' },
}, { timestamps: true });

const Product  = mongoose.model('Product',  ProductSchema);
const Sale     = mongoose.model('Sale',     SaleSchema);
const Customer = mongoose.model('Customer', CustomerSchema);
const Staff    = mongoose.model('Staff',    StaffSchema);
const StockLog = mongoose.model('StockLog', StockLogSchema);

// ── Health ────────────────────────────────────────────────────────────────────

app.get('/api/health', (req, res) => {
  res.json({ status: 'online', server: 'Local Sale REST API', version: '2.0.0', timestamp: new Date().toISOString() });
});

// ── Products ──────────────────────────────────────────────────────────────────

app.get('/api/products', async (req, res) => {
  const products = await Product.find().lean();
  res.json({ products });
});

app.post('/api/products', async (req, res) => {
  const data = { ...req.body, id: req.body.id || String(Date.now()) };
  const product = await Product.findOneAndUpdate(
    { id: data.id },
    data,
    { upsert: true, new: true, setDefaultsOnInsert: true }
  ).lean();
  res.status(201).json({ success: true, product });
});

// Update product by id
app.post('/api/products/:id', async (req, res) => {
  const product = await Product.findOneAndUpdate(
    { id: req.params.id },
    { ...req.body, id: req.params.id },
    { new: true }
  ).lean();
  if (!product) return res.status(404).json({ error: 'Product not found' });
  res.json({ success: true, product });
});

// Barcode scan lookup
app.get('/api/products/scan/:barcode', async (req, res) => {
  const code = req.params.barcode.trim().toLowerCase();
  const product = await Product.findOne({
    $or: [
      { barcode: { $regex: new RegExp(`^${code}$`, 'i') } },
      { id: code }
    ]
  }).lean();
  if (!product) return res.status(404).json({ success: false, error: `Barcode "${code}" not found` });
  res.json({ success: true, product });
});

// Stock In
app.post('/api/products/stock-in', async (req, res) => {
  const { barcodeOrId, quantity, reason } = req.body;
  const qty = parseInt(quantity, 10);
  if (!barcodeOrId || isNaN(qty) || qty <= 0) {
    return res.status(400).json({ error: 'Valid barcodeOrId and positive quantity required' });
  }
  const code = String(barcodeOrId).trim().toLowerCase();
  const product = await Product.findOneAndUpdate(
    { $or: [{ barcode: { $regex: new RegExp(`^${code}$`, 'i') } }, { id: code }] },
    { $inc: { quantity: qty } },
    { new: true }
  ).lean();
  if (!product) return res.status(404).json({ error: `Product "${barcodeOrId}" not found` });

  const log = await StockLog.create({
    productId: product.id, productName: product.name,
    barcode: product.barcode, quantityAdded: qty,
    newQuantity: product.quantity, reason: reason || 'Barcode Scan Stock-In',
  });
  res.json({ success: true, product, log });
});

// ── Sales ─────────────────────────────────────────────────────────────────────

app.get('/api/sales', async (req, res) => {
  const sales = await Sale.find().sort({ date: -1 }).lean();
  res.json({ sales });
});

app.post('/api/sales', async (req, res) => {
  const body = req.body;
  const sale = await Sale.create({
    invoiceNo:     body.invoiceNo || `INV${String(Date.now()).slice(-6)}`,
    customerName:  body.customerName || 'Walk-in Customer',
    customerPhone: body.customerPhone || '',
    date:          body.date ? new Date(body.date) : new Date(),
    items:         body.items || [],
    discount:      parseFloat(body.discount) || 0,
    tax:           parseFloat(body.tax) || 0,
    paymentMethod: body.paymentMethod || 'Cash',
    paid:          parseFloat(body.paid) || 0,
    cashier:       body.cashier || 'Admin',
    paymentHistory: body.paymentHistory || [],
  });

  // Deduct stock for each item sold
  for (const item of sale.items) {
    await Product.findOneAndUpdate(
      { $or: [{ id: item.productId }, { name: { $regex: new RegExp(`^${item.productName}$`, 'i') } }] },
      { $inc: { quantity: -item.qty } }
    );
  }

  // Update customer ledger
  if (body.customerName && body.customerName !== 'Walk-in Customer') {
    const subtotal = sale.items.reduce((s, i) => s + i.price * i.qty, 0);
    const total = Math.max(0, subtotal - sale.discount);
    await Customer.findOneAndUpdate(
      { name: { $regex: new RegExp(`^${body.customerName}$`, 'i') } },
      {
        $inc: { totalPurchase: total, totalPaid: sale.paid },
        $push: { transactions: { $each: [{ id: `txn_${Date.now()}`, date: 'Just now', amount: total, description: `Invoice #${sale.invoiceNo}`, type: 'sale' }], $position: 0 } }
      }
    );
  }

  res.status(201).json({ success: true, sale });
});

// ── Customers ─────────────────────────────────────────────────────────────────

app.get('/api/customers', async (req, res) => {
  const customers = await Customer.find().lean();
  res.json({ customers });
});

app.post('/api/customers', async (req, res) => {
  const data = { ...req.body, id: req.body.id || String(Date.now()) };
  const customer = await Customer.findOneAndUpdate(
    { id: data.id },
    data,
    { upsert: true, new: true, setDefaultsOnInsert: true }
  ).lean();
  res.status(201).json({ success: true, customer });
});

app.post('/api/customers/:id/payment', async (req, res) => {
  const amount = parseFloat(req.body.amount) || 0;
  if (amount <= 0) return res.status(400).json({ error: 'Invalid amount' });
  const customer = await Customer.findOneAndUpdate(
    { id: req.params.id },
    {
      $inc: { totalPaid: amount },
      $push: { transactions: { $each: [{ id: `pay_${Date.now()}`, date: 'Today', amount, description: 'Payment Received', type: 'payment' }], $position: 0 } }
    },
    { new: true }
  ).lean();
  if (!customer) return res.status(404).json({ error: 'Customer not found' });
  res.json({ success: true, customer });
});

// ── Staff ─────────────────────────────────────────────────────────────────────

app.get('/api/staff', async (req, res) => {
  const staff = await Staff.find().lean();
  res.json({ staff });
});

app.post('/api/staff', async (req, res) => {
  const data = { ...req.body, id: req.body.id || String(Date.now()) };
  const member = await Staff.findOneAndUpdate(
    { id: data.id },
    data,
    { upsert: true, new: true, setDefaultsOnInsert: true }
  ).lean();
  res.status(201).json({ success: true, staff: member });
});

// ── Reports ───────────────────────────────────────────────────────────────────

app.get('/api/reports/summary', async (req, res) => {
  const [sales, products, customers] = await Promise.all([
    Sale.find().lean(),
    Product.find().lean(),
    Customer.find().lean(),
  ]);

  const totalSales = sales.reduce((sum, s) => {
    return sum + Math.max(0, s.items.reduce((a, i) => a + i.price * i.qty, 0) - s.discount);
  }, 0);

  const totalProfit = sales.reduce((sum, s) => {
    for (const item of s.items) {
      const prod = products.find(p => p.name.toLowerCase() === item.productName.toLowerCase());
      const cost = prod ? prod.purchasePrice : item.price * 0.7;
      sum += (item.price - cost) * item.qty;
    }
    return sum;
  }, 0);

  const totalDues = customers.reduce((sum, c) => sum + Math.max(0, c.totalPurchase - c.totalPaid), 0);

  res.json({ totalSales, totalProfit, totalDues, productCount: products.length, salesCount: sales.length, customerCount: customers.length });
});

// ── Root ──────────────────────────────────────────────────────────────────────

app.get('/', (req, res) => {
  res.json({
    status: 'online',
    server: 'Local Sale REST API',
    version: '2.0.0',
    db: mongoose.connection.readyState === 1 ? 'MongoDB Atlas connected' : 'disconnected',
    endpoints: ['/api/health', '/api/products', '/api/products/scan/:barcode', '/api/products/stock-in', '/api/sales', '/api/customers', '/api/staff', '/api/reports/summary'],
  });
});

// ── Start ─────────────────────────────────────────────────────────────────────

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`🚀 Local Sale API running on port ${PORT}`);
});
