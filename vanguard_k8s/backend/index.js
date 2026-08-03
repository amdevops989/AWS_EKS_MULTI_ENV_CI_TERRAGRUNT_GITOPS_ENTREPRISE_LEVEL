const express = require('express');
const { Pool } = require('pg');
const client = require('prom-client');

const app = express();
app.use(express.json());

// 0. Debug Log - Verify Environment Ingestion in k9s logs
console.log('--- Database Config Debug ---');
console.log(`DB_HOST: ${process.env.DB_HOST}`);
console.log(`DB_PORT: ${process.env.DB_PORT || '5432'}`);
console.log(`DB_USER: ${process.env.DB_USER}`);
console.log(`DB_NAME: ${process.env.DB_NAME}`);
console.log('-----------------------------');

// 1. PostgreSQL Connection Pool with SSL & Timeout Config
const pool = new Pool({
  host: process.env.DB_HOST,
  user: process.env.DB_USER || 'dbadmin',
  password: process.env.DB_PASSWORD || 'YourSecretPassword123!',
  database: process.env.DB_NAME || 'ironcore',
  port: parseInt(process.env.DB_PORT || '5432', 10),
  
  // 🌟 FIX: Enable SSL and allow self-signed/RDS certificates
  ssl: {
    rejectUnauthorized: false
  },
  
  // Increase connection timeout to allow RDS TLS negotiation to complete
  connectionTimeoutMillis: 10000, 
  idleTimeoutMillis: 30000,
});

// Prevent unhandled pool crashes
pool.on('error', (err) => {
  console.error('Unexpected error on idle PostgreSQL client:', err);
});

// 2. Prometheus Metrics
client.collectDefaultMetrics({ register: client.register });

const inventoryOperationsCounter = new client.Counter({
  name: 'inventory_operations_total',
  help: 'Total number of items processed by the CRUD engine',
  labelNames: ['action', 'status']
});

// 3. Database Initialization with Retry Loop
const initDb = async (retries = 5, delay = 3000) => {
  while (retries > 0) {
    try {
      const client = await pool.connect();
      try {
        await client.query(`
          CREATE TABLE IF NOT EXISTS inventory (
            id SERIAL PRIMARY KEY,
            name TEXT NOT NULL
          );
        `);
        console.log('✅ Database initialized and schema verified.');
        return; // Success, exit retry loop
      } finally {
        client.release();
      }
    } catch (err) {
      console.error(`❌ DB init failed (${retries} retries left):`, err.message);
      retries -= 1;
      if (retries === 0) {
        console.error('💥 All database connection retries exhausted.');
      } else {
        await new Promise((res) => setTimeout(res, delay));
      }
    }
  }
};

initDb();

// 4. Instrumented JSON Routes
app.get('/items', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM inventory ORDER BY id DESC');
    res.status(200).json(result.rows);
  } catch (error) {
    console.error('GET /items error:', error.message);
    res.status(500).json({ error: error.message });
  }
});

app.post('/items', async (req, res) => {
  const { name } = req.body;
  if (!name) {
    return res.status(400).json({ error: 'Item name is required' });
  }
  try {
    const result = await pool.query('INSERT INTO inventory (name) VALUES ($1) RETURNING *', [name]);
    inventoryOperationsCounter.inc({ action: 'add', status: 'success' });
    res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error('POST /items error:', error.message);
    inventoryOperationsCounter.inc({ action: 'add', status: 'failed' });
    res.status(500).json({ error: error.message });
  }
});

app.delete('/items/:id', async (req, res) => {
  const { id } = req.params;
  try {
    await pool.query('DELETE FROM inventory WHERE id = $1', [id]);
    inventoryOperationsCounter.inc({ action: 'delete', status: 'success' });
    res.status(200).json({ message: 'Item deleted' });
  } catch (error) {
    console.error('DELETE /items/:id error:', error.message);
    inventoryOperationsCounter.inc({ action: 'delete', status: 'failed' });
    res.status(500).json({ error: error.message });
  }
});

app.get('/metrics', async (req, res) => {
  try {
    res.set('Content-Type', client.register.contentType);
    res.end(await client.register.metrics());
  } catch (err) {
    res.status(500).end(err);
  }
});

app.listen(3000, () => {
  console.log('Backend running on port 3000');
});