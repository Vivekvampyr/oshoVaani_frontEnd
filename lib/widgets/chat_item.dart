import 'package:flutter/material.dart';

class ChatItem extends StatefulWidget {
  final String text;
  final bool isMe;
  const ChatItem({
    super.key,
    required this.text,
    required this.isMe,
  });

  @override
  State<ChatItem> createState() => _ChatItemState();
}

class _ChatItemState extends State<ChatItem> {
  bool isLiked = false;

  void toggleLike() {
    if (!widget.isMe) {
      // Allow liking only if the message is from the computer (isMe == false)
      setState(() {
        isLiked = !isLiked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        vertical: 10,
        horizontal: 12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            widget.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!widget.isMe) ProfileContainer(isMe: widget.isMe),
          if (!widget.isMe) const SizedBox(width: 15),
          Column(
            crossAxisAlignment:
                widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.60,
                ),
                decoration: BoxDecoration(
                  color: widget.isMe
                      ? Theme.of(context).colorScheme.secondary
                      : Colors.grey.shade800,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(15),
                    topRight: const Radius.circular(15),
                    bottomLeft: Radius.circular(widget.isMe ? 15 : 0),
                    bottomRight: Radius.circular(widget.isMe ? 0 : 15),
                  ),
                ),
                child: SelectableText(
                  "Hello There! Osho Here!", //widget.text
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              if (!widget.isMe) // Only show like button for computer messages
                GestureDetector(
                  onTap: toggleLike,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked ? Colors.red : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isLiked ? "Liked" : "Like",
                        style: TextStyle(
                          color: isLiked ? Colors.red : Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (widget.isMe) const SizedBox(width: 15),
          if (widget.isMe) ProfileContainer(isMe: widget.isMe),
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
