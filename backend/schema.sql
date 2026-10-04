CREATE TABLE IF NOT EXISTS users (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  email VARCHAR(150) UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  role VARCHAR(20) NOT NULL DEFAULT 'staff',
  created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS categories (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) UNIQUE NOT NULL,
  description TEXT DEFAULT ''
);
CREATE TABLE IF NOT EXISTS suppliers (
  id SERIAL PRIMARY KEY,
  name VARCHAR(150) NOT NULL,
  email VARCHAR(150) DEFAULT '',
  phone VARCHAR(40) DEFAULT '',
  address TEXT DEFAULT ''
);
CREATE TABLE IF NOT EXISTS products (
  id SERIAL PRIMARY KEY,
  sku VARCHAR(60) UNIQUE NOT NULL,
  name VARCHAR(150) NOT NULL,
  description TEXT DEFAULT '',
  category_id INT REFERENCES categories(id) ON DELETE SET NULL,
  supplier_id INT REFERENCES suppliers(id) ON DELETE SET NULL,
  price NUMERIC(12,2) NOT NULL DEFAULT 0,
  cost NUMERIC(12,2) NOT NULL DEFAULT 0,
  quantity INT NOT NULL DEFAULT 0,
  min_stock INT NOT NULL DEFAULT 10,
  unit VARCHAR(20) DEFAULT 'pcs',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS stock_movements (
  id SERIAL PRIMARY KEY,
  product_id INT NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  user_id INT REFERENCES users(id) ON DELETE SET NULL,
  type VARCHAR(10) NOT NULL CHECK (type IN ('IN','OUT','ADJUST')),
  quantity INT NOT NULL,
  note TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_products_name ON products(name);
CREATE INDEX IF NOT EXISTS idx_movements_product ON stock_movements(product_id);

INSERT INTO categories (name, description) VALUES
 ('Electronics','Devices and accessories'),
 ('Groceries','Food and daily items'),
 ('Stationery','Office and school supplies'),
 ('Hardware','Tools and fittings')
ON CONFLICT DO NOTHING;

INSERT INTO suppliers (name, email, phone, address)
SELECT 'Alpha Traders','sales@alpha.com','+91 90000 11111','Ahmedabad'
WHERE NOT EXISTS (SELECT 1 FROM suppliers);

INSERT INTO products (sku,name,description,category_id,supplier_id,price,cost,quantity,min_stock,unit)
SELECT * FROM (VALUES
 ('ELE-001','Wireless Mouse','2.4GHz optical mouse',1,1,599,350,45,10,'pcs'),
 ('ELE-002','USB-C Cable','1m fast charging cable',1,1,299,120,8,15,'pcs'),
 ('GRO-001','Basmati Rice 5kg','Premium long grain',2,1,540,430,30,12,'bag'),
 ('STA-001','A4 Paper Ream','500 sheets',3,1,320,250,5,10,'ream'),
 ('HAR-001','Hammer','Steel claw hammer',4,1,450,280,22,5,'pcs')
) AS v(sku,name,description,category_id,supplier_id,price,cost,quantity,min_stock,unit)
WHERE NOT EXISTS (SELECT 1 FROM products);
