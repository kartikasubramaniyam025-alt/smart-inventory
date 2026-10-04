const router = require('express').Router();
const pool = require('../db');
const { adminOnly } = require('../middleware/auth');

const BASE = `SELECT p.*, c.name AS category_name, s.name AS supplier_name
  FROM products p LEFT JOIN categories c ON c.id=p.category_id
  LEFT JOIN suppliers s ON s.id=p.supplier_id`;

router.get('/', async (req, res) => {
  const { search, category_id, low } = req.query;
  const where = [], vals = [];
  if (search) { vals.push(`%${search}%`); where.push(`(p.name ILIKE $${vals.length} OR p.sku ILIKE $${vals.length})`); }
  if (category_id) { vals.push(category_id); where.push(`p.category_id=$${vals.length}`); }
  if (low === 'true') where.push('p.quantity <= p.min_stock');
  const sql = `${BASE} ${where.length ? 'WHERE ' + where.join(' AND ') : ''} ORDER BY p.name`;
  res.json((await pool.query(sql, vals)).rows);
});

router.get('/:id', async (req, res) => {
  const { rows } = await pool.query(`${BASE} WHERE p.id=$1`, [req.params.id]);
  rows[0] ? res.json(rows[0]) : res.status(404).json({ error: 'Product not found' });
});

router.post('/', async (req, res) => {
  const b = req.body;
  if (!b.name || !b.sku) return res.status(400).json({ error: 'Name and SKU are required' });
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const { rows } = await client.query(
      `INSERT INTO products (sku,name,description,category_id,supplier_id,price,cost,quantity,min_stock,unit)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10) RETURNING *`,
      [b.sku, b.name, b.description || '', b.category_id || null, b.supplier_id || null,
       b.price || 0, b.cost || 0, b.quantity || 0, b.min_stock ?? 10, b.unit || 'pcs']);
    if (Number(b.quantity) > 0)
      await client.query(
        `INSERT INTO stock_movements (product_id,user_id,type,quantity,note) VALUES ($1,$2,'IN',$3,'Opening stock')`,
        [rows[0].id, req.user.id, b.quantity]);
    await client.query('COMMIT');
    res.status(201).json(rows[0]);
  } catch (e) {
    await client.query('ROLLBACK');
    res.status(e.code === '23505' ? 409 : 500).json({ error: e.code === '23505' ? 'SKU already exists' : 'Server error' });
  } finally { client.release(); }
});

// UPDATE product (quantity is changed only through stock movements)
router.put('/:id', async (req, res) => {
  const b = req.body;
  try {
    const { rows } = await pool.query(
      `UPDATE products SET sku=COALESCE($1,sku), name=COALESCE($2,name), description=COALESCE($3,description),
        category_id=$4, supplier_id=$5, price=COALESCE($6,price), cost=COALESCE($7,cost),
        min_stock=COALESCE($8,min_stock), unit=COALESCE($9,unit), updated_at=NOW()
       WHERE id=$10 RETURNING *`,
      [b.sku, b.name, b.description, b.category_id || null, b.supplier_id || null,
       b.price, b.cost, b.min_stock, b.unit, req.params.id]);
    rows[0] ? res.json(rows[0]) : res.status(404).json({ error: 'Product not found' });
  } catch (e) {
    res.status(e.code === '23505' ? 409 : 500).json({ error: 'Could not update product' });
  }
});

router.delete('/:id', adminOnly, async (req, res) => {
  await pool.query('DELETE FROM products WHERE id=$1', [req.params.id]);
  res.json({ message: 'Deleted' });
});

module.exports = router;
