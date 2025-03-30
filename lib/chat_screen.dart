import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oshovaani/providers/chat_history_provider.dart';
import 'package:oshovaani/providers/chats_provider.dart';
import 'package:oshovaani/widgets/chat_item.dart';
import 'package:oshovaani/widgets/chat_sidebar.dart';
import 'package:oshovaani/widgets/my_app_bar.dart';
import 'package:oshovaani/widgets/text_and_voice_filed.dart';

class ChatScreen extends ConsumerWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatHistory = ref.watch(chatHistoryProvider);
    final chats = ref.watch(chatsProvider).reversed.toList();

    return Scaffold(
      appBar: const MyAppBar(),
      drawer: ChatSidebar(
        chatHistory: chatHistory,
        onNewChat: () {
          ref.read(chatHistoryProvider.notifier).addChat("New Chat");
        },
        onDeleteChat: (chat) {
          ref.read(chatHistoryProvider.notifier).deleteChat(chat);
        },
        onSelectChat: (chat) {
          print('Selected chat: $chat'); // Replace this with navigation logic
        },
      ),
      body: Column(
        children: [
          Expanded(
            child: chats.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Animated Wave Emoji for friendliness
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
                                  offset: Offset(2, 3),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),

                          SizedBox(height: 10),

                          // Subtext with glowing effect
                          Text(
                            "💡 What’s on your mind?",
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

                          SizedBox(height: 20),

                          // Floating Chat Bubble Animation
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.blueAccent.withValues(alpha: .7)
                                      : Colors.blueGrey.withValues(alpha: .7),
                                  blurRadius: 25,
                                  spreadRadius: 2,
                                  offset: Offset(0, 5),
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

                          SizedBox(height: 20),

                          // Subtle Gradient Divider for Elegance
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
                    reverse: true,
                    itemCount: chats.length,
                    itemBuilder: (context, index) => ChatItem(
                      text: chats[index].message,
                      isMe: chats[index].isMe,
                    ),
                  ),
          ),
          const Padding(
            padding: EdgeInsets.all(12.0),
            child: TextAndVoiceField(),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
