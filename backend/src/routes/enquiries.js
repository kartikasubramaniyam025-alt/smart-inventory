const router = require('express').Router();
const pool = require('../db');

const adminOnly = (req, res, next) =>
  req.user && req.user.role === 'admin'
    ? next()
    : res.status(403).json({ error: 'Admin access required' });

router.get('/', adminOnly, async (_req, res) => {
  try {
    const { rows } = await pool.query(
      `SELECT e.*, p.name AS product_name
       FROM enquiries e LEFT JOIN products p ON p.id = e.product_id
       ORDER BY e.created_at DESC LIMIT 200`
    );
    res.json(rows);
  } catch (e) {
    res.status(500).json({ error: 'Server error' });
  }
});

router.put('/:id/status', adminOnly, async (req, res) => {
  const id = parseInt(req.params.id, 10);
  const status = (req.body || {}).status;
  if (Number.isNaN(id) || !['new', 'done'].includes(status))
    return res.status(400).json({ error: 'Invalid request' });
  try {
    const { rows } = await pool.query('UPDATE enquiries SET status=$1 WHERE id=$2 RETURNING *', [status, id]);
    if (!rows[0]) return res.status(404).json({ error: 'Not found' });
    res.json(rows[0]);
  } catch (e) {
    res.status(500).json({ error: 'Server error' });
  }
});

module.exports = router;