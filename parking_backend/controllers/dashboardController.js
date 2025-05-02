// controllers/dashboardController.js
const { pool } = require('../config/db');

// Function to get dashboard data
const getDashboardData = async (req, res) => {
  try {
    const totalSpotsResult = await pool.query('SELECT COUNT(*) FROM parking_spots');
    const availableSpotsResult = await pool.query('SELECT COUNT(*) FROM parking_spots WHERE is_available = true');
    const totalStaffResult = await pool.query('SELECT COUNT(*) FROM staff');

    res.json({
      totalSpots: parseInt(totalSpotsResult.rows[0].count),
      availableSpots: parseInt(availableSpotsResult.rows[0].count),
      totalStaff: parseInt(totalStaffResult.rows[0].count),
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Internal server error' });
  }
};

module.exports = { getDashboardData };