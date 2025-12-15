import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/product.dart';

class CartProvider with ChangeNotifier {
  String _apiUrl = '';
  List<Product> _products = [];
  final Map<int, CartItem> _items = {};
  bool _isLoading = false;

  void updateApiUrl(String url) {
    _apiUrl = url;
    // If we have an URL and no products, fetch them
    if (_apiUrl.isNotEmpty && _products.isEmpty) {
      fetchProducts();
    }
  }

  List<Product> get products => _products;
  Map<int, CartItem> get items => _items;
  bool get isLoading => _isLoading;

  int get itemCount => _items.length;

  double get totalAmount {
    var total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.total;
    });
    return total;
  }

  Future<void> fetchProducts() async {
    if (_apiUrl.isEmpty) return;

    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(Uri.parse('$_apiUrl/v1/products'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _products = data.map((item) => Product.fromJson(item)).toList();
      } else {
        if (kDebugMode) {
          print('Failed to fetch products: ${response.statusCode}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching products: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void addItem(Product product) {
    if (_items.containsKey(product.id)) {
      _items.update(
        product.id,
        (existingCartItem) => CartItem(
          product: existingCartItem.product,
          quantity: existingCartItem.quantity + 1,
        ),
      );
    } else {
      _items.putIfAbsent(
        product.id,
        () => CartItem(product: product),
      );
    }
    notifyListeners();
  }

  void removeSingleItem(int productId) {
    if (!_items.containsKey(productId)) {
      return;
    }
    if (_items[productId]!.quantity > 1) {
      _items.update(
        productId,
        (existingCartItem) => CartItem(
          product: existingCartItem.product,
          quantity: existingCartItem.quantity - 1,
        ),
      );
    } else {
      _items.remove(productId);
    }
    notifyListeners();
  }

  void removeItem(int productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
