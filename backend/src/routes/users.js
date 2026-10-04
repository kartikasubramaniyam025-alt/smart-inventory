const router = require('express').Router();
const pool = require('../db');
const { adminOnly } = require('../middleware/auth');

router.get('/', adminOnly, async (_req, res) =>
  res.json((await pool.query('SELECT id,name,email,role,created_at FROM users ORDER BY id')).rows));

router.put('/:id/role', adminOnly, async (req, res) => {
  if (!['admin', 'staff'].includes(req.body.role)) return res.status(400).json({ error: 'Invalid role' });
  const { rows } = await pool.query('UPDATE users SET role=$1 WHERE id=$2 RETURNING id,name,email,role', [req.body.role, req.params.id]);
  rows[0] ? res.json(rows[0]) : res.status(404).json({ error: 'Not found' });
});

router.delete('/:id', adminOnly, async (req, res) => {
  await pool.query('DELETE FROM users WHERE id=$1 AND id<>$2', [req.params.id, req.user.id]);
  res.json({ message: 'Deleted' });
});

module.exports = router;
