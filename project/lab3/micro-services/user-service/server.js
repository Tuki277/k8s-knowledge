const express = require('express');
const { Pool } = require('pg');

const pool = new Pool({
  host: process.env.PG_HOST || 'localhost',
  user: process.env.PG_USER || 'postgres',
  password: process.env.PG_PASSWORD || 'postgres',
  database: process.env.PG_DB || 'demo',
});

const app = express();
app.use(express.json());

app.get('/users', async (_req, res) => {
  const { rows } = await pool.query('SELECT id, name FROM users ORDER BY id DESC');
  res.json(rows);
});

app.post('/users', async (req, res) => {
  const { rows } = await pool.query('INSERT INTO users(name) VALUES($1) RETURNING id, name', [req.body.name]);
  res.status(201).json(rows[0]);
});

async function init() {
  // retry until postgres is ready
  for (;;) {
    try {
      await pool.query('CREATE TABLE IF NOT EXISTS users (id SERIAL PRIMARY KEY, name TEXT NOT NULL)');
      break;
    } catch (e) {
      console.log('waiting for postgres...');
      await new Promise((r) => setTimeout(r, 2000));
    }
  }
  app.listen(3001, () => console.log('user-service on 3001'));
}
init();
