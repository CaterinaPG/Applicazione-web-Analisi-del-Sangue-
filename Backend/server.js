const express = require('express');
const mysql = require('mysql2/promise');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const cors = require('cors');
const fs = require('fs');
const path = require('path');
require('dotenv').config();
 
const app = express();
const PORT = process.env.PORT || 3000;
 
// Middleware
app.use(cors());
app.use(express.json());
 
// Database connection
const dbConfig = {
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'analisi_sanguigne'
};
 
const adminDbConfig = {
  host: dbConfig.host,
  user: dbConfig.user,
  password: dbConfig.password,
  multipleStatements: true,
};
 
let db;
 
async function importDatabaseSchema() {
  const sqlFilePath = path.resolve(__dirname, '..', 'database_completo.sql');
  if (!fs.existsSync(sqlFilePath)) {
    throw new Error(`Schema file not found: ${sqlFilePath}`);
  }
 
  const sqlScript = await fs.promises.readFile(sqlFilePath, 'utf8');
  const adminConnection = await mysql.createConnection(adminDbConfig);
  try {
    await adminConnection.query(`CREATE DATABASE IF NOT EXISTS \`${dbConfig.database}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci`);
    await adminConnection.changeUser({ database: dbConfig.database });
    await adminConnection.query(sqlScript);
  } finally {
    await adminConnection.end();
  }
}
 
// Initialize database connection
async function initDB() {
  try {
    db = await mysql.createConnection(dbConfig);
    console.log('Connected to MySQL database');
  } catch (error) {
    if (error.code === 'ER_BAD_DB_ERROR') {
      console.log(`Database ${dbConfig.database} not found. Creating it from schema...`);
      try {
        await importDatabaseSchema();
        db = await mysql.createConnection(dbConfig);
        console.log('Connected to MySQL database after creating schema');
      } catch (schemaError) {
        console.error('Failed to create database schema:', schemaError);
        process.exit(1);
      }
    } else if (error.code === 'ER_ACCESS_DENIED_ERROR') {
      console.error('Database connection failed: access denied. Check DB_USER and DB_PASSWORD in .env');
      process.exit(1);
    } else {
      console.error('Database connection failed:', error);
      process.exit(1);
    }
  }
}
 
// JWT secret
const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key';
 
const isBcryptHash = (value) => typeof value === 'string' && /^\$2[aby]\$\d{2}\$/.test(value);
 
// Middleware to verify JWT
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];
 
  if (!token) {
    return res.status(401).json({ error: 'Access token required' });
  }
 
  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) {
      return res.status(403).json({ error: 'Invalid token' });
    }
    req.user = user;
    next();
  });
};
 
// Routes
 
function computeEsito(result) {
  const valoreMisurato = Number(result.valore_misurato)
  const valoreMin = result.valore_min === null ? null : Number(result.valore_min)
  const valoreMax = result.valore_max === null ? null : Number(result.valore_max)
 
  let esito = 'NORMALE'
  if (valoreMin !== null && valoreMax !== null) {
    if (valoreMisurato < valoreMin) {
      esito = 'BASSO'
    } else if (valoreMisurato > valoreMax) {
      esito = 'ALTO'
    }
  }
 
  return {
    ...result,
    valore_misurato: valoreMisurato,
    valore_min: valoreMin,
    valore_max: valoreMax,
    esito,
  }
}
 
// User registration
app.post('/api/register', async (req, res) => {
  try {
    const { email, password, nome, cognome, data_nascita, sesso } = req.body;
 
    // Validate input
    if (!email || !password || !nome || !cognome || !data_nascita || !sesso) {
      return res.status(400).json({ error: 'All fields are required' });
    }
 
    // Check if user already exists
    const [existing] = await db.execute('SELECT user_id FROM users WHERE email = ?', [email]);
    if (existing.length > 0) {
      return res.status(400).json({ error: 'Email already registered' });
    }
 
    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);
 
    // Insert user
    const [result] = await db.execute(
      'INSERT INTO users (email, password_hash, nome, cognome, data_nascita, sesso) VALUES (?, ?, ?, ?, ?, ?)',
      [email, hashedPassword, nome, cognome, data_nascita, sesso]
    );
 
    res.status(201).json({ message: 'User registered successfully', user_id: result.insertId });
  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});
 
// User login
app.post('/api/login', async (req, res) => {
  try {
    const { email, password } = req.body;
 
    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password are required' });
    }
 
    // Find user
    const [users] = await db.execute('SELECT * FROM users WHERE email = ?', [email]);
    if (users.length === 0) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }
 
    const user = users[0];
 
    // Check password
    let validPassword = false;
 
    if (isBcryptHash(user.password_hash)) {
      validPassword = await bcrypt.compare(password, user.password_hash);
    } else if (password === user.password_hash) {
      validPassword = true;
 
      const upgradedHash = await bcrypt.hash(password, 10);
      await db.execute('UPDATE users SET password_hash = ? WHERE user_id = ?', [upgradedHash, user.user_id]);
    }
 
    if (!validPassword) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }
 
    // Generate JWT
    const token = jwt.sign(
      { user_id: user.user_id, email: user.email },
      JWT_SECRET,
      { expiresIn: '24h' }
    );
 
    res.json({
      token,
      user: {
        user_id: user.user_id,
        email: user.email,
        nome: user.nome,
        cognome: user.cognome,
        data_nascita: user.data_nascita,
        sesso: user.sesso
      }
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});
 
