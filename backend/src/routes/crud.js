// Reusable CRUD router for simple tables (categories, suppliers)
const express = require('express');
const pool = require('../db');
const { adminOnly } = require('../middleware/auth');

module.exports = function crud(table, fields) {
  const router = express.Router();
  const pick = (b) => fields.map((f) => (b[f] === undefined ? null : b[f]));

  router.get('/', async (_req, res) =>
    res.json((await pool.query(`SELECT * FROM ${table} ORDER BY name`)).rows));

  router.post('/', async (req, res) => {
    if (!req.body.name) return res.status(400).json({ error: 'Name is required' });
    try {
      const ph = fields.map((_, i) => `$${i + 1}`).join(',');
      const { rows } = await pool.query(
        `INSERT INTO ${table} (${fields.join(',')}) VALUES (${ph}) RETURNING *`, pick(req.body));
      res.status(201).json(rows[0]);
    } catch (e) {
      res.status(e.code === '23505' ? 409 : 500).json({ error: e.code === '23505' ? 'Already exists' : 'Server error' });
    }
  });

  router.put('/:id', async (req, res) => {
    const set = fields.map((f, i) => `${f}=COALESCE($${i + 1},${f})`).join(',');
    const { rows } = await pool.query(
      `UPDATE ${table} SET ${set} WHERE id=$${fields.length + 1} RETURNING *`,
      [...pick(req.body), req.params.id]);
    rows[0] ? res.json(rows[0]) : res.status(404).json({ error: 'Not found' });
  });

  router.delete('/:id', adminOnly, async (req, res) => {
    await pool.query(`DELETE FROM ${table} WHERE id=$1`, [req.params.id]);
    res.json({ message: 'Deleted' });
  });
  return router;
};
