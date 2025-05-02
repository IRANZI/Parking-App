const { pool } = require("../config/db");
const upload = require("../config/multerConfig"); // Import Multer configuration

// Enhanced controller with image support
exports.getAllParkingSpots = async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT p.*, 
             COALESCE(AVG(r.rating), 0) as avg_rating,
             COUNT(r.id) as review_count
      FROM parking_spots p
      LEFT JOIN reviews r ON p.id = r.parking_spot_id
      GROUP BY p.id
    `);
    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.getParkingSpotById = async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query(`
      SELECT p.*, 
             COALESCE(AVG(r.rating), 0) as avg_rating,
             COUNT(r.id) as review_count
      FROM parking_spots p
      LEFT JOIN reviews r ON p.id = r.parking_spot_id
      WHERE p.id = $1
      GROUP BY p.id
    `, [id]);

    if (result.rows.length === 0) {
      return res.status(404).json({ message: "Parking spot not found" });
    }
    res.json(result.rows[0]);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Updated to handle image upload during creation
exports.addParkingSpot = async (req, res) => {
  try {
    // Validate file was uploaded
    if (!req.file) {
      return res.status(400).json({ error: 'No image uploaded' });
    }

    const { name, latitude, longitude, availableSpots, price, address, description } = req.body;

    // Construct full image URL using req.protocol and req.get('host')
    const imageUrl = `${req.protocol}://${req.get('host')}/uploads/${req.file.filename}`;

    const result = await pool.query(
      `INSERT INTO parking_spots 
       (name, latitude, longitude, available_spots, price, address, description, image_url) 
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8) 
       RETURNING *`,
      [name, latitude, longitude, availableSpots, price, address, description, imageUrl]
    );
    

    res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({ 
      error: 'Failed to create parking spot',
      details: error.message 
    });
  }
};


// New endpoint for image upload to existing spots
exports.uploadParkingImage = [
  upload.single('image'),
  async (req, res) => {
    try {
      if (!req.file) {
        return res.status(400).json({ error: 'No image uploaded' });
      }

      const imageUrl = `/uploads/${req.file.filename}`;
      const { id } = req.params;

      const result = await pool.query(
        'UPDATE parking_spots SET image_url = $1 WHERE id = $2 RETURNING *',
        [imageUrl, id]
      );

      if (result.rows.length === 0) {
        return res.status(404).json({ message: "Parking spot not found" });
      }

      res.json(result.rows[0]);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }
];

// Enhanced update endpoint
exports.updateParkingSpot = async (req, res) => {
  try {
    const { id } = req.params;
const { name, latitude, longitude, availableSpots, price, address, description } = req.body;

const result = await pool.query(
  `UPDATE parking_spots 
   SET name = $1, latitude = $2, longitude = $3, 
       available_spots = $4, price = $5,
       address = $6, description = $7
   WHERE id = $8 
   RETURNING *`,
  [name, latitude, longitude, availableSpots, price, address, description, id]
);


    if (result.rows.length === 0) {
      return res.status(404).json({ message: "Parking spot not found" });
    }
    res.json(result.rows[0]);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Enhanced reviews endpoint
exports.getParkingSpotReviews = async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query(
      `SELECT r.*, u.name as user_name, u.avatar as user_avatar
       FROM reviews r
       JOIN users u ON r.user_id = u.id
       WHERE r.parking_spot_id = $1
       ORDER BY r.created_at DESC`,
      [id]
    );
    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};