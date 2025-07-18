import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/branch_model.dart';

class BranchService {
  final SupabaseClient client;

  BranchService(this.client);

  Future<List<Branch>> fetchBranches() async {
    final response = await client.from('branches').select().then((value) => value);
    final data = response as List;
    return data.map((e) => Branch.fromMap(e)).toList();
  }

  Future<void> addBranch(String name, String address) async {
    await client.from('branches').insert({'name': name, 'address': address});
  }

  Future<void> deleteBranch(String id) async {
    await client.from('branches').delete().eq('id', id);
  }
} 