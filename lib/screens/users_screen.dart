// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/sidebar_menu.dart';
import '../models/user_model.dart';
import 'package:intl/intl.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List<UserModel> _users = [];
  List<UserModel> _filteredUsers = [];
  bool _isLoading = true;
  // ignore: unused_field
  final String _searchQuery = '';
  String _filterType = 'all'; // 'all', 'admin', 'customer'
  // ignore: unused_field
  UserModel? _selectedUser;
  
  final TextEditingController _searchController = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final supabase = authProvider.supabaseClient;
      
      debugPrint('Loading users from database...');
      
      // Fetch users with detailed information
      final response = await supabase
          .from('profiles')
          .select('id, email, created_at, is_admin, full_name')
          .order('created_at', ascending: false);
      
      debugPrint('Fetched ${response.length} users');
      
      // Map the response to UserModel objects
      final List<UserModel> fetchedUsers = [];
      for (final user in response) {
        try {
          final userModel = UserModel.fromJson(user);
          fetchedUsers.add(userModel);
          debugPrint('Added user: ${userModel.email}, admin: ${userModel.role}');
        } catch (e) {
          debugPrint('Error parsing user: $e');
          debugPrint('Raw user data: $user');
        }
      }
      
      if (mounted) {
        setState(() {
          _users = fetchedUsers;
          _filteredUsers = fetchedUsers;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading users: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to load users: $e';
          _isLoading = false;
        });
      }
    }
  }
  
  void _applyFilters() {
    if (!mounted) return;
    
    final searchQuery = _searchController.text.toLowerCase().trim();
    
    setState(() {
      _filteredUsers = _users.where((user) {
        // Apply role filter
        if (_filterType == 'admin' && user.role != 'admin') {
          return false;
        }
        if (_filterType == 'customer' && user.role == 'admin') {
          return false;
        }
        
        // Apply search filter if query is not empty
        if (searchQuery.isNotEmpty) {
          return user.email.toLowerCase().contains(searchQuery) ||
              (user.fullName?.toLowerCase().contains(searchQuery) ?? false) ||
              user.role.toLowerCase().contains(searchQuery);
        }
        
        return true;
      }).toList();
    });
  }
  
  Future<void> _toggleUserStatus(UserModel user) async {
    // Show confirmation dialog first
    final bool confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(user.role == 'admin' ? 'Demote to Customer?' : 'Promote to Admin?'),
          content: Text(
            user.role == 'admin'
                ? 'Are you sure you want to change ${user.email} from admin to customer?'
                : 'Are you sure you want to change ${user.email} from customer to admin?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    ) ?? false;
    
    if (!confirm) return;
    
    final newAdminStatus = user.role != 'admin';
    
    // Try both methods to ensure it works
    try {
      // First try direct database update
      await _directToggleUserStatus(user, newAdminStatus);
    } catch (e) {
      debugPrint('Direct toggle failed: $e');
      try {
        // Then try RPC method as fallback
        await _changeUserRoleViaRPC(user.email, newAdminStatus);
      } catch (e2) {
        debugPrint('RPC toggle also failed: $e2');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to change user role: $e2')),
          );
        }
      }
    }
  }
  
  Future<void> _directToggleUserStatus(UserModel user, bool makeAdmin) async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final supabase = authProvider.supabaseClient;
      
      // Toggle is_admin status
      debugPrint('Toggling user ${user.email} admin status from ${user.role == 'admin'} to $makeAdmin');
      
      // Use a direct SQL-like update
      final updateResponse = await supabase
          .from('profiles')
          .update({'is_admin': makeAdmin})
          .eq('id', user.id)
          .select();
      
      debugPrint('Update response: $updateResponse');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User ${makeAdmin ? 'promoted to admin' : 'demoted to customer'}')),
        );
      }
      
      // Refresh user list
      _loadUsers();
    } catch (e) {
      debugPrint('Error toggling user status: $e');
      rethrow; // Rethrow to try the RPC method
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _changeUserRoleViaRPC(String email, bool makeAdmin) async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final supabase = authProvider.supabaseClient;
      
      // Call the RPC function to change user role
      final response = await supabase.rpc(
        'change_user_role',
        params: {
          'user_email': email,
          'is_admin': makeAdmin,
        },
      );
      
      debugPrint('RPC response: $response');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User ${makeAdmin ? 'promoted to admin' : 'demoted to customer'}')),
        );
      }
      
      // Refresh user list
      _loadUsers();
    } catch (e) {
      debugPrint('Error in RPC change_user_role: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating user role: $e')),
        );
      }
      rethrow;
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showCreateAdminDialog() async {
    final formKey = GlobalKey<FormState>();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final fullNameController = TextEditingController();

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Create Admin User'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: fullNameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Create'),
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  try {
                    final authProvider = Provider.of<AuthProvider>(context, listen: false);
                    final supabase = authProvider.supabaseClient;

                    // Create user with email and password
                    final authResponse = await supabase.auth.signUp(
                      email: emailController.text,
                      password: passwordController.text,
                    );

                    if (authResponse.user != null) {
                      // Update profile with admin role
                      await supabase.from('profiles').update({
                        'full_name': fullNameController.text,
                        'is_admin': true,
                      }).eq('id', authResponse.user!.id);

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Admin user created successfully')),
                        );
                      }

                      // Refresh user list
                      _loadUsers();
                    }

                    if (mounted) {
                      Navigator.of(context).pop();
                    }
                  } catch (e) {
                    debugPrint('Error creating admin user: $e');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error creating admin user: $e')),
                      );
                    }
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteUser(UserModel user) async {
    bool isSubmitting = false;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Delete User'),
              content: Text('Are you sure you want to delete user "${user.email}"?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          setState(() => isSubmitting = true);
                          try {
                            final authProvider = Provider.of<AuthProvider>(context, listen: false);
                            final supabase = authProvider.supabaseClient;
                            final result = await supabase.from('profiles').delete().eq('id', user.id).select();
                            if (mounted) {
                              // ignore: unnecessary_type_check
                              if (result is List && result.isNotEmpty) {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('User deleted successfully')),
                                );
                                _loadUsers();
                              } else {
                                setState(() => isSubmitting = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Delete failed: No rows affected. Check RLS policies and user ID.')),
                                );
                              }
                            }
                          } catch (e) {
                            setState(() => isSubmitting = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Delete'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;
    final isTablet = width >= 600 && width < 1024;
    final isDesktop = width >= 1024;
    final maxContentWidth = isDesktop ? 1100.0 : isTablet ? 800.0 : double.infinity;
    final horizontalPadding = isMobile ? 4.0 : isTablet ? 16.0 : 32.0;
    final verticalPadding = isMobile ? 4.0 : isTablet ? 8.0 : 24.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        automaticallyImplyLeading: false,
        leading: isMobile ? const SidebarMenu() : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadUsers,
          ),
          const SizedBox(width: 16),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateAdminDialog,
        tooltip: 'Add Admin User',
        child: const Icon(Icons.add),
      ),
      drawer: isMobile ? const SidebarMenu() : null,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isMobile) const SidebarMenu(),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: maxContentWidth,
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                        vertical: verticalPadding,
                      ),
                      child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _error != null
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Error loading users',
                                    style: TextStyle(
                                      fontSize: isMobile ? 16 : 20,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.error,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(_error!),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: _loadUsers,
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Retry'),
                                  ),
                                ],
                              ),
                            )
                          : Column(
                              children: [
                                Padding(
                                  padding: EdgeInsets.all(isMobile ? 8.0 : isTablet ? 12.0 : 20.0),
                                  child: isMobile
                                    ? Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: _buildFilterRow(isMobile, isTablet),
                                      )
                                    : Row(
                                        children: _buildFilterRow(isMobile, isTablet),
                                      ),
                                ),
                                Expanded(
                                  child: _filteredUsers.isEmpty
                                    ? const Center(child: Text('No users found'))
                                    : _buildResponsiveLayout(isMobile, isTablet, isDesktop),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildFilterRow(bool isMobile, bool isTablet) {
    return [
      Expanded(
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            labelText: 'Search Users',
            hintText: 'Enter name, email or role',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                _applyFilters();
              },
            ),
          ),
          onChanged: (value) {
            _applyFilters();
          },
        ),
      ),
      SizedBox(width: isMobile ? 8 : 16),
      DropdownButton<String>(
        value: _filterType,
        items: const [
          DropdownMenuItem(value: 'all', child: Text('All Users')),
          DropdownMenuItem(value: 'admin', child: Text('Admins')),
          DropdownMenuItem(value: 'customer', child: Text('Customers')),
        ],
        onChanged: (value) {
          setState(() {
            _filterType = value ?? 'all';
            _applyFilters();
          });
        },
      ),
    ];
  }

  Widget _buildResponsiveLayout(bool isMobile, bool isTablet, [bool isDesktop = false]) {
    if (isMobile) {
      return ListView.builder(
        itemCount: _filteredUsers.length,
        itemBuilder: (context, index) {
          final user = _filteredUsers[index];
          return _buildUserListItem(user, isMobile, isTablet, isDesktop);
        },
      );
    } else {
      return SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: isDesktop ? 32 : isTablet ? 20 : 12,
            columns: const [
              DataColumn(label: Text('Name')),
              DataColumn(label: Text('Email')),
              DataColumn(label: Text('Role')),
              DataColumn(label: Text('Registration Date')),
              DataColumn(label: Text('Actions')),
            ],
            rows: _filteredUsers.map((user) {
              return DataRow(
                cells: [
                  DataCell(Text(user.fullName ?? 'N/A', style: TextStyle(fontSize: isDesktop ? 16 : 14))),
                  DataCell(Text(user.email, style: TextStyle(fontSize: isDesktop ? 16 : 14))),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          user.role == 'admin' ? Icons.admin_panel_settings : Icons.person,
                          color: user.role == 'admin' ? Colors.red : Colors.blue,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(user.role, style: TextStyle(fontSize: isDesktop ? 16 : 14)),
                      ],
                    ),
                  ),
                  DataCell(Text(DateFormat('MMM d, yyyy').format(user.createdAt), style: TextStyle(fontSize: isDesktop ? 16 : 14))),
                  DataCell(Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          user.role == 'admin' ? Icons.person : Icons.admin_panel_settings,
                          color: user.role == 'admin' ? Colors.blue : Colors.red,
                        ),
                        tooltip: user.role == 'admin' ? 'Demote to Customer' : 'Promote to Admin',
                        onPressed: () => _toggleUserStatus(user),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Delete User',
                        onPressed: () => _deleteUser(user),
                      ),
                    ],
                  )),
                ],
              );
            }).toList(),
          ),
        ),
      );
    }
  }

  Widget _buildUserListItem(UserModel user, bool isMobile, bool isTablet, bool isDesktop) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 16, vertical: isMobile ? 4 : 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: user.role == 'admin' ? Colors.red.shade100 : Colors.blue.shade100,
          child: Icon(
            user.role == 'admin' ? Icons.admin_panel_settings : Icons.person,
            color: user.role == 'admin' ? Colors.red : Colors.blue,
          ),
        ),
        title: Text(user.fullName ?? 'N/A', style: TextStyle(fontSize: isMobile ? 15 : 17, fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email, style: TextStyle(fontSize: isMobile ? 13 : 15)),
            Text(
              'Registered: ${DateFormat('MMM d, yyyy').format(user.createdAt)}',
              style: TextStyle(fontSize: isMobile ? 11 : 13, color: Colors.grey.shade600),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                user.role == 'admin' ? Icons.person : Icons.admin_panel_settings,
                color: user.role == 'admin' ? Colors.blue : Colors.red,
              ),
              tooltip: user.role == 'admin' ? 'Demote to Customer' : 'Promote to Admin',
              onPressed: () => _toggleUserStatus(user),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: 'Delete User',
              onPressed: () => _deleteUser(user),
            ),
          ],
        ),
      ),
    );
  }
} 