// Get user profile
app.get('/api/profile', authenticateToken, async (req, res) => {
  try {
    const [users] = await db.execute('SELECT user_id, email, nome, cognome, data_nascita, sesso FROM users WHERE user_id = ?', [req.user.user_id]);
    if (users.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }
    res.json(users[0]);
  } catch (error) {
    console.error('Profile error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});
 
// Get biomarkers
app.get('/api/biomarkers', async (req, res) => {
  try {
    const [biomarkers] = await db.execute('SELECT * FROM biomarkers ORDER BY biomarker_id');
    res.json(biomarkers);
  } catch (error) {
    console.error('Biomarkers error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});
 
// Submit test results
app.post('/api/test-results', authenticateToken, async (req, res) => {
  try {
    const { results, testDate } = req.body;
    const userId = req.user.user_id;
 
    if (!results || !Array.isArray(results) || results.length === 0) {
      return res.status(400).json({ error: 'Results array is required' });
    }
 
    const date = testDate || new Date().toISOString().split('T')[0];
 
    // Insert results
    const values = results.map(result => [userId, result.biomarker_id, result.valore_misurato, date]);
    const placeholders = values.map(() => '(?, ?, ?, ?)').join(', ');
 
    const [result] = await db.execute(
      `INSERT INTO test_results (user_id, biomarker_id, valore_misurato, data_test) VALUES ${placeholders}`,
      values.flat()
    );
 
    res.status(201).json({ message: 'Test results submitted successfully', insertedCount: result.affectedRows });
  } catch (error) {
    console.error('Submit results error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});
 
// Get test results for user
app.get('/api/test-results', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.user_id;
    const { date } = req.query;
 
    let query = `
      SELECT tr.result_id, tr.valore_misurato, tr.data_test,
             b.biomarker_id, b.nome as esame, b.unita_misura,
             rr.valore_min, rr.valore_max
      FROM test_results tr
      JOIN biomarkers b ON tr.biomarker_id = b.biomarker_id
      JOIN users u ON tr.user_id = u.user_id
      LEFT JOIN references_ranges rr ON b.biomarker_id = rr.biomarker_id
        AND rr.sesso = u.sesso
        AND TIMESTAMPDIFF(YEAR, u.data_nascita, tr.data_test) BETWEEN rr.eta_min AND rr.eta_max
      WHERE tr.user_id = ?
    `;
 
    const params = [userId];
 
    if (date) {
      query += ' AND tr.data_test = ?';
      params.push(date);
    }
 
    query += ' ORDER BY tr.data_test DESC, b.nome';
 
    const [results] = await db.execute(query, params);
 
    const processedResults = results.map(computeEsito);
 
    res.json(processedResults);
  } catch (error) {
    console.error('Get results error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});
 
// Get test history
app.get('/api/test-history', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.user_id;
    const { biomarker_id, from_date, to_date } = req.query;
 
    let query = `
      SELECT tr.result_id, tr.valore_misurato, tr.data_test,
             b.biomarker_id, b.nome as biomarker_nome, b.nome as esame, b.unita_misura,
             rr.valore_min, rr.valore_max
      FROM test_results tr
      JOIN biomarkers b ON tr.biomarker_id = b.biomarker_id
      JOIN users u ON tr.user_id = u.user_id
      LEFT JOIN references_ranges rr ON b.biomarker_id = rr.biomarker_id
        AND rr.sesso = u.sesso
        AND TIMESTAMPDIFF(YEAR, u.data_nascita, tr.data_test) BETWEEN rr.eta_min AND rr.eta_max
      WHERE tr.user_id = ?
    `;
 
    const params = [userId];
 
    if (biomarker_id) {
      query += ' AND tr.biomarker_id = ?';
      params.push(biomarker_id);
    }
 
    if (from_date) {
      query += ' AND tr.data_test >= ?';
      params.push(from_date);
    }
 
    if (to_date) {
      query += ' AND tr.data_test <= ?';
      params.push(to_date);
    }
 
    query += ' ORDER BY tr.data_test DESC, b.nome';
 
    const [results] = await db.execute(query, params);
 
    const processedResults = results.map(computeEsito);
 
    res.json(processedResults);
  } catch (error) {
    console.error('Get history error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});
 
// Start server
async function startServer() {
  await initDB();
  app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
  });
}
 
startServer();