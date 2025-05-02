const { pool } = require("../config/db");
const jwt = require("jsonwebtoken");
const { processMTNPayment, processAirtelPayment } = require("../services/paymentServices");

const generateBookingCode = require('../utils/codeGenerator');

const getUserFromToken = (req) => {
  try {
    // Get the token from headers (case insensitive)
    const authHeader = req.headers['authorization'] || req.headers['Authorization'];
    
    if (!authHeader) {
      console.log('Authorization header missing');
      return null;
    }

    // Check if it's a Bearer token
    if (!authHeader.startsWith('Bearer ')) {
      console.log('Invalid token format - missing Bearer prefix');
      return null;
    }

    const token = authHeader.split(' ')[1];
    if (!token) {
      console.log('Token not found after Bearer');
      return null;
    }

    // Verify the token
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    console.log('Successfully decoded token for user:', decoded.id);
    return decoded.id;
  } catch (err) {
    console.error('Token verification failed:', err.message);
    return null;
  }
};

  function calculatePrice(startTime, endTime, hourlyRate) {
    const timeRegex = /^([01]?[0-9]|2[0-3]):[0-5][0-9]$/;
    if (!timeRegex.test(startTime)) throw new Error('Invalid start time format');
    if (!timeRegex.test(endTime)) throw new Error('Invalid end time format');
    const [startHour, startMin] = startTime.split(":").map(Number);
    const [endHour, endMin] = endTime.split(":").map(Number);
  
    const start = new Date();
    start.setHours(startHour, startMin);
  
    const end = new Date();
    end.setHours(endHour, endMin);
    if (end <= start) throw new Error('End time must be after start time');

    const durationInHours = (end - start) / (1000 * 60 * 60);
    const roundedHours = Math.ceil(durationInHours); // Optional: round up to nearest hour
  
    return roundedHours * hourlyRate;
  }
  function validateReservationData(data) {  
    const requiredFields = [
      'spot_id', 'date', 
      'start_time', 'end_time',
      'vehicle_brand', 'vehicle_type', 'plate_number'
    ];
    
    const missingFields = requiredFields.filter(field => !data[field]);
    if (missingFields.length > 0) {
      throw  new Error(`Missing required fields: ${missingFields.join(', ')}`);
    }
  
    // Validate date format (YYYY-MM-DD)
    if (!/^\d{4}-\d{2}-\d{2}$/.test(data.date)) {
      throw new Error('Invalid date format. Use YYYY-MM-DD');
    }
   
  }
  exports.createReservation = async (req, res) => {
    //validate input data
    const user_id = getUserFromToken(req);
    if (!user_id) {
      console.log('Failed to authenticate - invalid or missing token');
      return res.status(401).json({ 
        error: "Unauthorized",
        message: "Invalid or expired authentication token"
      });
    }
    
    const { spot_id, date, start_time, end_time, vehicle_brand, vehicle_type, plate_number } = req.body;
    
    try {
      // Validate required fields
      validateReservationData(req.body);
      if (!spot_id || !date || !start_time || !end_time) {
        return res.status(400).json({ message: "Missing required fields" });
      }
  
      // Get spot information and count overlapping reservations
      const availabilityQuery = `
        SELECT 
          ps.id,
          ps.price,
          ps.available_spots,
          (
            SELECT COUNT(*) 
            FROM reservations r 
            WHERE r.spot_id = ps.id
            AND r.date = $2
            AND (r.start_time < $4 AND r.end_time > $3)
          ) AS overlapping_reservations
        FROM parking_spots ps
        WHERE ps.id = $1
      `;
  
      const availabilityResult = await pool.query(availabilityQuery, 
        [spot_id, date, start_time, end_time]);
  
      if (availabilityResult.rows.length === 0) {
        return res.status(404).json({ message: 'Parking spot not found' });
      }
  
      const spot = availabilityResult.rows[0];
      
      if (spot.overlapping_reservations >= spot.available_spots) {
        return res.status(400).json({ 
          message: 'No available spots for the selected time period' 
        });
      }
  
      // Calculate price (booking_code will be added during payment)
      const totalPrice = calculatePrice(start_time, end_time, spot.price);
  
      // Use transaction for data consistency
      const client = await pool.connect();
      try {
        await client.query('BEGIN');
  
        // Create reservation without booking_code
        const insertResult = await client.query(
          `INSERT INTO reservations 
          (user_id, spot_id, date, start_time, end_time, vehicle_brand, 
           vehicle_type, plate_number, total_price, status)
          VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, 'pending')
          RETURNING id`,
          [user_id, spot_id, date, start_time, end_time, 
           vehicle_brand, vehicle_type, plate_number, totalPrice]
        );
  
        // Update available spots if first reservation for this time period
        if (spot.overlapping_reservations === 0) {
          await client.query(
            `UPDATE parking_spots 
             SET available_spots = available_spots - 1 
             WHERE id = $1`,
            [spot_id]
          );
        }
  
        await client.query('COMMIT');
  
        return res.status(201).json({
          message: 'Reservation created successfully',
          reservation: {
            id: insertResult.rows[0].id,
            spot_id,
            date,
            start_time,
            end_time,
            vehicle_brand,
            vehicle_type,
            plate_number,
            total_price: totalPrice,
            status: 'pending'
          }
        });
      } catch (err) {
        await client.query('ROLLBACK');
        throw err;
      } finally {
        client.release();
      }
    } catch (err) {
      console.error('Reservation Error:', err);
      res.status(500).json({ message: 'Internal server error' });
    }
  };
  
