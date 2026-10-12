const router = require('express').Router();
const pool = require('../db');

// Creates the table automatically the first time the server starts
pool
  .query(`CREATE TABLE IF NOT EXISTS enquiries (
    id SERIAL PRIMARY KEY,
    product_id INTEGER,
    name TEXT NOT NULL,
    email TEXT,
    phone TEXT,
    message TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'new',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
  )`)
  .catch((e) => console.error('enquiries table error:', e.message));

const num = (v) => {
  const n = parseInt(v, 10);
  return Number.isNaN(n) ? null : n;
};

const SELECT = `
  SELECT p.id, p.name, p.description, p.price, p.unit, c.name AS category_name,
    CASE WHEN p.quantity <= 0 THEN 'out'
         WHEN p.quantity <= p.min_stock THEN 'low'
         ELSE 'in' END AS availability
  FROM products p LEFT JOIN categories c ON c.id = p.category_id`;

router.get('/categories', async (_req, res) => {
  try {
    const { rows } = await pool.query('SELECT id, name FROM categories ORDER BY name');
    res.json(rows);
  } catch (e) {
    res.status(500).json({ error: 'Server error' });
  }
});

router.get('/products', async (req, res) => {
  try {
    const search = (req.query.search || '').toString().trim() || null;
    const cat = num(req.query.category_id);
    const { rows } = await pool.query(
      `${SELECT}
       WHERE ($1::text IS NULL OR p.name ILIKE '%' || $1 || '%')
         AND ($2::int IS NULL OR p.category_id = $2)
       ORDER BY p.name LIMIT 200`,
      [search, cat]
    );
    res.json(rows);
  } catch (e) {
    res.status(500).json({ error: 'Server error' });
  }
});

router.get('/products/:id', async (req, res) => {
  const id = num(req.params.id);
  if (id === null) return res.status(400).json({ error: 'Invalid product' });
  try {
    const { rows } = await pool.query(`${SELECT} WHERE p.id = $1`, [id]);
    if (!rows[0]) return res.status(404).json({ error: 'Product not found' });
    res.json(rows[0]);
  } catch (e) {
    res.status(500).json({ error: 'Server error' });
  }
});

router.post('/enquiries', async (req, res) => {
  const b = req.body || {};
  const clean = (v, max) => (v == null ? '' : String(v).trim().slice(0, max));
  const name = clean(b.name, 100);
  const email = clean(b.email, 150);
  const phone = clean(b.phone, 30);
  const message = clean(b.message, 2000);
  if (!name || !message || (!email && !phone))
    return res.status(400).json({ error: 'Name, message and an email or phone are required' });
  try {
    await pool.query(
      'INSERT INTO enquiries (product_id, name, email, phone, message) VALUES ($1,$2,$3,$4,$5)',
      [num(b.product_id), name, email || null, phone || null, message]
    );
    res.status(201).json({ message: 'Thank you! We will contact you soon.' });
  } catch (e) {
    res.status(500).json({ error: 'Server error' });
  }
});

module.exports = router;