// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/sidebar_menu.dart';
import '../utils/constants.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

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
      final notifications = userIds
          .map(
            (userId) => {
              'user_id': userId,
              'title': _titleController.text,
              'body': _bodyController.text,
              'is_read': false,
              'created_at': DateTime.now().toIso8601String(),
            },
          )
          .toList();
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Notification deleted')));
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Constants.isMobile(context);
    // ignore: unused_local_variable
    final isTablet = Constants.isTablet(context);
    final maxContentWidth = 700.0;

    return Scaffold(
      extendBodyBehindAppBar: false,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Notifications'),
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
            colors: [Colors.grey[100]!, Colors.blueGrey[50]!],
          ),
        ),
        child: LayoutBuilder(
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
                            const SizedBox(height: 24),
                            Divider(height: isMobile ? 18 : 32, thickness: 1.2, color: Colors.blueGrey[100]),
                            _ModernNotificationForm(
                              titleController: _titleController,
                              bodyController: _bodyController,
                              isSending: _isSending,
                              onSend: _sendNotification,
                              isMobile: isMobile,
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: FutureBuilder<List<dynamic>>(
                                future: _fetchNotifications(),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) {
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }
                                  final notifications = snapshot.data!;
                                  if (notifications.isEmpty) {
                                    return const Center(
                                      child: Text('No notifications sent.'),
                                    );
                                  }
                                  return ListView.builder(
                                    itemCount: notifications.length,
                                    itemBuilder: (context, index) {
                                      final notification = notifications[index];
                                      return _ModernNotificationCard(
                                        notification: notification,
                                        onDelete: () => _deleteNotification(notification),
                                        isMobile: isMobile,
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
      ),
    );
  }
}

class _ModernNotificationForm extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController bodyController;
  final bool isSending;
  final VoidCallback onSend;
  final bool isMobile;
  const _ModernNotificationForm({required this.titleController, required this.bodyController, required this.isSending, required this.onSend, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.93),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        margin: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 16, vertical: isMobile ? 4 : 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                prefixIcon: Icon(Icons.title),
              ),
            ),
            SizedBox(height: isMobile ? 8 : 16),
            TextField(
              controller: bodyController,
              decoration: const InputDecoration(
                labelText: 'Body',
                prefixIcon: Icon(Icons.message),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: isSending ? null : onSend,
                child: isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Send Notification'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModernNotificationCard extends StatefulWidget {
  final Map<String, dynamic> notification;
  final VoidCallback onDelete;
  final bool isMobile;
  const _ModernNotificationCard({required this.notification, required this.onDelete, required this.isMobile});

  @override
  State<_ModernNotificationCard> createState() => _ModernNotificationCardState();
}

class _ModernNotificationCardState extends State<_ModernNotificationCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final n = widget.notification;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        margin: EdgeInsets.symmetric(horizontal: widget.isMobile ? 8 : 16, vertical: widget.isMobile ? 4 : 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(_hovering ? 0.98 : 0.93),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: _hovering ? Colors.blue.withOpacity(0.13) : Colors.grey.withOpacity(0.08),
              blurRadius: _hovering ? 14 : 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: _hovering ? Colors.blue.withOpacity(0.18) : Colors.transparent,
            width: 1.1,
          ),
        ),
        child: ListTile(
          title: Text(
            n['title'] ?? '',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(n['body'] ?? ''),
          trailing: IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: widget.onDelete,
          ),
        ),
      ),
    );
  }
}