// Get all reservations
exports.getReservations = async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM reservations ORDER BY id DESC');
    res.json(result.rows);
  } catch (err) {
    console.error('Error fetching reservations:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
};
  // Create reservation (book spot)

// Get single reservation
exports.getReservationById = async (req, res) => {
  const { id } = req.params;
  try {
    const result = await pool.query('SELECT * FROM reservations WHERE id = $1', [id]);
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Reservation not found' });
    }
    res.json(result.rows[0]);
  } catch (err) {
    console.error('Error fetching reservation:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
};
//using user id to get reservation
exports.getReservationsByUser = async (req, res) => {
  const user_id = getUserFromToken(req);
  
  if (!user_id) {
    return res.status(401).json({ 
      error: "Unauthorized",
      message: "Invalid or expired authentication token"
    });
  }

  try {
    const result = await pool.query(
      `
      SELECT 
        reservations.*, 
        parking_spots.name AS spot_name,
        parking_spots.price,
        parking_spots.address
      FROM reservations
      JOIN parking_spots ON reservations.spot_id = parking_spots.id
      WHERE reservations.user_id = $1
      ORDER BY reservations.date DESC, reservations.start_time DESC
      `,
      [user_id]
    );

    res.json(result.rows);
  } catch (err) {
    console.error('Error fetching user reservations:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
};


// Update reservation
exports.updateReservation = async (req, res) => {
  const { id } = req.params;
  const {
    user_id,
    spot_id,
    date,
    start_time,
    end_time,
    vehicle_brand,
    vehicle_type,
    plate_number,
    total_price,
    status,
    check_in_time,
    check_out_time
  } = req.body;

  try {
    const result = await pool.query(
      `UPDATE reservations SET
        user_id = $1, spot_id = $2, date = $3, start_time = $4, end_time = $5,
        vehicle_brand = $6, vehicle_type = $7, plate_number = $8,
        total_price = $9, status = $10, check_in_time = $11, check_out_time = $12
       WHERE id = $13 RETURNING *`,
      [
        user_id, spot_id, date, start_time, end_time,
        vehicle_brand, vehicle_type, plate_number,
        total_price, status, check_in_time, check_out_time,
        id
      ]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Reservation not found' });
    }

    res.json(result.rows[0]);
  } catch (err) {
    console.error('Error updating reservation:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Delete reservation
exports.deleteReservation = async (req, res) => {
  const { id } = req.params;
  const client = await pool.connect();
  
  try {
    await client.query('BEGIN');
    
    // Get the reservation
    const reservationResult = await client.query(
      'SELECT * FROM reservations WHERE id = $1', 
      [id]
    );
    
    if (reservationResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Reservation not found' });
    }

    // Delete the reservation
    await client.query('DELETE FROM reservations WHERE id = $1', [id]);
    
    await client.query('COMMIT');
    
    res.json({ message: 'Reservation deleted successfully' });
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Error deleting reservation:', err);
    res.status(500).json({ error: 'Internal server error' });
  } finally {
    client.release();
  }
};

exports.confirmPayment = async (req, res) => {
  const client = await pool.connect();

  try {
    const { reservation_id, payment_method, phone_number, amount_paid } = req.body;
    
    // Validate required fields
    if (!reservation_id || !payment_method || !phone_number || !amount_paid) {
      throw new Error('Missing required payment details');
    }

    // Validate phone number format (Rwandan)
    if (!/^07[2389]\d{7}$/.test(phone_number)) {
      throw new Error('Invalid Rwandan phone number format');
    }

    await client.query('BEGIN');

    // Get and lock reservation
    const reservationResult = await client.query(
      `SELECT * FROM reservations 
       WHERE id = $1 AND status = 'pending'
       FOR UPDATE`,
      [reservation_id]
    );

    if (reservationResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ 
        success: false,
        message: 'Reservation not found or already paid' 
      });
    }

    const reservation = reservationResult.rows[0];
    
    // Validate payment amount (allow small floating point differences)
    if (Math.abs(parseFloat(amount_paid) - parseFloat(reservation.total_price) < -0.01)) {
      await client.query('ROLLBACK');
      return res.status(400).json({ 
        success: false,
        message: `Insufficient payment amount. Required: ${reservation.total_price}` 
      });
    }

    // Process payment with selected provider
    let paymentResult;
    const paymentReference = `PAY-${reservation_id}-${Date.now()}`;

    switch (payment_method.toUpperCase()) {
      case 'MTN':
        paymentResult = await processMTNPayment(phone_number, amount_paid, paymentReference);
        break;
      case 'AIRTEL':
        paymentResult = await processAirtelPayment(phone_number, amount_paid, paymentReference);
        break;
      default:
        throw new Error('Unsupported payment method');
    }

    if (!paymentResult.success) {
      await client.query('ROLLBACK');
      return res.status(400).json({ 
        success: false,
        message: paymentResult.error || 'Payment processing failed'
      });
    }

    // Update reservation status
    const ticketCode = generateBookingCode(5);
    const updateResult = await client.query(
      `UPDATE reservations
       SET status = 'paid', booking_code = $1
       WHERE id = $2
       RETURNING *`,
      [ticketCode, reservation_id]
    );

    // Record payment transaction
    await client.query(
      `INSERT INTO payments 
       (reservation_id, amount, method, status, transaction_id, phone_number, paid_at)
       VALUES ($1, $2, $3, 'success', $4, $5, NOW())`,
      [
        reservation_id, 
        amount_paid,
        payment_method,
        paymentResult.transactionId,
        phone_number
      ]
    );

    await client.query('COMMIT');

    const updatedReservation = updateResult.rows[0];
    return res.status(200).json({
      success: true,
      message: 'Payment successful',
      data: {
        booking_code: updatedReservation.booking_code,
        transaction_id: paymentResult.transactionId,
        amount_paid: amount_paid,
        payment_method: payment_method,
        valid_until: `${updatedReservation.date} ${updatedReservation.end_time}`
      }
    });

  } catch (error) {
    await client.query('ROLLBACK').catch(() => {});
    console.error('Payment Error:', error);
    return res.status(500).json({ 
      success: false,
      message: error.message || 'Payment processing failed' 
    });
  } finally {
    client.release();
  }
};


    
exports.checkInByCode = async (req, res) => {
  const client = await pool.connect();

  try {
    let { booking_code, plate_number } = req.body;
    
    if (!booking_code || !plate_number) {
      return res.status(400).json({ error: 'Booking code and plate number are required' });
    }

    booking_code = booking_code.trim();
    plate_number = plate_number.trim().toUpperCase(); // Normalize plate number

    await client.query('BEGIN');

    // Check reservation validity
    const result = await client.query(
      `UPDATE reservations 
       SET check_in_time = NOW(), status = 'active'
       WHERE booking_code = $1 
         AND plate_number = $2
         AND check_in_time IS NULL
         AND status = 'paid'
         AND CURRENT_DATE BETWEEN (date - INTERVAL '1 day') AND date
       RETURNING *`,
      [booking_code, plate_number]
    );

    if (result.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(400).json({ 
        error: 'Invalid code, already checked in, or reservation expired' 
      });
    }

    await client.query('COMMIT');
    
    return res.json({ 
      message: 'Check-in successful',
      reservation: result.rows[0] 
    });

  } catch (err) {
    await client.query('ROLLBACK').catch(() => {});
    console.error('Check-in error:', err);
    return res.status(500).json({ error: 'Check-in processing failed' });
  } finally {
    client.release();
  }
};


  exports.checkOutByCode = async (req, res) => {
    const { booking_code, plate_number } = req.body;
    const client = await pool.connect();
  
    try {
      await client.query('BEGIN');
  
      // Get the reservation
      const reservationResult = await client.query(
        `SELECT * FROM reservations 
         WHERE booking_code = $1 AND plate_number = $2 
         AND check_out_time IS NULL AND check_in_time IS NOT NULL`,
        [booking_code, plate_number]
      );
  
      if (reservationResult.rows.length === 0) {
        await client.query('ROLLBACK');
        return res.status(400).json({ error: 'Invalid or already checked out' });
      }
  
      // Mark as completed
      const result = await client.query(
        `UPDATE reservations 
         SET check_out_time = NOW(), status = 'completed'
         WHERE booking_code = $1 AND plate_number = $2
         RETURNING *`,
        [booking_code, plate_number]
      );
  
      await client.query('COMMIT');
  
      res.json({ 
        message: 'Check-out successful', 
        reservation: result.rows[0] 
      });
    } catch (err) {
      await client.query('ROLLBACK');
      console.error('Check-out error:', err);
      res.status(500).json({ error: 'Internal server error' });
    } finally {
      client.release();
    }
  };
  