const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const { pool } = require("../config/db");

// REGISTER FUNCTION
exports.register = async (req, res) => {
  const { name, email, phone, password } = req.body; // 🔧 FIX: Make sure `phone` is extracted
  try {
    const hashedPassword = await bcrypt.hash(password, 10);
    const newUser = await pool.query(
      "INSERT INTO users (name, email, phone, password) VALUES ($1, $2, $3, $4) RETURNING *",
      [name, email, phone, hashedPassword] // 🔧 FIX: Include phone here
    );
    res.status(201).json({ message: "User registered successfully!" });
  } catch (err) {
    console.error("Registration Error:", err);
    res.status(500).json({ error: "Registration failed" });
  }
};

// LOGIN FUNCTION
exports.login = async (req, res) => {
  const { email, password } = req.body;

  try {
    console.log("🔍 Checking user:", email);

    const user = await pool.query(
      "SELECT * FROM users WHERE email = $1 OR phone = $2",
      [email, email] // 🔧 FIX: Provide both $1 and $2 values (email can also be a phone)
    );

    if (user.rows.length === 0) {
      console.log("❌ User not found:", email);
      return res.status(401).json({ error: "Invalid credentials" });
    }

    console.log("✅ User found:", user.rows[0]);

    const isMatch = await bcrypt.compare(password, user.rows[0].password);
    if (!isMatch) {
      console.log("❌ Password mismatch for user:", email);
      return res.status(401).json({ error: "Invalid credentials" });
    }

    if (!process.env.JWT_SECRET) {
      console.error("⚠️ JWT_SECRET is missing in .env file!");
      return res.status(500).json({ error: "Server configuration error" });
    }

    const token = jwt.sign({ id: user.rows[0].id }, process.env.JWT_SECRET, {
      expiresIn: "1h",
    });

    console.log("✅ Token generated successfully");

    res.json({
      token,
      user: {
        id: user.rows[0].id,
        name: user.rows[0].name,
        email: user.rows[0].email,
        phone: user.rows[0].phone,
      },
    });
  } catch (err) {
    console.error("🔥 Login Error:", err);
    res.status(500).json({ error: "Login failed due to server error" });
  }
};
