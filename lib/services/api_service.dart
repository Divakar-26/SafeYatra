import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "https://121b16992cad.ngrok-free.app";
  static const _jsonHeaders = {'Content-Type': 'application/json'};

  static Future<Map<String, dynamic>> register(
      String fullName,
      String email,
      String password,
      String confirmPassword,
      ) async {
    final uri = Uri.parse('$baseUrl/register');
    try {
      final resp = await http
          .post(
        uri,
        headers: _jsonHeaders,
        body: json.encode({
          'full_name': fullName,
          'email': email,
          'password': password,
          'confirm_password': confirmPassword,
        }),
      )
          .timeout(const Duration(seconds: 20));

      final body = resp.body.isNotEmpty ? resp.body : '{}';
      Map<String, dynamic> data;
      try {
        data = json.decode(body) as Map<String, dynamic>;
      } catch (_) {
        data = {'raw': body};
      }

      if (resp.statusCode == 200) {
        return {
          'success': true,
          'user_id': data['user_id'],
          'message': data['message'] ?? 'Registration successful',
        };
      }

      // Bubble up server message for debugging
      final detail = data['detail'];
      final message = (detail is List && detail.isNotEmpty)
          ? (detail.first['msg'] ?? 'Registration failed')
          : (detail?.toString() ?? data['raw']?.toString() ?? 'Registration failed (${resp.statusCode})');

      return {'success': false, 'message': message};
    } on Exception catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> login(
      String username,
      String password,
      ) async {
    final uri = Uri.parse('$baseUrl/login');
    try {
      final resp = await http
          .post(
        uri,
        headers: _jsonHeaders,
        body: json.encode({'email': username, 'password': password}),
      )
          .timeout(const Duration(seconds: 20));

      final body = resp.body.isNotEmpty ? resp.body : '{}';
      Map<String, dynamic> data;
      try {
        data = json.decode(body) as Map<String, dynamic>;
      } catch (_) {
        data = {'raw': body};
      }

      if (resp.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Login successful',
          'email': data['email'],
          'name': data['name'],
          'setup_complete': data['setup_complete'] ?? false,
          'created_at': data['created_at'],
        };
      }

      return {
        'success': false,
        'message': data['detail']?.toString() ?? data['raw']?.toString() ?? 'Login failed (${resp.statusCode})',
      };
    } on Exception catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

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
      String allergies,
      {bool shareHealth = false,      // Add optional parameters
        bool shareLocation = false}
      ) async {
    final uri = Uri.parse('$baseUrl/profile/email/$email');
    try {
      final resp = await http
          .post(
        uri,
        headers: _jsonHeaders,
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
          'share_health': shareHealth,        // Add these
          'share_location': shareLocation,    // Add these
        }),
      )
          .timeout(const Duration(seconds: 20));

      final body = resp.body.isNotEmpty ? resp.body : '{}';
      Map<String, dynamic> data;
      try {
        data = json.decode(body) as Map<String, dynamic>;
      } catch (_) {
        data = {'raw': body};
      }

      if (resp.statusCode == 200) {
        return {'success': true, 'message': data['message'] ?? 'Setup successful'};
      }
      return {
        'success': false,
        'message': data['detail']?.toString() ?? data['raw']?.toString() ?? 'Setup failed (${resp.statusCode})',
      };
    } on Exception catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getUserSetup(String username) async {
    final uri = Uri.parse('$baseUrl/user/$username/setup');
    try {
      final resp = await http.get(uri).timeout(const Duration(seconds: 20));
      final body = resp.body.isNotEmpty ? resp.body : '{}';
      Map<String, dynamic> data;
      try {
        data = json.decode(body) as Map<String, dynamic>;
      } catch (_) {
        data = {'raw': body};
      }

      if (resp.statusCode == 200) {
        return {'success': true, 'data': data};
      }
      return {
        'success': false,
        'message': data['detail']?.toString() ?? data['raw']?.toString() ?? 'Failed to get user setup (${resp.statusCode})',
      };
    } on Exception catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> checkSetupStatus(String username) async {
    final uri = Uri.parse('$baseUrl/user/$username/setup');
    try {
      final resp = await http.get(uri).timeout(const Duration(seconds: 20));
      final body = resp.body.isNotEmpty ? resp.body : '{}';
      Map<String, dynamic> data;
      try {
        data = json.decode(body) as Map<String, dynamic>;
      } catch (_) {
        data = {'raw': body};
      }

      if (resp.statusCode == 200) {
        return {'success': true, 'setup_complete': data['setup_complete'] ?? false};
      }
      return {
        'success': false,
        'message': data['detail']?.toString() ?? data['raw']?.toString() ?? 'Failed to check setup status (${resp.statusCode})',
      };
    } on Exception catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
  static Future<Map<String, dynamic>> getProfileByEmail(String email) async {
    if (email.isEmpty) {
      return {'success': false, 'message': 'Email is empty'};
    }

    final encodedEmail = Uri.encodeComponent(email.trim());
    final uri = Uri.parse('$baseUrl/profile/email/$encodedEmail');

    print('Fetching profile for email: $email'); // Debug log
    print('Encoded email: $encodedEmail'); // Debug log
    print('Request URL: $uri'); // Debug log

    try {
      final resp = await http.get(uri).timeout(const Duration(seconds: 20));

      print('Response status: ${resp.statusCode}'); // Debug log
      print('Response body: ${resp.body}'); // Debug log

      final body = resp.body.isNotEmpty ? resp.body : '{}';

      Map<String, dynamic> data;
      try {
        data = json.decode(body) as Map<String, dynamic>;
      } catch (_) {
        data = {'raw': body};
      }

      if (resp.statusCode == 200) {
        return {'success': true, 'data': data};
      }
      return {
        'success': false,
        'message': data['detail']?.toString() ??
            data['raw']?.toString() ??
            'Failed to get profile (${resp.statusCode})',
      };
    } on Exception catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateUserLocation(
      String email,
      double latitude,
      double longitude,
      ) async {
    final uri = Uri.parse('$baseUrl/location/$email');
    try {
      final resp = await http
          .post(
        uri,
        headers: _jsonHeaders,
        body: json.encode({
          'latitude': latitude,
          'longitude': longitude,
        }),
      )
          .timeout(const Duration(seconds: 10));

      final body = resp.body.isNotEmpty ? resp.body : '{}';
      Map<String, dynamic> data;
      try {
        data = json.decode(body) as Map<String, dynamic>;
      } catch (_) {
        data = {'raw': body};
      }

      if (resp.statusCode == 200) {
        return {'success': true, 'message': data['message'] ?? 'Location updated'};
      }

      return {
        'success': false,
        'message': data['detail']?.toString() ??
            data['raw']?.toString() ??
            'Location update failed (${resp.statusCode})',
      };
    } on Exception catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
}
