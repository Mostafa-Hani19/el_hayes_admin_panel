class Order {
  final String id;
  final String userId;
  final String address;
  final String phone;
  final String status;
  final DateTime createdAt;
  final List<OrderItem> items;

  Order({
    required this.id,
    required this.userId,
    required this.address,
    required this.phone,
    required this.status,
    required this.createdAt,
    required this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json, List<OrderItem> items) {
    return Order(
      id: json['id'],
      userId: json['user_id'],
      address: json['address'] ?? '',
      phone: json['phone'] ?? '',
      status: json['status'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      items: items,
    );
  }
}

class OrderItem {
  final String id;
  final String orderId;
  final String productId;
  final int quantity;
  final double price;

  OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.quantity,
    required this.price,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'],
      orderId: json['order_id'],
      productId: json['product_id'],
      quantity: json['quantity'],
      price: (json['price'] is int)
          ? (json['price'] as int).toDouble()
          : (json['price'] as num).toDouble(),
    );
  }
} 