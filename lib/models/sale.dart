class Sale {
  final int productId;
  final String productName;
  final int quantity;
  final double price;
  final int orderId;
  final DateTime createdAt;

  Sale({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    required this.orderId,
    required this.createdAt,
  });

  factory Sale.fromJson(Map<String, dynamic> json) {
    return Sale(
      productId: int.parse(json['product_id'].toString()),
      productName: json['product_name'] ?? 'Unknown',
      quantity: int.parse(json['quantity'].toString()),
      price: double.parse(json['price'].toString()),
      orderId: int.parse(json['order_id'].toString()),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  double get total => price * quantity;
}
