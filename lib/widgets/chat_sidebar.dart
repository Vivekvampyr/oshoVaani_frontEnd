import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oshovaani/providers/chat_history_provider.dart';
import 'package:oshovaani/screens/liked_messages_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:oshovaani/services/ai_handler.dart';
import 'package:oshovaani/home_screen.dart';
import 'package:oshovaani/screens/edit_profile_screen.dart';

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
  final AIHandler _aiHandler = AIHandler();

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
      // Get the timestamp from the message
      final timestamp =
          DateTime.fromMillisecondsSinceEpoch(int.parse(lastMessage.id));
      final now = DateTime.now();
      final difference = now.difference(timestamp);

      // For messages less than a minute old, show "Just now"
      if (difference.inMinutes < 1) {
        return 'Just now';
      }
      // For messages less than an hour old, show minutes ago
      else if (difference.inHours < 1) {
        return '${difference.inMinutes}m ago';
      }
      // For messages less than a day old, show hours ago
      else if (difference.inDays < 1) {
        return '${difference.inHours}h ago';
      }
      // For messages older than a day, show the date
      else {
        return DateFormat('MMM d').format(timestamp);
      }
    } catch (e) {
      print('Error parsing message time: $e');
      return 'Just now';
    }
  }

  String _getChatCreationTime(String chatId) {
    try {
      final timestamp = DateTime.fromMillisecondsSinceEpoch(int.parse(chatId));
      final now = DateTime.now();
      final difference = now.difference(timestamp);

      if (difference.inDays > 1) {
        return DateFormat('MMM d, y').format(timestamp);
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else {
        return DateFormat('h:mm a').format(timestamp);
      }
    } catch (e) {
      // If parsing fails, return current time
      return DateFormat('h:mm a').format(DateTime.now());
    }
  }

  Map<String, List<MapEntry<String, List<dynamic>>>> _organizeChatsByDate(
      List<MapEntry<String, List<dynamic>>> chats) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final Map<String, List<MapEntry<String, List<dynamic>>>> organizedChats = {
      'Today': [],
      'Yesterday': [],
      'Other': [],
    };

    for (var chat in chats) {
      try {
        final timestamp =
            DateTime.fromMillisecondsSinceEpoch(int.parse(chat.key));
        final chatDate =
            DateTime(timestamp.year, timestamp.month, timestamp.day);

        if (chatDate.isAtSameMomentAs(today)) {
          organizedChats['Today']!.add(chat);
        } else if (chatDate.isAtSameMomentAs(yesterday)) {
          organizedChats['Yesterday']!.add(chat);
        } else {
          organizedChats['Other']!.add(chat);
        }
      } catch (e) {
        organizedChats['Other']!.add(chat);
      }
    }

    return organizedChats;
  }

  Widget _buildChatSection(
      String title, List<MapEntry<String, List<dynamic>>> chats) {
    if (chats.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        ...chats.map((chat) => _buildChatTile(chat)).toList(),
      ],
    );
  }

  Widget _buildChatTile(MapEntry<String, List<dynamic>> chat) {
    final chatId = chat.key;
    final messages = chat.value;
    final title = ref.read(chatHistoryProvider.notifier).getChatTitle(chatId);
    final isSelected = chatId == widget.currentChatId;
    final lastMessageTime = _getLastMessageTime(messages);
    final messagePreview = _getMessagePreview(messages);
    final creationTime = _getChatCreationTime(chatId);
    final colors = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 1),
      decoration: BoxDecoration(
        color:
            isSelected ? colors.secondary.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border:
            isSelected ? Border.all(color: colors.secondary, width: 1.5) : null,
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
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colors.onPrimary,
                      fontWeight: isSelected ? FontWeight.bold : null,
                      fontSize: 14,
                    ),
              ),
            ),
            Text(
              creationTime,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onPrimary.withOpacity(0.4),
                    fontSize: 11,
                  ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                messagePreview,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onPrimary.withOpacity(0.6),
                      fontSize: 12,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                lastMessageTime,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: () => widget.onSelectChat(chatId),
      ),
    );
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
      final chatId = entry.key;
      final title = ref.read(chatHistoryProvider.notifier).getChatTitle(chatId);
      final lastMessage =
          entry.value.isNotEmpty ? entry.value.last.message.toLowerCase() : '';
      return title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          lastMessage.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  Future<void> _handleLogout() async {
    await _aiHandler.logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final chatHistory = ref.watch(chatHistoryProvider);
    final filteredChats = _getFilteredChats(chatHistory);
    final organizedChats = _organizeChatsByDate(filteredChats);

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
              child: Column(
                children: [
                  Row(
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
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _userName,
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      color: colors.onPrimary,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.2,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.more_vert,
                                    color: colors.onPrimary,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    showModalBottomSheet(
                                      context: context,
                                      backgroundColor: Colors.transparent,
                                      builder: (context) => Container(
                                        decoration: BoxDecoration(
                                          color: colors.surface,
                                          borderRadius:
                                              const BorderRadius.vertical(
                                            top: Radius.circular(20),
                                          ),
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            ListTile(
                                              leading: Icon(
                                                Icons.edit,
                                                color: colors.primary,
                                              ),
                                              title: Text(
                                                'Edit Profile',
                                                style: TextStyle(
                                                  color: colors.primary,
                                                ),
                                              ),
                                              onTap: () {
                                                Navigator.pop(context);
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        const EditProfileScreen(),
                                                  ),
                                                ).then((_) => _loadUserData());
                                              },
                                            ),
                                            ListTile(
                                              leading: const Icon(Icons.logout,
                                                  color: Colors.red),
                                              title: const Text(
                                                'Logout',
                                                style: TextStyle(
                                                    color: Colors.red),
                                              ),
                                              onTap: () {
                                                Navigator.pop(context);
                                                _handleLogout();
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
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
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildChatSection('Today', organizedChats['Today']!),
                        _buildChatSection(
                            'Yesterday', organizedChats['Yesterday']!),
                        _buildChatSection('Other', organizedChats['Other']!),
                      ],
                    ),
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
                      final now = DateTime.now();
                      final formattedDateTime =
                          DateFormat('MMM d, y h:mm a').format(now);
                      ref
                          .read(chatHistoryProvider.notifier)
                          .addChat("New Chat - $formattedDateTime");
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
