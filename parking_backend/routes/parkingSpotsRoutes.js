// In your routes file:
const express = require('express');
const router = express.Router();
const parkingController = require('../controllers/parkingSpotsController');
const upload = require('../config/multerConfig');

router.get('/', parkingController.getAllParkingSpots);
router.get('/:id', parkingController.getParkingSpotById);
router.post('/', upload.single('image'), parkingController.addParkingSpot);
router.post('/:id/upload-image', upload.single('image'), parkingController.uploadParkingImage);
router.put('/:id', parkingController.updateParkingSpot);
router.get('/:id/reviews', parkingController.getParkingSpotReviews);

module.exports = router;