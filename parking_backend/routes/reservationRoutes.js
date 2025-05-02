const express = require('express');
const router = express.Router();
const reservationsController = require('../controllers/reservation_controller');

router.post('/', reservationsController.createReservation);
router.get('/', reservationsController.getReservations);
router.get('/user', reservationsController.getReservationsByUser);
router.get('/:id', reservationsController.getReservationById);
router.put('/:id', reservationsController.updateReservation);
router.delete('/:id', reservationsController.deleteReservation);
router.post('/payment', reservationsController.confirmPayment);
router.post('/admin/check-in', reservationsController.checkInByCode);
router.post('/admin/check-out', reservationsController.checkOutByCode);

module.exports = router;
