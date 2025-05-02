// routes/dashboardRoutes.js
const express = require('express');
const { getDashboardData } = require('../controllers/dashboardController'); // Import the controller

const router = express.Router();

// Endpoint to get dashboard data
router.get('/', getDashboardData); // Use the controller function

module.exports = router;