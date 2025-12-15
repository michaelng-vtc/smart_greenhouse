class Product {
  final int id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final int stock;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.stock,
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
    );
  }
}

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get total => product.price * quantity;
}
