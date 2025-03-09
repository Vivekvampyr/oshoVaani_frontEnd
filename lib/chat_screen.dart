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
                      child: Text(
                        "Hello, Friend! What do you want to ask?",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
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
