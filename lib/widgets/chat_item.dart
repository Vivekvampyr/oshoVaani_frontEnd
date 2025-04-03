import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oshovaani/models/chat_model.dart';
import 'package:oshovaani/providers/liked_messages_provider.dart';
import 'package:oshovaani/providers/chat_history_provider.dart';
import 'package:intl/intl.dart';

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

  String _formatMessageTime(String messageId) {
    try {
      final timestamp = message.timestamp;
      final now = DateTime.now();
      final difference = now.difference(timestamp);

      // For messages less than a minute old, show actual time
      if (difference.inMinutes < 1) {
        return DateFormat('h:mm a').format(timestamp);
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
      return DateFormat('h:mm a').format(DateTime.now());
    }
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Remove from chat history
              ref.read(chatHistoryProvider.notifier).removeMessage(
                    message.chatId,
                    message.id,
                  );
              // Remove from liked messages if exists
              if (ref
                  .read(likedMessagesProvider.notifier)
                  .isLiked(message.id)) {
                ref.read(likedMessagesProvider.notifier).toggleLike(message);
              }
              Navigator.pop(context);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final likedMessages = ref.watch(likedMessagesProvider);
    final isLiked = likedMessages.any((msg) => msg.id == message.id);
    final messageTime = _formatMessageTime(message.id);

    return GestureDetector(
      onLongPress: () => _showDeleteDialog(context, ref),
      child: Container(
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
                    text,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () {
                        ref
                            .read(likedMessagesProvider.notifier)
                            .toggleLike(message);
                      },
                      child: Text(
                        isLiked ? "🧡 Liked" : "🤍 Like",
                        style: TextStyle(
                          fontSize: 12,
                          color: isLiked ? Colors.orange : Colors.grey,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      messageTime,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (isMe) const SizedBox(width: 15),
            if (isMe) ProfileContainer(isMe: isMe),
          ],
        ),
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
