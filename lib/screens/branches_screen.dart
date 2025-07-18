import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/branch_model.dart';
import '../services/branch_service.dart';
import 'branch_products_screen.dart';
import '../widgets/sidebar_menu.dart';
import '../utils/constants.dart';

class BranchesScreen extends StatefulWidget {
  const BranchesScreen({Key? key}) : super(key: key);

  @override
  State<BranchesScreen> createState() => _BranchesScreenState();
}

class _BranchesScreenState extends State<BranchesScreen> {
  late BranchService branchService;
  List<Branch> branches = [];
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    branchService = BranchService(Supabase.instance.client);
    _loadBranches();
  }

  Future<void> _loadBranches() async {
    final data = await branchService.fetchBranches();
    setState(() {
      branches = data;
    });
  }

  Future<void> _addBranch() async {
    await branchService.addBranch(_nameController.text, _addressController.text);
    _nameController.clear();
    _addressController.clear();
    _loadBranches();
  }

  Future<void> _deleteBranch(String id) async {
    await branchService.deleteBranch(id);
    _loadBranches();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Constants.isMobile(context);
    final isTablet = Constants.isTablet(context);
    final isDesktop = Constants.isDesktop(context);
    final maxContentWidth = isDesktop ? 1100.0 : isTablet ? 800.0 : double.infinity;
    final horizontalPadding = isMobile ? 4.0 : isTablet ? 16.0 : 32.0;
    final verticalPadding = isMobile ? 4.0 : isTablet ? 8.0 : 24.0;
    final Color bgGradientStart = Colors.grey[100]!;
    final Color bgGradientEnd = Colors.blueGrey[50]!;

    return Scaffold(
      extendBodyBehindAppBar: false,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Branches'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: isMobile ? const SidebarMenu() : null,
        backgroundColor: Colors.white.withOpacity(0.85),
        elevation: 0.5,
      ),
      drawer: isMobile ? const SidebarMenu() : null,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [bgGradientStart, bgGradientEnd],
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMobile) const SidebarMenu(),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxContentWidth),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: verticalPadding,
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _nameController,
                                  decoration: const InputDecoration(labelText: 'Branch Name'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _addressController,
                                  decoration: const InputDecoration(labelText: 'Address'),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: _addBranch,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: branches.length,
                            itemBuilder: (context, index) {
                              final branch = branches[index];
                              return ListTile(
                                title: Text(branch.name),
                                subtitle: Text(branch.address),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.settings),
                                      tooltip: 'Manage Products',
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) => BranchProductsScreen(branch: branch),
                                          ),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      tooltip: 'Delete Branch',
                                      onPressed: () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Delete Branch'),
                                            content: const Text('Are you sure you want to delete this branch?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.of(context).pop(false),
                                                child: const Text('Cancel'),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.of(context).pop(true),
                                                child: const Text('Delete'),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirm == true) {
                                          _deleteBranch(branch.id);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 