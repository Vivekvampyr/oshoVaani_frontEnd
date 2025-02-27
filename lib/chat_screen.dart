import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oshovaani/providers/chats_provider.dart';
import 'package:oshovaani/widgets/chat_item.dart';
import 'package:oshovaani/widgets/text_and_voice_filed.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Consumer(builder: (context, ref, child) {
            final chats = ref.watch(chatsProvider).reversed.toList();
            return ListView.builder(
              reverse: true,
              itemCount: chats.length,
              itemBuilder: (context, index) => ChatItem(
                text: chats[index].message,
                isMe: chats[index].isMe,
              ),
            );
          }),
        ),
        const Padding(
          padding: EdgeInsets.all(12.0),
          child: TextAndVoiceField(),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
