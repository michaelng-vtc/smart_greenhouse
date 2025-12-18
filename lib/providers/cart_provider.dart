import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../models/product.dart';
import '../models/order.dart';
import '../models/sale.dart';

class CartProvider with ChangeNotifier {
  String _apiUrl = '';
  List<Product> _products = [];
  List<Product> _userProducts = [];
  List<Order> _orders = [];
  List<Sale> _sales = [];
  final Map<int, CartItem> _items = {};
  bool _isLoading = false;

  List<Order> get orders => _orders;
  List<Sale> get sales => _sales;

  String get apiUrl => _apiUrl;

  void updateApiUrl(String url) {
    _apiUrl = url;
    // If we have an URL and no products, fetch them
    if (_apiUrl.isNotEmpty && _products.isEmpty) {
      fetchProducts();
    }
  }

  List<Product> get products => _products;
  List<Product> get userProducts => _userProducts;
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

  double get totalEarnings {
    var total = 0.0;
    for (var sale in _sales) {
      total += sale.total;
    }
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

  Future<String?> uploadImage(dynamic imageFile, {int? userId}) async {
    if (_apiUrl.isEmpty) return null;
    try {
      // _apiUrl is like http://ip/api/public
      // upload endpoint is http://ip/api/public/v1/upload
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_apiUrl/v1/upload'),
      );

      if (userId != null) {
        request.fields['user_id'] = userId.toString();
      }

      if (kIsWeb) {
        // For web, imageFile should be XFile
        if (imageFile is! XFile) return null;
        final bytes = await imageFile.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            bytes,
            filename: imageFile.name,
          ),
        );
      } else {
        // For mobile, imageFile can be File or XFile
        String path;
        if (imageFile is File) {
          path = imageFile.path;
        } else if (imageFile is XFile) {
          path = imageFile.path;
        } else {
          return null;
        }
        request.files.add(await http.MultipartFile.fromPath('image', path));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['url'];
      } else {
        if (kDebugMode) {
          print('Upload failed with status: ${response.statusCode}');
          print('Response body: ${response.body}');
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) print('Error uploading image: $e');
      return null;
    }
  }

  Future<bool> addProduct(
    String name,
    String description,
    double price,
    int stock, {
    String? imageUrl,
    int? userId,
  }) async {
    if (_apiUrl.isEmpty) return false;

    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/v1/products'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'description': description,
          'price': price,
          'stock': stock,
          'image_url': imageUrl ?? 'assets/images/default_seed.png',
          'user_id': userId,
        }),
      );

      if (response.statusCode == 201) {
        await fetchProducts(); // Refresh list
        if (userId != null) {
          await fetchUserProducts(userId);
        }
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error adding product: $e');
      }
      return false;
    }
  }

  Future<void> fetchUserProducts(int userId) async {
    if (_apiUrl.isEmpty) return;

    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$_apiUrl/v1/products?user_id=$userId'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _userProducts = data.map((item) => Product.fromJson(item)).toList();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching user products: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteProduct(int productId) async {
    if (_apiUrl.isEmpty) return false;

    try {
      final response = await http.delete(
        Uri.parse('$_apiUrl/v1/products/$productId'),
      );

      if (response.statusCode == 200) {
        await fetchProducts(); // Refresh main list
        // Note: We can't easily refresh user list here without userId,
        // so the UI should handle calling fetchUserProducts again or we rely on local removal
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting product: $e');
      }
      return false;
    }
  }

  void addItem(Product product) {
    if (_items.containsKey(product.id)) {
      if (_items[product.id]!.quantity >= product.stock) {
        return;
      }
      _items.update(
        product.id,
        (existingCartItem) => CartItem(
          product: existingCartItem.product,
          quantity: existingCartItem.quantity + 1,
        ),
      );
    } else {
      if (product.stock > 0) {
        _items.putIfAbsent(product.id, () => CartItem(product: product));
      }
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

  Future<void> fetchSales(int userId) async {
    if (_apiUrl.isEmpty) return;

    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$_apiUrl/v1/orders/sales/$userId'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _sales = data.map((item) => Sale.fromJson(item)).toList();
      } else {
        if (kDebugMode) {
          print('Failed to fetch sales: ${response.statusCode}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching sales: $e');
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
        await fetchProducts(); // Refresh products to update stock
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
