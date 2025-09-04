import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Replace with your ngrok/laptop URL
  static const String baseUrl = "https://cc92c58583c8.ngrok-free.app";

  // ---------------- Registration ----------------
  static Future<Map<String, dynamic>> register(
      String fullName,
      String email,
      String password,
      String confirmPassword) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'full_name': fullName,
          'email': email,
          'password': password,
          'confirm_password': confirmPassword,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'user_id': data['user_id'],
          'message': data['message'] ?? 'Registration successful',
        };
      } else {
        // Handle both dict {"detail": "..."} and list [{"msg": "..."}]
        if (data['detail'] is List && data['detail'].isNotEmpty) {
          return {
            'success': false,
            'message': data['detail'][0]['msg'] ?? 'Registration failed',
          };
        }
        return {
          'success': false,
          'message': data['detail'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ---------------- Login ----------------
  static Future<Map<String, dynamic>> login(
      String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': username,
          'password': password,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Login successful',
          'email': data['email'],
          'setup_complete': data['setup_complete'] ?? false,
          'created_at': data['created_at'],
        };
      } else {
        return {
          'success': false,
          'message': data['detail'] ?? 'Login failed',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ---------------- Setup User ----------------
  static Future<Map<String, dynamic>> setupUser(
      String email,
      String name,
      String gender,
      int age,
      String mobileNumber,
      String aadhar,
      String passport,
      String emergencyNumber,
      String medicalConditions,
      String allergies) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/profile/email/$email'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'gender': gender,
          'age': age,
          'mobile_number': mobileNumber,
          'aadhar_number': aadhar,
          'passport': passport,
          'emergency_contact': emergencyNumber,
          'medical_conditions': medicalConditions,
          'allergies': allergies,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {
          'success': false,
          'message': data['detail'] ?? 'Setup failed',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ---------------- Get User Setup ----------------
  static Future<Map<String, dynamic>> getUserSetup(String username) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/$username/setup'),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message': data['detail'] ?? 'Failed to get user setup',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ---------------- Check Setup Status ----------------
  static Future<Map<String, dynamic>> checkSetupStatus(String username) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/$username/setup'),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'setup_complete': data['setup_complete'] ?? false,
        };
      } else {
        return {
          'success': false,
          'message': data['detail'] ?? 'Failed to check setup status',
        };
      } 
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
}
