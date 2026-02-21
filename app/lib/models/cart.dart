class CartItem {
  final String productId;
  final int quantity;

  CartItem({required this.productId, required this.quantity});

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      productId: json['product_id'] as String,
      quantity: json['quantity'] as int,
    );
  }
}

class Cart {
  final String userId;
  final List<CartItem> items;

  Cart({required this.userId, required this.items});

  factory Cart.fromJson(Map<String, dynamic> json) {
    final list = json['items'] as List<dynamic>? ?? [];
    return Cart(
      userId: json['user_id'] as String,
      items: list.map((e) => CartItem.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}
