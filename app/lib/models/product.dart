class Product {
  final String productId;
  final String name;
  final String description;
  final double price;
  final String category;
  final String imageUrl;
  final bool availability;

  Product({
    required this.productId,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.imageUrl,
    required this.availability,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      productId: json['product_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      category: json['category'] as String,
      imageUrl: json['image_url'] as String,
      availability: json['availability'] as bool,
    );
  }
}
