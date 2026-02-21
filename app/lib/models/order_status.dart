class OrderStatus {
  final String orderId;
  final String status;
  final String lastUpdated;

  OrderStatus({
    required this.orderId,
    required this.status,
    required this.lastUpdated,
  });

  factory OrderStatus.fromJson(Map<String, dynamic> json) {
    return OrderStatus(
      orderId: json['order_id'] as String,
      status: json['status'] as String,
      lastUpdated: json['last_updated'] as String,
    );
  }
}
