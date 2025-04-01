import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oshovaani/models/chat_model.dart';
import 'package:oshovaani/providers/liked_messages_provider.dart';

class ChatItem extends ConsumerWidget {
  final String text;
  final bool isMe;
  final ChatModel message;
  const ChatItem({
    super.key,
    required this.text,
    required this.isMe,
    required this.message,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final likedMessages = ref.watch(likedMessagesProvider);
    final isLiked = likedMessages.any((msg) => msg.id == message.id);

    return Container(
      margin: const EdgeInsets.symmetric(
        vertical: 10,
        horizontal: 12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ProfileContainer(isMe: isMe),
          if (!isMe) const SizedBox(width: 15),
          Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.60,
                ),
                decoration: BoxDecoration(
                  color: isMe
                      ? Theme.of(context).colorScheme.secondary
                      : Colors.grey.shade800,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(15),
                    topRight: const Radius.circular(15),
                    bottomLeft: Radius.circular(isMe ? 15 : 0),
                    bottomRight: Radius.circular(isMe ? 0 : 15),
                  ),
                ),
                child: SelectableText(
                  text, //text
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              GestureDetector(
                onTap: () {
                  ref.read(likedMessagesProvider.notifier).toggleLike(message);
                },
                child: Text(
                  isLiked ? "🧡 Liked" : "🤍 Like",
                  style: TextStyle(
                    fontSize: 12,
                    color: isLiked ? Colors.orange : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          if (isMe) const SizedBox(width: 15),
          if (isMe) ProfileContainer(isMe: isMe),
        ],
      ),
    );
  }
}

class ProfileContainer extends StatelessWidget {
  const ProfileContainer({
    super.key,
    required this.isMe,
  });

  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isMe
            ? Theme.of(context).colorScheme.secondary
            : Colors.grey.shade800,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(10),
          topRight: const Radius.circular(10),
          bottomLeft: Radius.circular(isMe ? 0 : 15),
          bottomRight: Radius.circular(isMe ? 15 : 0),
        ),
      ),
      child: CircleAvatar(
        backgroundImage: AssetImage(
          isMe ? 'assets/images/user.jpeg' : 'assets/images/osho.jpg',
        ),
        radius: 20, // Adjust size as needed
      ),
    );
  }
}
