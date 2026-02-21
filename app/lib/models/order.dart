class OrderItem {
  final String productId;
  final int quantity;

  OrderItem({required this.productId, required this.quantity});

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['product_id'] as String,
      quantity: json['quantity'] as int,
    );
  }
}

class Order {
  final String orderRef;
  final String userId;
  final List<OrderItem> items;
  final double total;
  final String timestamp;

  Order({
    required this.orderRef,
    required this.userId,
    required this.items,
    required this.total,
    required this.timestamp,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    final list = json['items'] as List<dynamic>? ?? [];
    return Order(
      orderRef: json['order_ref'] as String,
      userId: json['user_id'] as String,
      items: list.map((e) => OrderItem.fromJson(e as Map<String, dynamic>)).toList(),
      total: (json['total'] as num).toDouble(),
      timestamp: json['timestamp'] as String,
    );
  }
}
