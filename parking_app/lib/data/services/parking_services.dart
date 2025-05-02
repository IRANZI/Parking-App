import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:parking/data/models/parking_spot.dart';
import 'package:parking/data/models/review.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ParkingService {
  static const String baseUrl = 'http://localhost:2005/api';

  // Get auth token
  static Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  // Fetch all parking spots
  static Future<List<ParkingSpot>> getParkingSpots() async {
    try {
      final url = Uri.parse('$baseUrl/parkingSpots/');
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as List;
        return jsonData.map((item) => ParkingSpot.fromJson(item)).toList();
      } else {
        throw _handleError(response);
      }
    } catch (e) {
      print("Error fetching parking spots: $e");
      rethrow;
    }
  }

  // Upload parking spot image (uses internal token fetch)
  static Future<String> uploadImage({
    required String parkingSpotId,
    required File imageFile,
  }) async {
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('Unauthorized. Please log in.');

      final url = Uri.parse('$baseUrl/parkingSpots/$parkingSpotId/upload-image');
      var request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $token';

      request.files.add(await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
      ));

      final response = await request.send();
      final responseData = await http.Response.fromStream(response);

      if (response.statusCode == 200) {
        final jsonData = json.decode(responseData.body);
        return jsonData['imageUrl'] as String;
      } else {
        throw _handleError(responseData);
      }
    } catch (e) {
      print("Error uploading image: $e");
      rethrow;
    }
  }

  // Get reviews for a parking spot
  static Future<List<Review>> getReviews(String parkingSpotId) async {
    try {
      final token = await _getAuthToken();
      final url = Uri.parse('$baseUrl/reviews/$parkingSpotId');

      final headers = {
        if (token != null) 'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as List;
        return jsonData.map((item) => Review.fromJson(item)).toList();
      } else {
        throw _handleError(response);
      }
    } catch (e) {
      print("Error fetching reviews: $e");
      rethrow;
    }
  }

  // Add a review (internally handles token)
  static Future<void> addReview({
    required String parkingSpotId,
    required int rating,
    required String comment,
  }) async {
    try {
      final token = await _getAuthToken();
      if (token == null || token.isEmpty) {
        throw Exception('User not authenticated');
      }

      final url = Uri.parse('$baseUrl/reviews/$parkingSpotId');
      final body = json.encode({'rating': rating, 'comment': comment});

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      if (response.statusCode != 201) {
        throw Exception('Failed to add review: ${response.statusCode}');
      }
    } catch (e) {
      print('Error adding review: $e');
      rethrow;
    }
  }

  // Generic error handler
  static Exception _handleError(http.Response response) {
    try {
      final errorData = json.decode(response.body);
      final errorMsg = errorData['error'] ?? 'Unknown error occurred';
      return Exception('${response.statusCode}: $errorMsg');
    } catch (_) {
      return Exception('Request failed with status: ${response.statusCode}');
    }
  }
}
