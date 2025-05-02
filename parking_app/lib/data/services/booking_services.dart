import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/booking.dart';

class BookingService {
  static const String baseUrl = 'http://localhost:2005/api/reservation';

  // Get auth token - identical to ParkingService
static Future<String?> _getAuthToken() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    
    // Add debug print to verify token retrieval
    debugPrint('Retrieved token: ${token != null ? 'exists' : 'null'}');
    
    return token;
  } catch (e) {
    debugPrint('Error getting token: $e');
    return null;
  }
}

  // Create headers - identical to ParkingService pattern
  static Future<Map<String, String>> _getHeaders() async {
  try {
    final token = await _getAuthToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }
    
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  } catch (e) {
    debugPrint('Error creating headers: $e');
    rethrow;
  }
}

  // Create booking - now uses just the token like ParkingService
  static Future<Booking> createBooking({
    required String spotId,
    required String vehicleBrand,
    required String vehicleType,
    required String plateNumber,
    required DateTime date,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
  }) async {
    try {
      final headers = await _getHeaders();
      
      // The backend will get user ID from the token
      final formattedDate = DateFormat('yyyy-MM-dd').format(date);
      final formattedStartTime = '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
      final formattedEndTime = '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: headers,
        body: json.encode({
          'spot_id': spotId,
          'date': formattedDate,
          'start_time': formattedStartTime,
          'end_time': formattedEndTime,
          'vehicle_brand': vehicleBrand,
          'vehicle_type': vehicleType,
          'plate_number': plateNumber,
        }),
      );

      if (response.statusCode == 201) {
        return Booking.fromJson(json.decode(response.body)['reservation']);
      } else {
        throw _handleError(response);
      }
    } catch (e) {
      debugPrint("Booking creation error: $e");
      rethrow;
    }
  }

  // Get user bookings - uses token-based auth like ParkingService
  static Future<List<Booking>> getUserBookings() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return (json.decode(response.body) as List)
            .map((item) => Booking.fromJson(item))
            .toList();
      } else {
        throw _handleError(response);
      }
    } catch (e) {
      debugPrint("Error fetching bookings: $e");
      rethrow;
    }
  }

  // Cancel booking - token-based auth
  static Future<void> cancelBooking(String bookingId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/$bookingId/cancel'),
        headers: await _getHeaders(),
      );

      if (response.statusCode != 200) {
        throw _handleError(response);
      }
    } catch (e) {
      debugPrint("Cancel booking error: $e");
      rethrow;
    }
  }

  // Confirm payment - token-based auth
  static Future<Map<String, dynamic>> confirmPayment({
    required String reservationId,
    required String paymentMethod,
    required double amountPaid,
    required String phoneNumber,
    String? transactionId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/payment'),
        headers: await _getHeaders(),
        body: json.encode({
          'reservation_id': reservationId,
          'payment_method': paymentMethod,
          'amount_paid': amountPaid,
          'phone_number': phoneNumber,
          if (transactionId != null) 'transaction_id': transactionId,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw _handleError(response);
      }
    } catch (e) {
      debugPrint("Payment error: $e");
      rethrow;
    }
  }

  // Error handler - identical to ParkingService
  static Exception _handleError(http.Response response) {
    try {
      final errorData = json.decode(response.body);
      final errorMsg = errorData['error'] ?? 
                      errorData['message'] ?? 
                      'Unknown error occurred';
      return Exception('${response.statusCode}: $errorMsg');
    } catch (_) {
      return Exception('Request failed with status: ${response.statusCode}');
    }
  }
}