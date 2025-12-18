import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';
import '../models/chat_user.dart';

class ChatProvider with ChangeNotifier {
  List<ChatMessage> _messages = [];
  List<ChatUser> _users = [];
  bool _isLoading = false;
  String _apiUrl = '';
  Timer? _timer;
  int? _currentChatPartnerId;

  List<ChatMessage> get messages => _messages;
  List<ChatUser> get users => _users;
  bool get isLoading => _isLoading;

  void setApiUrl(String url) {
    _apiUrl = url;
  }

  void startPolling(int currentUserId, int otherUserId) {
    _currentChatPartnerId = otherUserId;
    fetchMessages(currentUserId, otherUserId);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_currentChatPartnerId == otherUserId) {
        fetchMessages(currentUserId, otherUserId);
      }
    });
  }

  void stopPolling() {
    _timer?.cancel();
    _currentChatPartnerId = null;
    _messages = []; // Clear messages when leaving chat
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }

  Future<void> fetchUsers(int currentUserId) async {
    if (_apiUrl.isEmpty) return;
    _isLoading = true;
    // notifyListeners(); // Avoid rebuilding just for loading state if not needed

    try {
      final response = await http.get(
        Uri.parse('$_apiUrl/v1/chat/users?current_user_id=$currentUserId'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _users = data.map((item) => ChatUser.fromJson(item)).toList();
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching users: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMessages(int currentUserId, int otherUserId) async {
    if (_apiUrl.isEmpty) return;

    try {
      final response = await http.get(
        Uri.parse(
          '$_apiUrl/v1/chat/messages/$otherUserId?user_id=$currentUserId',
        ),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final newMessages = data
            .map((item) => ChatMessage.fromJson(item))
            .toList();

        // Only notify if there are changes to avoid unnecessary rebuilds
        if (newMessages.length != _messages.length ||
            (newMessages.isNotEmpty &&
                _messages.isNotEmpty &&
                newMessages.last.id != _messages.last.id)) {
          _messages = newMessages;
          notifyListeners();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching messages: $e');
      }
    }
  }

  Future<bool> sendMessage(int senderId, int receiverId, String content) async {
    if (_apiUrl.isEmpty) return false;

    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/v1/chat/messages'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'sender_id': senderId,
          'receiver_id': receiverId,
          'content': content,
        }),
      );

      if (response.statusCode == 201) {
        await fetchMessages(senderId, receiverId); // Refresh immediately
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error sending message: $e');
      }
      return false;
    }
  }
}
