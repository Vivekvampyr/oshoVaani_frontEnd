import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatSidebar extends StatefulWidget {
  final List<String> chatHistory;
  final VoidCallback onNewChat;
  final Function(String) onSelectChat;
  final Function(String) onDeleteChat; // Added delete function

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
  String? _profileImagePath;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // 🟢 Load User Data from SharedPreferences
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? "Guest";
      _profileImagePath = prefs.getString('userProfile');
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;

    return Drawer(
      child: Column(
        children: [
          // 🟢 User Profile Section
          Container(
            height: 160,
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
                CircleAvatar(
                  radius: 36,
                  backgroundImage:
                      _profileImagePath != null && _profileImagePath!.isNotEmpty
                          ? FileImage(File(_profileImagePath!))
                          : const AssetImage('assets/default_avatar.png')
                              as ImageProvider,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _userName,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: colors.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 🔹 Chat History Label
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              "Conversations",
              style: theme.textTheme.titleMedium?.copyWith(
                color: isDarkMode
                    ? colors.onPrimary.withOpacity(0.7)
                    : Colors.black54,
              ),
            ),
          ),

          const SizedBox(height: 10),

          // 🟡 Chat History List
          Expanded(
            child: widget.chatHistory.isEmpty
                ? Center(
                    child: Text(
                      "No conversations yet",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onPrimary.withOpacity(0.6),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    itemCount: widget.chatHistory.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading:
                            Icon(Icons.chat_rounded, color: colors.secondary),
                        title: Text(
                          widget.chatHistory[index],
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colors.onPrimary,
                          ),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        onTap: () =>
                            widget.onSelectChat(widget.chatHistory[index]),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () =>
                              widget.onDeleteChat(widget.chatHistory[index]),
                        ),
                      );
                    },
                  ),
          ),

          const Divider(),

          // 🟠 Modern "New Chat" Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: widget.onNewChat,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
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
                      color: colors.onSecondary,
                    ),
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
