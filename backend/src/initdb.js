// Creates tables, sample data and a default admin user.
const fs = require('fs');
const path = require('path');
const bcrypt = require('bcryptjs');
const pool = require('./db');

(async () => {
  try {
    await pool.query(fs.readFileSync(path.join(__dirname, '..', 'schema.sql'), 'utf8'));
    const hash = await bcrypt.hash('Admin@123', 10);
    await pool.query(
      `INSERT INTO users (name,email,password_hash,role) VALUES ('Admin','admin@inventory.com',$1,'admin')
       ON CONFLICT (email) DO NOTHING`, [hash]);
    console.log('Database ready. Login: admin@inventory.com / Admin@123');
  } catch (e) { console.error(e); } finally { await pool.end(); }
})();
