const { pool } = require("../config/db");
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

// Helper to get user from token
const getUserFromToken = (req) => {
  const token = req.header('Authorization')?.split(' ')[1];
  if (!token) return null;
  
  try {
    return jwt.verify(token, process.env.JWT_SECRET);
  } catch (err) {
    return null;
  }
};

// Get user profile
exports.getUserProfile = async (req, res) => {
    try {
      const users = getUserFromToken(req);
      const userId = users?.id;
      
      if (!userId) {
        return res.status(409).json({ message: 'Unauthorized' }); // ✅ return added
      }
  
      const { rows } = await pool.query(
        `SELECT id, name, email, phone, avatar, created_at 
         FROM users 
         WHERE id = $1`,
        [userId]
      );
  
      if (rows.length === 0) {
        return res.status(404).json({ message: 'User not found' }); // ✅ return added
      }
  
      const user = rows[0];
      return res.json({
        ...user,
        avatarUrl: user.avatar_url, // Optional: ensure it's in DB or handle fallback
        createdAt: user.created_at.toISOString()
      });
    } catch (err) {
      console.error(err);
      return res.status(500).json({ message: 'Server Error' }); // ✅ return added
    }
  };
  

// Change password
exports.changePassword = async (req, res) => {
    try {
      const { oldPassword, newPassword } = req.body;
      
      // Validate input
      if (!oldPassword || !newPassword) {
        return res.status(400).json({ message: 'Both old and new passwords are required' });
      }
  
      const userFromToken = getUserFromToken(req);
      if (!userFromToken?.id) {
        return res.status(401).json({ message: 'Unauthorized' });
      }
      const userId = userFromToken.id;
  
      // 1. Get user's current password hash
      const { rows } = await pool.query(
        `SELECT password FROM users WHERE id = $1`,
        [userId]
      );
  
      if (rows.length === 0) {
        return res.status(404).json({ message: 'User not found' });
      }
  
      const storedHash = rows[0].password;
      
      // Validate stored hash exists
      if (!storedHash) {
        return res.status(400).json({ 
          message: 'No password set for this user' 
        });
      }
  
      // 2. Verify old password
      const isMatch = await bcrypt.compare(oldPassword, storedHash);
      if (!isMatch) {
        return res.status(400).json({ message: 'Invalid current password' });
      }
  
      // Validate new password
      if (newPassword.length < 8) {
        return res.status(400).json({ 
          message: 'Password must be at least 8 characters' 
        });
      }
  
      // 3. Hash new password and update
      const salt = await bcrypt.genSalt(10);
      const newHash = await bcrypt.hash(newPassword, salt);
      
      await pool.query(
        `UPDATE users SET password = $1 WHERE id = $2`,
        [newHash, userId]
      );
      
      return res.json({ 
        success: true,
        message: 'Password updated successfully' 
      });
    } catch (err) {
      console.error('Password change error:', err);
      return res.status(500).json({ 
        message: 'Error changing password',
        error: process.env.NODE_ENV === 'development' ? err.message : undefined
      });
    }
  };
// Logout user
exports.logoutUser = async (req, res) => {
  try {
    // For PostgreSQL, you might want to:
    // 1. Add token to blacklist table
    // 2. Or just rely on token expiration
    res.json({ message: 'Logged out successfully' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server Error' });
  }
};