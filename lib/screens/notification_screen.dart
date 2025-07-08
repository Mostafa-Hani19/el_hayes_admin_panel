import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/sidebar_menu.dart';
import '../utils/constants.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _isSending = false;

  Future<void> _sendNotification() async {
    setState(() => _isSending = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final supabase = authProvider.supabaseClient;
    try {
      final users = await supabase.from('profiles').select('id');
      final userIds = (users as List).map((u) => u['id'] as String).toList();
      final notifications = userIds.map((userId) => {
        'user_id': userId,
        'title': _titleController.text,
        'body': _bodyController.text,
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      }).toList();
      await supabase.from('notifications').insert(notifications);
      _titleController.clear();
      _bodyController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification sent to all users!')),
      );
      setState(() {}); // Refresh list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send notification: $e')),
      );
    }
    setState(() => _isSending = false);
  }

  Future<List<dynamic>> _fetchNotifications() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final supabase = authProvider.supabaseClient;
    // Fetch only one notification per unique (title, body, created_at)
    final notifications = await supabase
        .from('notifications')
        .select('id, title, body, created_at')
        .order('created_at', ascending: false);
    // Remove duplicates
    final unique = <String, Map<String, dynamic>>{};
    for (final n in notifications as List) {
      final key = '${n['title']}_${n['body']}_${n['created_at']}';
      unique[key] = n;
    }
    return unique.values.toList();
  }

  Future<void> _deleteNotification(Map<String, dynamic> notification) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final supabase = authProvider.supabaseClient;
    await supabase
        .from('notifications')
        .delete()
        .eq('title', notification['title'])
        .eq('body', notification['body'])
        .eq('created_at', notification['created_at']);
    setState(() {}); // Refresh list
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notification deleted')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Constants.isMobile(context);
    // ignore: unused_local_variable
    final isTablet = Constants.isTablet(context);
    final maxContentWidth = 700.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications'), automaticallyImplyLeading: false),
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
                      maxWidth: isMobile ? double.infinity : maxContentWidth,
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(isMobile ? 8.0 : 16.0),
                      child: Column(
                        children: [
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  TextField(
                                    controller: _titleController,
                                    decoration: const InputDecoration(labelText: 'Title'),
                                  ),
                                  SizedBox(height: isMobile ? 8 : 16),
                                  TextField(
                                    controller: _bodyController,
                                    decoration: const InputDecoration(labelText: 'Body'),
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton(
                                    onPressed: _isSending ? null : _sendNotification,
                                    child: _isSending
                                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                        : const Text('Send Notification'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: FutureBuilder<List<dynamic>>(
                              future: _fetchNotifications(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return const Center(child: CircularProgressIndicator());
                                }
                                final notifications = snapshot.data!;
                                if (notifications.isEmpty) {
                                  return const Center(child: Text('No notifications sent.'));
                                }
                                return ListView.builder(
                                  itemCount: notifications.length,
                                  itemBuilder: (context, index) {
                                    final notification = notifications[index];
                                    return Card(
                                      child: ListTile(
                                        title: Text(notification['title'] ?? ''),
                                        subtitle: Text(notification['body'] ?? ''),
                                        trailing: IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () => _deleteNotification(notification),
                                        ),
                                      ),
                                    );
                                  },
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
          );
        },
      ),
    );
  }
} 