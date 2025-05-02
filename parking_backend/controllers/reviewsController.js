const { pool } = require("../config/db");
const jwt = require("jsonwebtoken");

// Middleware to get user from token
const getUserFromToken = (req) => {
  const token = req.header("Authorization")?.split(" ")[1];
  if (!token) return null;

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    return decoded.id; // Returning the user ID
  } catch (err) {
    return null;
  }
};

// ✅ Get all reviews for a parking spot
exports.getReviewsByParkingSpot = async (req, res) => {
    try {
      const { parking_spot_id } = req.params; // ✅ Get from params
      const result = await pool.query(
        "SELECT r.id, r.user_id, u.name AS user_name, r.rating, r.comment, r.created_at FROM reviews r JOIN users u ON r.user_id = u.id WHERE r.parking_spot_id = $1",
        [parking_spot_id]
      );
      if (result.rows.length >0){
          res.json(result.rows);
      }
      else{
            res.status(404).json({message:"No reviews found"});
      }
    } catch (error) {
      console.error("Error:", error);
      res.status(500).json({ error: "Failed to fetch reviews" });
    }
  };
  

// ✅ Add a new review
exports.addReview = async (req, res) => {
    try {
      const userId = getUserFromToken(req);
      if (!userId) return res.status(401).json({ error: "Unauthorized" });
  
      const { parking_spot_id } = req.params; // ✅ Extract from URL
      const { rating, comment } = req.body;
  
      const result = await pool.query(
        "INSERT INTO reviews (parking_spot_id, user_id, rating, comment) VALUES ($1, $2, $3, $4) RETURNING *",
        [parking_spot_id, userId, rating, comment]
      );
  
      res.status(201).json({message:"Added review successfully" ,review:result.rows[0]});
    } catch (error) {
      console.error("Error:", error);
      res.status(500).json({ error: "Failed to add review" });
    }
  };
  

// ✅ Update a review (only by the owner)
exports.updateReview = async (req, res) => {
  try {
    const userId = getUserFromToken(req);
    if (!userId) return res.status(401).json({ error: "Unauthorized" });

    const { id } = req.params;
    const { rating, comment } = req.body;

    const review = await pool.query("SELECT * FROM reviews WHERE id = $1", [id]);
    if (review.rows.length === 0) return res.status(404).json({ error: "Review not found" });

    if (review.rows[0].user_id !== userId) {
      return res.status(403).json({ error: "Not authorized to edit this review" });
    }

    const result = await pool.query(
      "UPDATE reviews SET rating = $1, comment = $2 WHERE id = $3 RETURNING *",
      [rating, comment, id]
    );

    res.json({message:"updated successfully",review:result.rows[0]});
  } catch (error) {
    res.status(500).json({ error: "Failed to update review" });
  }
};

// ✅ Delete a review (only by the owner)
exports.deleteReview = async (req, res) => {
  try {
    const userId = getUserFromToken(req);
    if (!userId) return res.status(401).json({ error: "Unauthorized" });

    const { id } = req.params;

    const review = await pool.query("SELECT * FROM reviews WHERE id = $1", [id]);
    if (review.rows.length === 0) return res.status(404).json({ error: "Review not found" });

    if (review.rows[0].user_id !== userId) {
      return res.status(403).json({ error: "Not authorized to delete this review" });
    }

    await pool.query("DELETE FROM reviews WHERE id = $1", [id]);

    res.json({ message: "Review deleted successfully" });
  } catch (error) {
    res.status(500).json({ error: "Failed to delete review" });
  }
};
