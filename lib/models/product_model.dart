class Product {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final double price;
  final String categoryId;
  final DateTime createdAt;
  final bool isAvailable; 

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.price,
    required this.categoryId,
    required this.createdAt,
    required this.isAvailable,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      imageUrl: json['image_url']?.toString() ?? '',
      price: (json['price'] is int)
          ? (json['price'] as int).toDouble()
          : (json['price'] is double)
              ? json['price']
              : double.tryParse(json['price']?.toString() ?? '0.0') ?? 0.0,
      categoryId: json['category_id']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      isAvailable: json['is_available'] ?? true, 
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image_url': imageUrl,
      'price': price,
      'category_id': categoryId,
      'created_at': createdAt.toIso8601String(),
      'is_available': isAvailable, 
    };
  }
}
