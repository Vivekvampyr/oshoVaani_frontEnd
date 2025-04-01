import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oshovaani/providers/liked_messages_provider.dart';
import 'package:oshovaani/widgets/chat_item.dart';

class LikedMessagesScreen extends ConsumerWidget {
  const LikedMessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final likedMessages = ref.watch(likedMessagesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Liked Messages'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: likedMessages.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 64,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No liked messages yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.5),
                        ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: likedMessages.length,
              itemBuilder: (context, index) {
                final message = likedMessages[index];
                return ChatItem(
                  text: message.message,
                  isMe: message.isMe,
                  message: message,
                );
              },
            ),
    );
  }
}
