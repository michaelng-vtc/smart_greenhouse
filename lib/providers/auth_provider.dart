import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AuthProvider with ChangeNotifier {
  // Replace with your actual API URL
  static const String _baseUrl = 'http://192.168.1.217/api/public';

  bool _isAuthenticated = false;
  String? _username;
  int? _userId;
  String? _errorMessage;

  bool get isAuthenticated => _isAuthenticated;
  String? get username => _username;
  int? get userId => _userId;
  String? get errorMessage => _errorMessage;

  Future<bool> checkUsername(String username) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/v1/auth/check-username?username=$username'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['exists'] == true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking username: $e');
      }
      return false;
    }
  }

  Future<bool> login(String username, String password) async {
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/v1/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _isAuthenticated = true;
        _username = data['user']['username'];
        // Handle ID whether it comes as int or String
        _userId = int.tryParse(data['user']['id'].toString());
        notifyListeners();
        return true;
      } else {
        final data = jsonDecode(response.body);
        _errorMessage = data['error'] ?? 'Login failed';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Connection error: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String username, String email, String password) async {
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/v1/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 201) {
        return true;
      } else {
        final data = jsonDecode(response.body);
        _errorMessage = data['error'] ?? 'Registration failed';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Connection error: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> verify(String email, String code) async {
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/v1/auth/verify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'code': code}),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final data = jsonDecode(response.body);
        _errorMessage = data['error'] ?? 'Verification failed';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Connection error: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> resendCode(String email) async {
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/v1/auth/resend'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final data = jsonDecode(response.body);
        _errorMessage = data['error'] ?? 'Failed to resend code';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Connection error: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/v1/auth/change-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': _userId,
          'old_password': oldPassword,
          'new_password': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final data = jsonDecode(response.body);
        _errorMessage = data['error'] ?? 'Failed to change password';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Connection error: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> changeUsername(String newUsername) async {
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/v1/auth/change-username'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': _userId, 'new_username': newUsername}),
      );

      if (response.statusCode == 200) {
        _username = newUsername;
        notifyListeners();
        return true;
      } else {
        final data = jsonDecode(response.body);
        _errorMessage = data['error'] ?? 'Failed to change username';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Connection error: $e';
      notifyListeners();
      return false;
    }
  }

  void logout() {
    _isAuthenticated = false;
    _username = null;
    _userId = null;
    notifyListeners();
  }
}
