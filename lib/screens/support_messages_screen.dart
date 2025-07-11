// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/constants.dart';
import '../widgets/sidebar_menu.dart';

class SupportMessagesScreen extends StatefulWidget {
  const SupportMessagesScreen({super.key});

  @override
  State<SupportMessagesScreen> createState() => _SupportMessagesScreenState();
}

class _SupportMessagesScreenState extends State<SupportMessagesScreen> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMessages();
  }

  Future<void> _fetchMessages() async {
    setState(() => _isLoading = true);
    final response = await supabase
        .from('support_messages')
        .select('*')
        .order('created_at', ascending: false);
    setState(() {
      _messages = List<Map<String, dynamic>>.from(response);
      _isLoading = false;
    });
  }

  // ignore: unused_element
  Future<void> _respondToMessage(String messageId, String reply) async {
    await supabase.from('support_messages').update({
      'response_text': reply,
      'status': 'responded',
      'responded_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', messageId);
    _fetchMessages();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Constants.isMobile(context);
    final isTablet = Constants.isTablet(context);
    final isDesktop = Constants.isDesktop(context);
    final maxContentWidth = isDesktop ? 1100.0 : isTablet ? 800.0 : double.infinity;
    final horizontalPadding = isMobile ? 4.0 : isTablet ? 16.0 : 32.0;
    final verticalPadding = isMobile ? 4.0 : isTablet ? 8.0 : 24.0;
    return Scaffold(
      extendBodyBehindAppBar: false,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Support Messages'),
        centerTitle: true,
        automaticallyImplyLeading: false,
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
        child: Row(
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
                        : Column(
                            children: [
                              const SizedBox(height: 24),
                              Divider(height: isMobile ? 18 : 32, thickness: 1.2, color: Colors.blueGrey[100]),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: _messages.length,
                                  itemBuilder: (context, index) {
                                    final message = _messages[index];
                                    return _ModernSupportMessageCard(
                                      message: message,
                                      isMobile: isMobile,
                                      onRespond: _respondToMessage,
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

class _ModernSupportMessageCard extends StatefulWidget {
  final Map<String, dynamic> message;
  final bool isMobile;
  final Function(String, String) onRespond;
  const _ModernSupportMessageCard({required this.message, required this.isMobile, required this.onRespond});

  @override
  State<_ModernSupportMessageCard> createState() => _ModernSupportMessageCardState();
}

class _ModernSupportMessageCardState extends State<_ModernSupportMessageCard> {
  bool _hovering = false;
  final TextEditingController _responseController = TextEditingController();

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.message;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        margin: EdgeInsets.symmetric(horizontal: widget.isMobile ? 8 : 16, vertical: widget.isMobile ? 4 : 8),
        decoration: BoxDecoration(
          color: _hovering ? const Color(0xFFE6C785) : const Color(0xFFFFF8E1),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: _hovering ? const Color(0xFFE6C785).withOpacity(0.22) : const Color(0xFFE6C785).withOpacity(0.10),
              blurRadius: _hovering ? 14 : 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: _hovering ? const Color(0xFFE6C785).withOpacity(0.28) : Colors.transparent,
            width: 1.1,
          ),
        ),
        child: Column(
          children: [
            ListTile(
              title: Text(
                m['subject'] ?? '',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Message: ' + (m['message'] ?? ''), style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 4),
                  if (m['response_text'] != null && m['response_text'].isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(),
                        Text('Response:', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(m['response_text'], style: const TextStyle(fontSize: 14, color: Colors.blueGrey)),
                      ],
                    ),
                  const SizedBox(height: 4),
                  Text('Type: ' + (m['type'] ?? ''), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  Text('Status: ' + (m['status'] ?? ''), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              trailing: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(m['created_at'] ?? ''),
                  if (m['responded_at'] != null) Text('Responded: ' + m['responded_at'], style: const TextStyle(fontSize: 12, color: Colors.green)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  TextField(
                    controller: _responseController,
                    decoration: const InputDecoration(
                      labelText: 'Your Response',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      final reply = _responseController.text;
                      if (reply.isNotEmpty) {
                        widget.onRespond(m['id'], reply);
                      }
                    },
                    child: const Text('Send Response'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
