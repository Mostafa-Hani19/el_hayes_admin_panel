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
      appBar: AppBar(
        title: const Text('Support Messages'),
        automaticallyImplyLeading: false,
        
      ),
      drawer: isMobile ? const SidebarMenu() : null,
      body: Row(
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
                      : ListView.builder(
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final message = _messages[index];
                            return Card(
                              margin: EdgeInsets.symmetric(
                                horizontal: isMobile ? 8 : 16,
                                vertical: isMobile ? 4 : 8,
                              ),
                              child: ListTile(
                                title: Text(message['subject'] ?? ''),
                                subtitle: Text(message['body'] ?? ''),
                                trailing: Text(message['created_at'] ?? ''),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
