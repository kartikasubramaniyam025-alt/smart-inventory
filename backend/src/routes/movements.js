const router = require('express').Router();
const pool = require('../db');

router.get('/', async (req, res) => {
  const vals = [], where = [];
  if (req.query.product_id) { vals.push(req.query.product_id); where.push(`m.product_id=$1`); }
  const { rows } = await pool.query(
    `SELECT m.*, p.name AS product_name, p.sku, u.name AS user_name
     FROM stock_movements m JOIN products p ON p.id=m.product_id
     LEFT JOIN users u ON u.id=m.user_id
     ${where.length ? 'WHERE ' + where.join(' AND ') : ''}
     ORDER BY m.created_at DESC LIMIT 200`, vals);
  res.json(rows);
});

// type IN adds, OUT subtracts, ADJUST sets the quantity to an exact value
router.post('/', async (req, res) => {
  const { product_id, type, quantity, note } = req.body;
  const qty = parseInt(quantity, 10);
  if (!product_id || !['IN', 'OUT', 'ADJUST'].includes(type) || isNaN(qty) || qty < 0 || (type !== 'ADJUST' && qty === 0))
    return res.status(400).json({ error: 'Valid product, type and quantity are required' });
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const cur = await client.query('SELECT quantity FROM products WHERE id=$1 FOR UPDATE', [product_id]);
    if (!cur.rows[0]) { await client.query('ROLLBACK'); return res.status(404).json({ error: 'Product not found' }); }
    const old = cur.rows[0].quantity;
    const next = type === 'IN' ? old + qty : type === 'OUT' ? old - qty : qty;
    if (next < 0) { await client.query('ROLLBACK'); return res.status(400).json({ error: `Only ${old} in stock` }); }
    await client.query('UPDATE products SET quantity=$1, updated_at=NOW() WHERE id=$2', [next, product_id]);
    const { rows } = await client.query(
      'INSERT INTO stock_movements (product_id,user_id,type,quantity,note) VALUES ($1,$2,$3,$4,$5) RETURNING *',
      [product_id, req.user.id, type, qty, note || '']);
    await client.query('COMMIT');
    res.status(201).json({ ...rows[0], new_quantity: next });
  } catch (e) {
    await client.query('ROLLBACK');
    res.status(500).json({ error: 'Server error' });
  } finally { client.release(); }
});

module.exports = router;
