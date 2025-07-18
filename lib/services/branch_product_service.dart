import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/branch_product_model.dart';

class BranchProductService {
  final SupabaseClient client;

  BranchProductService(this.client);

  Future<List<BranchProduct>> fetchBranchProducts(String branchId) async {
    final response = await client
        .from('branch_products')
        .select()
        .eq('branch_id', branchId);
    final data = response as List;
    return data.map((e) => BranchProduct.fromMap(e)).toList();
  }

  Future<void> setProductAvailability(String branchId, String productId, bool isAvailable) async {
    if (isAvailable) {
      // If available, delete the row
      await deleteBranchProduct(branchId, productId);
    } else {
      // If unavailable, upsert with is_available=false
      await client.from('branch_products').upsert({
        'branch_id': branchId,
        'product_id': productId,
        'is_available': false,
      });
    }
  }

  Future<void> deleteBranchProduct(String branchId, String productId) async {
    await client.from('branch_products')
      .delete()
      .eq('branch_id', branchId)
      .eq('product_id', productId);
  }
} 