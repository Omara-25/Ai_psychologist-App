import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ai_psychologist/providers/chat_provider.dart';
import 'package:ai_psychologist/widgets/app_drawer.dart';
import 'package:ai_psychologist/screens/chat_screen.dart';
import 'package:ai_psychologist/utils/page_transitions.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ChatSession {
  final String id;
  final DateTime createdAt;
  final String title;
  final bool isArchived;

  ChatSession({
    required this.id,
    required this.createdAt,
    required this.title,
    this.isArchived = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'title': title,
      'isArchived': isArchived,
    };
  }

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
      title: json['title'],
      isArchived: json['isArchived'] ?? false,
    );
  }
}

class ChatHistoryScreen extends StatefulWidget {
  const ChatHistoryScreen({super.key});

  @override
  State<ChatHistoryScreen> createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends State<ChatHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ChatSession> _activeSessions = [];
  List<ChatSession> _archivedSessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadChatSessions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadChatSessions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionsJson = prefs.getString('chat_sessions');

      if (sessionsJson != null) {
        final List<dynamic> decoded = jsonDecode(sessionsJson);
        final List<ChatSession> allSessions = decoded
            .map((item) => ChatSession.fromJson(item))
            .toList();

        setState(() {
          _activeSessions = allSessions.where((s) => !s.isArchived).toList();
          _archivedSessions = allSessions.where((s) => s.isArchived).toList();

          // Sort by most recent first
          _activeSessions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          _archivedSessions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        });
      } else {
        // Create a default session if none exists
        final defaultSession = ChatSession(
          id: 'default',
          createdAt: DateTime.now(),
          title: 'My First Conversation',
        );

        setState(() {
          _activeSessions = [defaultSession];
          _archivedSessions = [];
        });

        await _saveChatSessions();
      }
    } catch (e) {
      debugPrint('Error loading chat sessions: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveChatSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allSessions = [..._activeSessions, ..._archivedSessions];
      final encoded = jsonEncode(allSessions.map((s) => s.toJson()).toList());
      await prefs.setString('chat_sessions', encoded);
    } catch (e) {
      debugPrint('Error saving chat sessions: $e');
    }
  }

  Future<void> _createNewChat() async {
    final newSession = ChatSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      createdAt: DateTime.now(),
      title: 'New Conversation',
    );

    setState(() {
      _activeSessions.insert(0, newSession);
    });

    await _saveChatSessions();

    if (!mounted) return;

    // Set this as the active session and navigate to chat
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.clearChat(); // Start with a fresh chat

    Navigator.of(context).push(
      CustomPageTransition(
        child: const ChatScreen(),
        type: PageTransitionType.rightToLeft,
      ),
    );
  }

  Future<void> _archiveSession(ChatSession session) async {
    setState(() {
      _activeSessions.remove(session);
      _archivedSessions.insert(0, ChatSession(
        id: session.id,
        createdAt: session.createdAt,
        title: session.title,
        isArchived: true,
      ));
    });

    await _saveChatSessions();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Chat archived'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => _unarchiveSession(session),
        ),
      ),
    );
  }

  Future<void> _unarchiveSession(ChatSession session) async {
    final archivedSession = _archivedSessions.firstWhere((s) => s.id == session.id);

    setState(() {
      _archivedSessions.remove(archivedSession);
      _activeSessions.insert(0, ChatSession(
        id: session.id,
        createdAt: session.createdAt,
        title: session.title,
        isArchived: false,
      ));
    });

    await _saveChatSessions();
  }

  Future<void> _deleteSession(ChatSession session, bool isArchived) async {
    setState(() {
      if (isArchived) {
        _archivedSessions.removeWhere((s) => s.id == session.id);
      } else {
        _activeSessions.removeWhere((s) => s.id == session.id);
      }
    });

    await _saveChatSessions();
  }

  Future<void> _editSessionTitle(ChatSession session, bool isArchived) async {
    final TextEditingController controller = TextEditingController(text: session.title);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Chat Title'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Title',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final newTitle = controller.text.trim();
              if (newTitle.isNotEmpty) {
                final navigator = Navigator.of(context);
                if (isArchived) {
                  final index = _archivedSessions.indexWhere((s) => s.id == session.id);
                  if (index != -1) {
                    setState(() {
                      _archivedSessions[index] = ChatSession(
                        id: session.id,
                        createdAt: session.createdAt,
                        title: newTitle,
                        isArchived: true,
                      );
                    });
                  }
                } else {
                  final index = _activeSessions.indexWhere((s) => s.id == session.id);
                  if (index != -1) {
                    setState(() {
                      _activeSessions[index] = ChatSession(
                        id: session.id,
                        createdAt: session.createdAt,
                        title: newTitle,
                        isArchived: false,
                      );
                    });
                  }
                }
                await _saveChatSessions();
                if (mounted) navigator.pop();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // First try to pop the current screen
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              // If can't pop, navigate to chat screen using named route
              Navigator.of(context).pushReplacementNamed('/chat');
            }
          },
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Archived'),
          ],
        ),
      ),
      drawer: const AppDrawer(currentRoute: '/chat_history'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildSessionsList(_activeSessions, false),
                _buildSessionsList(_archivedSessions, true),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewChat,
        icon: const Icon(Icons.add),
        label: const Text('New Chat'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildSessionsList(List<ChatSession> sessions, bool isArchived) {
    if (sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isArchived ? Icons.archive : Icons.chat_bubble_outline,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              isArchived
                  ? 'No archived chats'
                  : 'No active chats',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: sessions.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final session = sessions[index];
        return _buildSessionCard(session, isArchived);
      },
    );
  }

  Widget _buildSessionCard(ChatSession session, bool isArchived) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // TODO: Load this specific chat session
          Navigator.of(context).push(
            CustomPageTransition(
              child: const ChatScreen(),
              type: PageTransitionType.rightToLeft,
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      session.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton(
                    icon: const Icon(Icons.more_vert),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: ListTile(
                          leading: const Icon(Icons.edit),
                          title: const Text('Edit Title'),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          onTap: () {
                            Navigator.pop(context);
                            _editSessionTitle(session, isArchived);
                          },
                        ),
                      ),
                      PopupMenuItem(
                        child: ListTile(
                          leading: Icon(isArchived ? Icons.unarchive : Icons.archive),
                          title: Text(isArchived ? 'Unarchive' : 'Archive'),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          onTap: () {
                            Navigator.pop(context);
                            isArchived
                                ? _unarchiveSession(session)
                                : _archiveSession(session);
                          },
                        ),
                      ),
                      PopupMenuItem(
                        child: ListTile(
                          leading: const Icon(Icons.delete, color: Colors.red),
                          title: const Text('Delete', style: TextStyle(color: Colors.red)),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          onTap: () {
                            Navigator.pop(context);
                            _deleteSession(session, isArchived);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                dateFormat.format(session.createdAt),
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withAlpha(153), // 0.6 * 255 = 153
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
