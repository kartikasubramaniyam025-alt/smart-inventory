require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const { auth } = require('./middleware/auth');
const crud = require('./routes/crud');

const app = express();
app.use(helmet());
app.use(cors());
app.use(express.json());

app.get('/api/health', (_req, res) => res.json({ status: 'ok' }));
app.use('/api/auth', require('./routes/auth'));
app.use('/api/products', auth, require('./routes/products'));
app.use('/api/categories', auth, crud('categories', ['name', 'description']));
app.use('/api/suppliers', auth, crud('suppliers', ['name', 'email', 'phone', 'address']));
app.use('/api/movements', auth, require('./routes/movements'));
app.use('/api/users', auth, require('./routes/users'));
app.use('/api', auth, require('./routes/dashboard'));

app.use((req, res) => res.status(404).json({ error: 'Route not found' }));
app.use((err, _req, res, _next) => { console.error(err); res.status(500).json({ error: 'Server error' }); });

const port = process.env.PORT || 4000;
app.listen(port, () => console.log(`API running on port ${port}`));
