import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/product.dart';
import '../models/order.dart';

class CartProvider with ChangeNotifier {
  String _apiUrl = '';
  List<Product> _products = [];
  List<Order> _orders = [];
  final Map<int, CartItem> _items = {};
  bool _isLoading = false;

  List<Order> get orders => _orders;

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
      _items.putIfAbsent(product.id, () => CartItem(product: product));
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

  Future<void> fetchOrders(int userId) async {
    if (_apiUrl.isEmpty) return;

    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$_apiUrl/v1/orders/user/$userId'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _orders = data.map((item) => Order.fromJson(item)).toList();
      } else {
        if (kDebugMode) {
          print('Failed to fetch orders: ${response.statusCode}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching orders: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submitOrder(int userId) async {
    if (_apiUrl.isEmpty || _items.isEmpty) return false;

    try {
      final orderItems = _items.values
          .map(
            (cartItem) => {
              'product_id': cartItem.product.id,
              'quantity': cartItem.quantity,
              'price': cartItem.product.price,
            },
          )
          .toList();

      final response = await http.post(
        Uri.parse('$_apiUrl/v1/orders'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'items': orderItems,
          'total_amount': totalAmount,
        }),
      );

      if (response.statusCode == 201) {
        clear();
        return true;
      } else {
        if (kDebugMode) {
          print('Failed to submit order: ${response.statusCode}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error submitting order: $e');
      }
      return false;
    }
  }
}
