const router = require('express').Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const pool = require('../db');
const { auth } = require('../middleware/auth');

const sign = (u) =>
  jwt.sign({ id: u.id, role: u.role, name: u.name }, process.env.JWT_SECRET, { expiresIn: '7d' });
const publicUser = (u) => ({ id: u.id, name: u.name, email: u.email, role: u.role });

router.post('/register', async (req, res) => {
  const { name, email, password } = req.body;
  if (!name || !email || !password || password.length < 6)
    return res.status(400).json({ error: 'Name, email and password (min 6 chars) are required' });
  try {
    const hash = await bcrypt.hash(password, 10);
    const count = (await pool.query('SELECT COUNT(*) FROM users')).rows[0].count;
    const role = Number(count) === 0 ? 'admin' : 'staff';
    const { rows } = await pool.query(
      'INSERT INTO users (name,email,password_hash,role) VALUES ($1,$2,$3,$4) RETURNING *',
      [name, email.toLowerCase(), hash, role]);
    res.status(201).json({ token: sign(rows[0]), user: publicUser(rows[0]) });
  } catch (e) {
    if (e.code === '23505') return res.status(409).json({ error: 'Email already registered' });
    res.status(500).json({ error: 'Server error' });
  }
});

router.post('/login', async (req, res) => {
  const { email, password } = req.body;
  const { rows } = await pool.query('SELECT * FROM users WHERE email=$1', [(email || '').toLowerCase()]);
  const u = rows[0];
  if (!u || !(await bcrypt.compare(password || '', u.password_hash)))
    return res.status(401).json({ error: 'Invalid email or password' });
  res.json({ token: sign(u), user: publicUser(u) });
});

router.get('/me', auth, async (req, res) => {
  const { rows } = await pool.query('SELECT * FROM users WHERE id=$1', [req.user.id]);
  if (!rows[0]) return res.status(404).json({ error: 'User not found' });
  res.json(publicUser(rows[0]));
});

// UPDATE profile
router.put('/me', auth, async (req, res) => {
  const { name, email } = req.body;
  try {
    const { rows } = await pool.query(
      'UPDATE users SET name=COALESCE($1,name), email=COALESCE($2,email) WHERE id=$3 RETURNING *',
      [name, email && email.toLowerCase(), req.user.id]);
    res.json(publicUser(rows[0]));
  } catch (e) {
    res.status(e.code === '23505' ? 409 : 500).json({ error: 'Could not update profile' });
  }
});

router.put('/me/password', auth, async (req, res) => {
  const { current_password, new_password } = req.body;
  if (!new_password || new_password.length < 6)
    return res.status(400).json({ error: 'New password must be at least 6 characters' });
  const { rows } = await pool.query('SELECT * FROM users WHERE id=$1', [req.user.id]);
  if (!(await bcrypt.compare(current_password || '', rows[0].password_hash)))
    return res.status(401).json({ error: 'Current password is incorrect' });
  await pool.query('UPDATE users SET password_hash=$1 WHERE id=$2', [await bcrypt.hash(new_password, 10), req.user.id]);
  res.json({ message: 'Password updated' });
});

module.exports = router;
