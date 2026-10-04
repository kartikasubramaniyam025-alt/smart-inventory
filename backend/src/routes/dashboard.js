const router = require('express').Router();
const pool = require('../db');

router.get('/dashboard', async (_req, res) => {
  const totals = (await pool.query(
    `SELECT COUNT(*)::int AS total_products,
            COALESCE(SUM(quantity),0)::int AS total_units,
            COALESCE(SUM(quantity*cost),0)::float AS stock_value,
            COUNT(*) FILTER (WHERE quantity <= min_stock)::int AS low_stock,
            COUNT(*) FILTER (WHERE quantity = 0)::int AS out_of_stock
     FROM products`)).rows[0];
  const recent = (await pool.query(
    `SELECT m.*, p.name AS product_name FROM stock_movements m
     JOIN products p ON p.id=m.product_id ORDER BY m.created_at DESC LIMIT 6`)).rows;
  const categories = (await pool.query('SELECT COUNT(*)::int AS n FROM categories')).rows[0].n;
  const suppliers = (await pool.query('SELECT COUNT(*)::int AS n FROM suppliers')).rows[0].n;
  res.json({ ...totals, categories, suppliers, recent });
});

router.get('/reports/stock-by-category', async (_req, res) => {
  const { rows } = await pool.query(
    `SELECT COALESCE(c.name,'Uncategorized') AS category, COUNT(p.id)::int AS products,
            COALESCE(SUM(p.quantity),0)::int AS units,
            COALESCE(SUM(p.quantity*p.cost),0)::float AS value
     FROM products p LEFT JOIN categories c ON c.id=p.category_id
     GROUP BY c.name ORDER BY value DESC`);
  res.json(rows);
});

module.exports = router;
