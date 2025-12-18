class Product {
  final int id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final int stock;
  final int? userId;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.stock,
    this.userId,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: json['name'],
      description: json['description'] ?? '',
      price: json['price'] is double
          ? json['price']
          : double.parse(json['price'].toString()),
      imageUrl: json['image_url'] ?? '',
      stock: json['stock'] is int
          ? json['stock']
          : int.parse(json['stock'].toString()),
      userId: json['user_id'] != null
          ? (json['user_id'] is int
                ? json['user_id']
                : int.tryParse(json['user_id'].toString()))
          : null,
    );
  }
}

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get total => product.price * quantity;
}
