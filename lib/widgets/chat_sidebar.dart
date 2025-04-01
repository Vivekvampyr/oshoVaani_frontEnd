import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oshovaani/chat_screen.dart';
import 'package:oshovaani/providers/chat_history_provider.dart';
import 'package:oshovaani/screens/liked_messages_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class ChatSidebar extends ConsumerStatefulWidget {
  final String? currentChatId;
  final Function(String) onSelectChat;

  const ChatSidebar({
    super.key,
    required this.currentChatId,
    required this.onSelectChat,
  });

  @override
  ConsumerState<ChatSidebar> createState() => _ChatSidebarState();
}

class _ChatSidebarState extends ConsumerState<ChatSidebar> {
  String _userName = "Guest";
  String _userEmail = "No Email Set";
  String? _profileImagePath;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? "Guest";
      _userEmail = prefs.getString('userEmail') ?? "No Email Set";
      _profileImagePath = prefs.getString('userProfile');
    });
  }

  void _showRenameDialog(String chatId, String currentTitle) {
    final TextEditingController controller =
        TextEditingController(text: currentTitle);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Chat'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter new chat name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                ref
                    .read(chatHistoryProvider.notifier)
                    .renameChat(chatId, controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(String chatId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Chat'),
        content: const Text('Are you sure you want to delete this chat?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(chatHistoryProvider.notifier).deleteChat(chatId);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _getLastMessageTime(List<dynamic> messages) {
    if (messages.isEmpty) return '';
    final lastMessage = messages.last;

    try {
      // Try to parse the ID as a timestamp
      final timestamp =
          DateTime.fromMillisecondsSinceEpoch(int.parse(lastMessage.id));
      final now = DateTime.now();
      final difference = now.difference(timestamp);

      if (difference.inDays > 0) {
        return DateFormat('MMM d').format(timestamp);
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      // If parsing fails, return "Just now"
      return 'Just now';
    }
  }

  String _getMessagePreview(List<dynamic> messages) {
    if (messages.isEmpty) return 'No messages yet';
    final lastMessage = messages.last;
    return lastMessage.message.length > 50
        ? '${lastMessage.message.substring(0, 50)}...'
        : lastMessage.message;
  }

  List<MapEntry<String, List<dynamic>>> _getFilteredChats(
      Map<String, List<dynamic>> chatHistory) {
    if (_searchQuery.isEmpty) return chatHistory.entries.toList();
    return chatHistory.entries.where((entry) {
      final title =
          entry.value.isNotEmpty ? entry.value.first.title : "New Chat";
      final lastMessage =
          entry.value.isNotEmpty ? entry.value.last.message.toLowerCase() : '';
      return title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          lastMessage.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final chatHistory = ref.watch(chatHistoryProvider);
    final filteredChats = _getFilteredChats(chatHistory);

    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: colors.secondary,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.secondary.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundImage: _profileImagePath != null &&
                                _profileImagePath!.isNotEmpty
                            ? FileImage(File(_profileImagePath!))
                            : const AssetImage('assets/images/user.jpeg')
                                as ImageProvider,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: colors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colors.secondary,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.edit,
                            size: 14,
                            color: colors.onPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _userName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colors.onPrimary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _userEmail,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.onPrimary.withOpacity(0.8),
                            letterSpacing: 0.1,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colors.outline.withOpacity(0.2),
                ),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search conversations...',
                  prefixIcon: Icon(
                    Icons.search,
                    color: colors.onSurface.withOpacity(0.6),
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: colors.onSurface.withOpacity(0.6),
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Conversations",
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.onPrimary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colors.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "${filteredChats.length} chats",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.secondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: filteredChats.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 48,
                          color: colors.onSurface.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No conversations yet'
                              : 'No conversations found',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colors.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: filteredChats.length,
                    itemBuilder: (context, index) {
                      final chatId = filteredChats[index].key;
                      final messages = filteredChats[index].value;
                      final title = ref
                          .read(chatHistoryProvider.notifier)
                          .getChatTitle(chatId);
                      final isSelected = chatId == widget.currentChatId;
                      final lastMessageTime = _getLastMessageTime(messages);
                      final messagePreview = _getMessagePreview(messages);

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 1),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colors.secondary.withOpacity(0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: isSelected
                              ? Border.all(color: colors.secondary, width: 1.5)
                              : null,
                        ),
                        child: ListTile(
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 2,
                          ),
                          leading: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: colors.secondary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.chat_rounded,
                              color: colors.secondary,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colors.onPrimary,
                              fontWeight: isSelected ? FontWeight.bold : null,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 1),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  messagePreview,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colors.onPrimary.withOpacity(0.6),
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  lastMessageTime,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colors.onPrimary.withOpacity(0.4),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          trailing: PopupMenuButton<String>(
                            icon: Icon(
                              Icons.more_vert,
                              color: colors.onPrimary.withOpacity(0.6),
                              size: 20,
                            ),
                            onSelected: (value) {
                              if (value == 'rename') {
                                _showRenameDialog(chatId, title);
                              } else if (value == 'delete') {
                                _showDeleteConfirmation(chatId);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'rename',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit),
                                    SizedBox(width: 8),
                                    Text('Rename'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Delete',
                                        style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          onTap: () => widget.onSelectChat(chatId),
                        ),
                      );
                    },
                  ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      ref
                          .read(chatHistoryProvider.notifier)
                          .addChat("New Chat");
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      backgroundColor: colors.secondary,
                      elevation: 4,
                      shadowColor: colors.secondary.withOpacity(0.3),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, color: colors.onSecondary),
                        const SizedBox(width: 8),
                        Text(
                          "Start New Chat",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colors.onSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LikedMessagesScreen(),
                      ),
                    );
                  },
                  style: IconButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: colors.secondary,
                    elevation: 4,
                    shadowColor: colors.secondary.withOpacity(0.3),
                  ),
                  icon: Icon(
                    Icons.favorite,
                    color: colors.onSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
