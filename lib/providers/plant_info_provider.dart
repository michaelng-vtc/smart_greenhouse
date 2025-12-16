import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/plant_info.dart';
import '../models/comment.dart';

class PlantInfoProvider with ChangeNotifier {
  List<PlantInfo> _items = [];
  List<Comment> _comments = [];
  bool _isLoading = false;
  String _apiUrl = '';

  List<PlantInfo> get items => _items;
  List<Comment> get comments => _comments;
  bool get isLoading => _isLoading;

  void setApiUrl(String url) {
    _apiUrl = url;
  }

  Future<void> fetchPlantInfo() async {
    if (_apiUrl.isEmpty) return;

    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(Uri.parse('$_apiUrl/v1/plant-info'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _items = data.map((item) => PlantInfo.fromJson(item)).toList();
      } else {
        if (kDebugMode) {
          print('Failed to fetch plant info: ${response.statusCode}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching plant info: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addPlantInfo(
    String title,
    String content,
    String? imageUrl,
  ) async {
    if (_apiUrl.isEmpty) return false;

    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/v1/plant-info'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'title': title,
          'content': content,
          'image_url': imageUrl,
        }),
      );

      if (response.statusCode == 201) {
        await fetchPlantInfo(); // Refresh list
        return true;
      } else {
        if (kDebugMode) {
          print('Failed to add plant info: ${response.statusCode}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error adding plant info: $e');
      }
      return false;
    }
  }

  Future<void> fetchComments(int plantInfoId) async {
    if (_apiUrl.isEmpty) return;

    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$_apiUrl/v1/plant-info/$plantInfoId/comments'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _comments = data.map((item) => Comment.fromJson(item)).toList();
      } else {
        if (kDebugMode) {
          print('Failed to fetch comments: ${response.statusCode}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching comments: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addComment(int plantInfoId, int userId, String content) async {
    if (_apiUrl.isEmpty) return false;

    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/v1/plant-info/$plantInfoId/comments'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'user_id': userId, 'content': content}),
      );

      if (response.statusCode == 201) {
        await fetchComments(plantInfoId); // Refresh comments
        return true;
      } else {
        if (kDebugMode) {
          print('Failed to add comment: ${response.statusCode}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error adding comment: $e');
      }
      return false;
    }
  }
}
