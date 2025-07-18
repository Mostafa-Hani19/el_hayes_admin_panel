class BranchProduct {
  final String id;
  final String branchId;
  final String productId;
  final bool isAvailable;

  BranchProduct({
    required this.id,
    required this.branchId,
    required this.productId,
    required this.isAvailable,
  });

  factory BranchProduct.fromMap(Map<String, dynamic> map) {
    return BranchProduct(
      id: map['id'],
      branchId: map['branch_id'],
      productId: map['product_id'],
      isAvailable: map['is_available'] ?? true,
    );
  }
} 