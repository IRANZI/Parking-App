import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  static const String baseUrl = 'http://localhost:2005/api'; 
  static String? authToken; 

  static Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  static Future<User> getCurrentUser() async {
    final token = await _getAuthToken();
      final url = Uri.parse('$baseUrl/users/me');

      final headers = {
        if (token != null) 'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return User(
        id: data['id'].toString(),
        name: data['name'],
        email: data['email'],
        phone: data['phone'],
        avatarUrl: data['avatarUrl'],
        joinDate: DateTime.parse(data['createdAt']),
      );
    } else {
      throw Exception('Failed to load user');
    }
  }

static Future<void> changePassword({
  required String oldPassword,
  required String newPassword,
}) async {
  try {
    // 1. Validate inputs first
    if (oldPassword.isEmpty || newPassword.isEmpty) {
      throw Exception('Both passwords are required');
    }

    if (newPassword.length < 8) {
      throw Exception('New password must be at least 8 characters');
    }

    // 2. Get auth token
    final token = await _getAuthToken();
    if (token == null) {
      throw Exception('Authentication required - please login again');
    }

    // 3. Prepare request
    final url = Uri.parse('$baseUrl/users/password');
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
    final body = jsonEncode({
      'oldPassword': oldPassword,
      'newPassword': newPassword,
    });

    // 4. Make the request
    final response = await http.put(
      url,
      headers: headers,
      body: body,
    );

    // 5. Handle response
    if (response.statusCode == 200) {
      return; // Success
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Password change failed');
    }
  } on http.ClientException catch (e) {
    throw Exception('Network error: ${e.message}');
  } on FormatException {
    throw Exception('Invalid server response');
  } catch (e) {
    throw Exception('Password change failed: ${e.toString()}');
  }
}

  static Future<void> logout() async {
   final token = await _getAuthToken();
      final url = Uri.parse('$baseUrl/users/logout');

      final headers = {
        if (token != null) 'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      final response = await http.post(url, headers: headers);
    if (response.statusCode != 200) {
      throw Exception('Failed to logout');
    }

    authToken = null; // Clear token
  }
}
