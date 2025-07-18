// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import 'package:go_router/go_router.dart';

class SidebarMenu extends StatelessWidget {
  const SidebarMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentRoute = ModalRoute.of(context)?.settings.name;
    final isMobile = Constants.isMobile(context);
    final isTablet = Constants.isTablet(context);
    final isDesktop = !isMobile && !isTablet;

    // Responsive width
    double drawerWidth = MediaQuery.of(context).size.width;
    if (isMobile) {
      drawerWidth = drawerWidth;
    } else if (isTablet) {
      drawerWidth = 250;
    } else {
      drawerWidth = 280;
    }

    return Container(
      decoration: BoxDecoration(
        color: isDesktop ? Colors.white : null,
        borderRadius: isDesktop ? const BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ) : null,
        boxShadow: isDesktop
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.07),
                  blurRadius: 16,
                  offset: const Offset(2, 0),
                ),
              ]
            : null,
      ),
      width: drawerWidth,
      child: Drawer(
        width: drawerWidth,
        backgroundColor: isDesktop ? Colors.white : Theme.of(context).scaffoldBackgroundColor,
        shape: isDesktop
            ? const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              )
            : null,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFE6C785),
                borderRadius: isDesktop
                    ? const BorderRadius.only(
                        topRight: Radius.circular(24),
                      )
                    : null,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    child: Text(
                      (authProvider.currentUser?.fullName ?? 'A').substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFE6C785),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Constants.appName,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          authProvider.currentUser?.fullName ?? 'Admin',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          authProvider.currentUser?.email ?? '',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.black54,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildMenuItem(
                    context,
                    icon: Icons.dashboard,
                    title: 'Dashboard',
                    route: Constants.dashboardRoute,
                    isActive: currentRoute == Constants.dashboardRoute,
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.people,
                    title: 'Users',
                    route: Constants.usersRoute,
                    isActive: currentRoute == Constants.usersRoute,
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.shopping_cart,
                    title: 'Orders',
                    route: Constants.ordersRoute,
                    isActive: currentRoute == Constants.ordersRoute,
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.category,
                    title: 'Categories',
                    route: Constants.categoriesRoute,
                    isActive: currentRoute == Constants.categoriesRoute,
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.inventory,
                    title: 'Products',
                    route: Constants.productsRoute,
                    isActive: currentRoute == Constants.productsRoute,
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.store,
                    title: 'Branches',
                    route: '/branches',
                    isActive: currentRoute == '/branches',
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.photo_library,
                    title: 'Banners',
                    route: '/banners',
                    isActive: currentRoute == '/banners',
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.view_carousel,
                    title: 'Ticker Banners',
                    route: '/tickers',
                    isActive: currentRoute == '/tickers',
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.notifications,
                    title: 'Notifications',
                    route: '/notifications',
                    isActive: currentRoute == '/notifications',
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.settings,
                    title: 'Settings',
                    route: '/settings',
                    isActive: currentRoute == '/settings',
                  ),
                  ListTile(
                    leading: const Icon(Icons.support_agent),
                    title: const Text('Support Messages'),
                    onTap: () {
                      context.go('/support_messages');
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text('Logout'),
                    onTap: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Confirm Logout'),
                          content: const Text('Are you sure you want to log out?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Logout'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        await authProvider.signOut();
                        context.go('/login');
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
    required bool isActive,
  }) {
    final isDesktop = !Constants.isMobile(context) && !Constants.isTablet(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFE6C785).withOpacity(0.55) : null,
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: ListTile(
          leading: Icon(
            icon,
            color: isActive ? Colors.black87 : Colors.grey[700],
          ),
          title: Text(
            title,
            style: TextStyle(
              color: isActive ? Colors.black87 : Colors.grey[900],
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              fontSize: isDesktop ? 16 : 15,
              fontFamily: 'Cairo',
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          tileColor: isActive ? const Color(0xFFE6C785).withOpacity(0.55) : null,
          hoverColor: Theme.of(context).colorScheme.primary.withOpacity(0.12),
          onTap: () {
            if (route == 'send_notification') {
              _showSendNotificationDialog(context);
            } else if (route == 'view_notifications') {
              _showSentNotificationsDialog(context);
            } else {
              context.go(route);
            }
          },
        ),
      ),
    );
  }

  static void _showSendNotificationDialog(BuildContext context) {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Notification'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: bodyController,
              decoration: const InputDecoration(labelText: 'Body'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final supabase = authProvider.supabaseClient;
              try {
                // Fetch all user IDs
                final users = await supabase.from('profiles').select('id');
                final userIds = (users as List).map((u) => u['id'] as String).toList();

                // Insert a notification for each user
                final notifications = userIds.map((userId) => {
                  'user_id': userId,
                  'title': titleController.text,
                  'body': bodyController.text,
                  'is_read': false,
                  'created_at': DateTime.now().toIso8601String(),
                }).toList();

                await supabase.from('notifications').insert(notifications);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notification sent to all users!')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to send notification: \$e')),
                );
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  static void _showSentNotificationsDialog(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final supabase = authProvider.supabaseClient;

    showDialog(
      context: context,
      builder: (context) {
        return FutureBuilder(
          future: supabase
              .from('notifications')
              .select('*')
              .order('created_at', ascending: false),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const AlertDialog(
                title: Text('Sent Notifications'),
                content: Center(child: CircularProgressIndicator()),
              );
            }
            final notifications = snapshot.data as List;
            if (notifications.isEmpty) {
              return const AlertDialog(
                title: Text('Sent Notifications'),
                content: Text('No notifications sent.'),
              );
            }
            return AlertDialog(
              title: const Text('Sent Notifications'),
              content: SizedBox(
                width: 400,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    return ListTile(
                      title: Text(notification['title'] ?? ''),
                      subtitle: Text(notification['body'] ?? ''),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          // Remove notification
                          await supabase
                              .from('notifications')
                              .delete()
                              .eq('id', notification['id']);
                          Navigator.pop(context); // Close dialog
                          _showSentNotificationsDialog(context); // Refresh
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Notification deleted')),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }
} 