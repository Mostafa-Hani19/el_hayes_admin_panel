import 'package:supabase_flutter/supabase_flutter.dart';

class Order {
  final String id;
  final String userId;
  final String name;
  final String address;
  final String phone;
  final String status;
  final DateTime createdAt;
  final List<OrderItem> items;
  final bool isSeen;

  Order({
    required this.id,
    required this.userId,
    required this.name,
    required this.address,
    required this.phone,
    required this.status,
    required this.createdAt,
    required this.items,
    required this.isSeen,
  });

  factory Order.fromJson(Map<String, dynamic> json, List<OrderItem> items) {
    return Order(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      phone: json['phone'] ?? '',
      status: json['status'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      items: items,
      isSeen: json['is_seen'] ?? false,
    );
  }

  static Stream<List<Order>> ordersStream() async* {
    final supabase = Supabase.instance.client;
    await for (final data in supabase.from('orders').stream(primaryKey: ['id'])) {
      yield (data as List)
          .map((json) => Order.fromJson(json, []))
          .toList();
    }
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