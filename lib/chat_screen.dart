import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oshovaani/providers/chat_history_provider.dart';
import 'package:oshovaani/widgets/chat_item.dart';
import 'package:oshovaani/widgets/chat_sidebar.dart';
import 'package:oshovaani/widgets/my_app_bar.dart';
import 'package:oshovaani/widgets/text_and_voice_filed.dart';
import 'package:oshovaani/models/chat_model.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String? initialChatId;

  const ChatScreen({
    super.key,
    this.initialChatId,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  String? _currentChatId;

  @override
  void initState() {
    super.initState();
    _currentChatId = widget.initialChatId;
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    if (_currentChatId == null) {
      final lastSelectedChat =
          await ref.read(chatHistoryProvider.notifier).getLastSelectedChat();
      if (lastSelectedChat != null) {
        setState(() {
          _currentChatId = lastSelectedChat;
        });
      } else {
        // Create a new chat if no chat is selected
        ref.read(chatHistoryProvider.notifier).addChat("New Chat");
        _currentChatId = ref.read(chatHistoryProvider).keys.first;
      }
    }
  }

  void _handleChatSelection(String chatId) {
    setState(() {
      _currentChatId = chatId;
    });
    ref.read(chatHistoryProvider.notifier).setLastSelectedChat(chatId);
    Navigator.pop(context); // Close the drawer
  }

  @override
  Widget build(BuildContext context) {
    final chatHistory = ref.watch(chatHistoryProvider);
    final currentMessages =
        _currentChatId != null ? chatHistory[_currentChatId] ?? [] : [];

    return Scaffold(
      appBar: const MyAppBar(),
      drawer: ChatSidebar(
        currentChatId: _currentChatId,
        onSelectChat: _handleChatSelection,
      ),
      body: Column(
        children: [
          Expanded(
            child: currentMessages.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "👋 Hey there, Explorer!",
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Colors.black87,
                              shadows: [
                                Shadow(
                                  blurRadius: 10,
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.blueAccent.withOpacity(0.6)
                                      : Colors.blueGrey.withOpacity(0.5),
                                  offset: const Offset(2, 3),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "💡 What's on your mind? Ask me anything!",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.8,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.grey[300]
                                  : Colors.grey[700],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.blueAccent.withOpacity(0.6)
                                      : Colors.blueGrey.withOpacity(0.5),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.chat_bubble_rounded,
                              size: 50,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.blueAccent
                                  : Colors.blueGrey,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            width: 80,
                            height: 4,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.blueAccent
                                      : Colors.blueGrey,
                                  Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.cyanAccent
                                      : Colors.lightBlueAccent,
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: currentMessages.length,
                    itemBuilder: (context, index) => ChatItem(
                      text: currentMessages[index].message,
                      isMe: currentMessages[index].isMe,
                      message: currentMessages[index],
                    ),
                  ),
          ),
          if (_currentChatId != null)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextAndVoiceField(
                chatId: _currentChatId!,
                onMessageSent: (message) {
                  // This callback is no longer needed as messages are handled in TextAndVoiceField
                },
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
