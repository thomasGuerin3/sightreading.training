const express = require("express");
const pg = require("pg");
const bcrypt = require("bcrypt");
const cors = require("cors");
const helmet = require("helmet");
const rateLimit = require("express-rate-limit");
const path = require("path");

const app = express();
const port = process.env.PORT || 3001;

// Database connection
const pool = new pg.Pool({
  user: "postgres",
  host: "localhost",
  database: "sightreading",
  password: process.env.DB_PASSWORD || "",
  port: 5432,
});

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());

// Serve static files from the static directory
app.use(express.static(path.join(__dirname, "../../static")));

// Also serve files with /static prefix for legacy compatibility
app.use("/static", express.static(path.join(__dirname, "../../static")));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100 // limit each IP to 100 requests per windowMs
});
app.use("/api/", limiter);

// Basic routes
app.get("/api/health", (req, res) => {
  res.json({ status: "ok" });
});

// User routes
app.post("/api/users/register", async (req, res) => {
  try {
    const { username, password, email } = req.body;
    const hashedPassword = await bcrypt.hash(password, 10);

    const result = await pool.query(
      "INSERT INTO users (username, password, email) VALUES ($1, $2, $3) RETURNING id",
      [username, hashedPassword, email]
    );

    res.json({ id: result.rows[0].id });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

app.post("/api/users/login", async (req, res) => {
  try {
    const { username, password } = req.body;

    const result = await pool.query(
      "SELECT id, password FROM users WHERE username = $1",
      [username]
    );

    if (result.rows.length === 0) {
      return res.status(401).json({ error: "Invalid credentials" });
    }

    const user = result.rows[0];
    const validPassword = await bcrypt.compare(password, user.password);

    if (!validPassword) {
      return res.status(401).json({ error: "Invalid credentials" });
    }

    res.json({ id: user.id });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// Songs routes
app.get("/api/songs", async (req, res) => {
  try {
    const result = await pool.query("SELECT * FROM songs ORDER BY id");
    res.json(result.rows);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

app.post("/api/songs/:id/time", async (req, res) => {
  try {
    const { id } = req.params;
    const { user_id, time } = req.body;

    await pool.query(
      "INSERT INTO song_user_time (song_id, user_id, time) VALUES ($1, $2, $3)",
      [id, user_id, time]
    );

    res.json({ success: true });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// Catch-all handler: send back React's index.html file for SPA routing
app.get("*", (req, res) => {
  res.sendFile(path.join(__dirname, "../../static/index.html"));
});

app.listen(port, () => {
  console.log(`Server running on port ${port}`);
});
