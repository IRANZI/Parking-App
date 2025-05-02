const express = require("express");
const {
  getReviewsByParkingSpot,
  addReview,
  updateReview,
  deleteReview,
} = require("../controllers/reviewsController");

const router = express.Router();

// Get all reviews for a parking spot
router.get("/:parking_spot_id", getReviewsByParkingSpot);

// Add a new review (auth required)
router.post("/:parking_spot_id", addReview);

// Update a review (auth required)
router.put("/:id", updateReview);

// Delete a review (auth required)
router.delete("/:id", deleteReview);

module.exports = router;
