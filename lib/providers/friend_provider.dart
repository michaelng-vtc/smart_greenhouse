import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/chat_user.dart';

class FriendProvider with ChangeNotifier {
  List<ChatUser> _friends = [];
  List<dynamic> _pendingRequests = [];
  bool _isLoading = false;
  String _apiUrl = '';

  List<ChatUser> get friends => _friends;
  List<dynamic> get pendingRequests => _pendingRequests;
  bool get isLoading => _isLoading;

  void setApiUrl(String url) {
    _apiUrl = url;
  }

  Future<void> fetchFriends(int userId) async {
    if (_apiUrl.isEmpty) return;
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(Uri.parse('$_apiUrl/v1/friends/$userId'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _friends = data.map((item) => ChatUser.fromJson(item)).toList();
      }
    } catch (e) {
      if (kDebugMode) print('Error fetching friends: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchPendingRequests(int userId) async {
    if (_apiUrl.isEmpty) return;

    try {
      final response = await http.get(
        Uri.parse('$_apiUrl/v1/friends/requests/$userId'),
      );
      if (response.statusCode == 200) {
        _pendingRequests = json.decode(response.body);
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) print('Error fetching requests: $e');
    }
  }

  Future<String?> sendFriendRequest(int userId, String friendUsername) async {
    if (_apiUrl.isEmpty) return 'API URL not set';

    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/v1/friends/request'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'friend_username': friendUsername,
        }),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        return null; // Success
      } else {
        return data['error'] ?? 'Failed to send request';
      }
    } catch (e) {
      return 'Connection error: $e';
    }
  }

  Future<bool> acceptRequest(int userId, int requestId) async {
    if (_apiUrl.isEmpty) return false;

    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/v1/friends/accept'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'user_id': userId, 'request_id': requestId}),
      );

      if (response.statusCode == 200) {
        await fetchFriends(userId);
        await fetchPendingRequests(userId);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
