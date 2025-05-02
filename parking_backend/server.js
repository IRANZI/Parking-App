require("dotenv").config();
const express = require("express");
const cors = require("cors");
const { pool, testConnection } = require("./config/db");
const authRoutes = require("./routes/authRoutes");
const parkingSpotsRoutes = require("./routes/parkingSpotsRoutes");
const reviewsRoutes = require("./routes/reviewsRoutes");
const dashboardRoutes = require("./routes/dashboardRoutes");
const path = require('path');

const app = express();
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(cors());
app.use((req, res, next) => {
  res.header("Access-Control-Allow-Origin", "*");
  res.header("Access-Control-Allow-Headers", "Content-Type, Accept");
  next();
});
app.use(express.static(path.join(__dirname, 'public')));

app.use("/api/auth", authRoutes);
app.use("/api/parkingSpots", parkingSpotsRoutes);
app.use("/api/reviews", reviewsRoutes);
app.use("/api/dashboard", dashboardRoutes);
app.use("/api/reservation", require("./routes/reservationRoutes"))
app.use("/api", require('./routes/userRoutes'))
const PORT = process.env.PORT || 5000;

const startServer = async () => {
  try {
    // Test database connection before starting server
    const isConnected = await testConnection();
    if (!isConnected) {
      console.error("Failed to connect to database. Server will not start.");
      process.exit(1);
    }

    app.listen(PORT, () => {
      console.log(`🚀 Server running on port ${PORT}`);
      console.log("📦 Database connection established successfully");
    });
  } catch (error) {
    console.error("Error starting server:", error);
    process.exit(1);
  }
};

startServer();

