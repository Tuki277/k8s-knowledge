require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');
const { createClient } = require('redis');
const { metrics } = require('@opentelemetry/api');
const { logger, httpLogger } = require('./logger');

// Custom business metrics (gửi về SigNoz qua instrumentation.js)
const meter = metrics.getMeter('todo-backend');
const todoOperations = meter.createCounter('todo.operations', {
  description: 'Number of todo operations'
});
const cacheRequests = meter.createCounter('todo.cache.requests', {
  description: 'Number of todo cache lookups'
});

const app = express();
app.use(httpLogger);
app.use(cors());
app.use(express.json());

// Database connection
const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'todo_db',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || 'postgres'
});

// Redis connection
const redisClient = createClient({
  url: process.env.REDIS_URL || 'redis://localhost:6379',
  password: process.env.REDIS_PASSWORD
});

redisClient.on('error', (err) => logger.error({ err }, 'Redis client error'));

// Initialize database table
async function initDB() {
  const client = await pool.connect();
  try {
    await client.query(`
      CREATE TABLE IF NOT EXISTS todos (
        id SERIAL PRIMARY KEY,
        title VARCHAR(255) NOT NULL,
        completed BOOLEAN DEFAULT false,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
  } catch (err) {
    logger.error({ err }, 'Error creating table');
  } finally {
    client.release();
  }
}

// Connect to database and redis
async function connect() {
  try {
    await redisClient.connect();
    logger.info('Connected to Redis');
    await initDB();
    logger.info('Database initialized');
  } catch (err) {
    logger.error({ err }, 'Connection error');
  }
}

// Health check: kiểm tra kết nối Postgres và Redis
app.get('/api/health', async (req, res) => {
  const checks = { database: 'ok', redis: 'ok' };

  try {
    await pool.query('SELECT 1');
  } catch (err) {
    req.log.error({ err }, 'Health check: database down');
    checks.database = 'error';
  }

  try {
    await redisClient.ping();
  } catch (err) {
    req.log.error({ err }, 'Health check: redis down');
    checks.redis = 'error';
  }

  const healthy = Object.values(checks).every((v) => v === 'ok');
  res.status(healthy ? 200 : 503).json({
    status: healthy ? 'ok' : 'error',
    uptime: process.uptime(),
    checks
  });
});

app.get('/api/health-2', async (req, res) => {
  const checks = { database: 'ok', redis: 'ok' };

  try {
    await pool.query('SELECT 1');
  } catch (err) {
    req.log.error({ err }, 'Health check: database down');
    checks.database = 'error';
  }

  try {
    await redisClient.ping();
  } catch (err) {
    req.log.error({ err }, 'Health check: redis down');
    checks.redis = 'error';
  }

  const healthy = Object.values(checks).every((v) => v === 'ok');
  res.status(healthy ? 200 : 503).json({
    status: healthy ? 'ok' : 'error',
    uptime: process.uptime(),
    checks
  });
});

// Get all todos
app.get('/api/todos', async (req, res) => {
  try {
    const cached = await redisClient.get('todos');
    cacheRequests.add(1, { result: cached ? 'hit' : 'miss' });
    req.log.debug({ cache: cached ? 'hit' : 'miss' }, 'Todo cache lookup');
    if (cached) {
      todoOperations.add(1, { operation: 'list', status: 'success' });
      return res.json(JSON.parse(cached));
    }

    const result = await pool.query('SELECT * FROM todos ORDER BY id');
    await redisClient.set('todos', JSON.stringify(result.rows), { EX: 30 });
    todoOperations.add(1, { operation: 'list', status: 'success' });
    res.json(result.rows);
  } catch (err) {
    req.log.error({ err }, 'Error getting todos');
    todoOperations.add(1, { operation: 'list', status: 'error' });
    res.status(500).json({ error: 'Server error' });
  }
});

// Create todo
app.post('/api/todos', async (req, res) => {
  const { title } = req.body;
  if (!title) {
    req.log.warn('Create todo rejected: title is required');
    return res.status(400).json({ error: 'Title is required' });
  }

  try {
    const result = await pool.query(
      'INSERT INTO todos (title) VALUES ($1) RETURNING *',
      [title]
    );
    await redisClient.del('todos');
    todoOperations.add(1, { operation: 'create', status: 'success' });
    req.log.info({ todoId: result.rows[0].id }, 'Todo created');
    res.status(201).json(result.rows[0]);
  } catch (err) {
    req.log.error({ err }, 'Error creating todo');
    todoOperations.add(1, { operation: 'create', status: 'error' });
    res.status(500).json({ error: 'Server error' });
  }
});

// Update todo
app.put('/api/todos/:id', async (req, res) => {
  const { id } = req.params;
  const { title, completed } = req.body;

  try {
    const result = await pool.query(
      'UPDATE todos SET title = COALESCE($1, title), completed = COALESCE($2, completed) WHERE id = $3 RETURNING *',
      [title, completed, id]
    );
    if (result.rowCount === 0) {
      req.log.warn({ todoId: id }, 'Update todo failed: not found');
      return res.status(404).json({ error: 'Todo not found' });
    }
    await redisClient.del('todos');
    todoOperations.add(1, { operation: 'update', status: 'success' });
    req.log.info({ todoId: id, completed: result.rows[0].completed }, 'Todo updated');
    res.json(result.rows[0]);
  } catch (err) {
    req.log.error({ err, todoId: id }, 'Error updating todo');
    todoOperations.add(1, { operation: 'update', status: 'error' });
    res.status(500).json({ error: 'Server error' });
  }
});

// Delete todo
app.delete('/api/todos/:id', async (req, res) => {
  const { id } = req.params;

  try {
    const result = await pool.query('DELETE FROM todos WHERE id = $1 RETURNING *', [id]);
    if (result.rowCount === 0) {
      req.log.warn({ todoId: id }, 'Delete todo failed: not found');
      return res.status(404).json({ error: 'Todo not found' });
    }
    await redisClient.del('todos');
    todoOperations.add(1, { operation: 'delete', status: 'success' });
    req.log.info({ todoId: id }, 'Todo deleted');
    res.json({ message: 'Todo deleted' });
  } catch (err) {
    req.log.error({ err, todoId: id }, 'Error deleting todo');
    todoOperations.add(1, { operation: 'delete', status: 'error' });
    res.status(500).json({ error: 'Server error' });
  }
});

const PORT = process.env.PORT || 3000;
connect().then(() => {
  app.listen(PORT, () => {
    logger.info({ port: PORT }, `Server running on port ${PORT}`);
  });
});
