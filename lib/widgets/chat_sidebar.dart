import 'dart:io';
import 'package:flutter/material.dart';
import 'package:oshovaani/chat_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatSidebar extends StatefulWidget {
  final List<String> chatHistory;
  final VoidCallback onNewChat;
  final Function(String) onSelectChat;
  final Function(String) onDeleteChat;

  const ChatSidebar({
    super.key,
    required this.chatHistory,
    required this.onNewChat,
    required this.onSelectChat,
    required this.onDeleteChat,
  });

  @override
  _ChatSidebarState createState() => _ChatSidebarState();
}

class _ChatSidebarState extends State<ChatSidebar> {
  String _userName = "Guest";
  String _userEmail = "No Email Set";
  String? _profileImagePath;
  List<String> _chatHistory = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Load User Data (Username, Email, Profile Picture)
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? "Guest";
      _userEmail = prefs.getString('userEmail') ?? "No Email Set";
      _profileImagePath = prefs.getString('userProfile');
      _chatHistory = prefs.getStringList('chatHistory') ?? [];
    });
  }

  // Save Chat History
  Future<void> _saveChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('chatHistory', _chatHistory);
  }

  // Start a New Chat
  void _startNewChat() {
    String newChatTitle = "New Chat";
    String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    setState(() {
      _chatHistory.insert(0, "$newChatTitle|$timestamp");
      _saveChatHistory();
    });
  }

  // Delete a Chat
  void _deleteChat(String chatTitle) {
    setState(() {
      _chatHistory.remove(chatTitle);
      _saveChatHistory();
      widget.onDeleteChat(chatTitle);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Drawer(
      child: Column(
        children: [
          // 🚀 Updated Profile Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.secondary,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                // 📷 Profile Picture
                CircleAvatar(
                  radius: 36,
                  backgroundImage:
                      _profileImagePath != null && _profileImagePath!.isNotEmpty
                          ? FileImage(File(_profileImagePath!))
                          : const AssetImage('assets/images/user.jpeg')
                              as ImageProvider,
                ),
                const SizedBox(width: 12),

                // 📝 Username & Email Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🏷 Username
                      Text(
                        _userName,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: colors.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),

                      // 📧 Email
                      Text(
                        _userEmail,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onPrimary.withOpacity(0.8),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              "Conversations",
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),

          Expanded(
            child: ListView.builder(
              itemCount: _chatHistory.length,
              itemBuilder: (context, index) {
                String chatTitle = _chatHistory[index].split('|').first;
                return Dismissible(
                  key: Key(chatTitle),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (direction) {
                    _deleteChat(chatTitle);
                  },
                  child: ListTile(
                    leading: Icon(Icons.chat_rounded, color: colors.secondary),
                    title: Text(
                      chatTitle,
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(color: colors.onPrimary),
                    ),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ChatScreen()),
                    ),
                  ),
                );
              },
            ),
          ),

          const Divider(),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _startNewChat,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
                backgroundColor: colors.secondary,
                elevation: 4,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    "Start New Chat",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colors.onSecondary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
