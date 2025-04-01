import 'package:flutter/material.dart';
import 'package:oshovaani/widgets/text_and_voice_filed.dart';

class SendButton extends StatefulWidget {
  final VoidCallback _sendTextMessage;
  final VoidCallback _sendVoiceMessage;
  final InputMode _inputMode;
  final bool _isReplying;
  final bool _isListening;
  const SendButton({
    super.key,
    required InputMode inputMode,
    required VoidCallback sendTextMessage,
    required VoidCallback sendVoiceMessage,
    required bool isReplying,
    required bool isListening,
  })  : _inputMode = inputMode,
        _sendTextMessage = sendTextMessage,
        _sendVoiceMessage = sendVoiceMessage,
        _isReplying = isReplying,
        _isListening = isListening;

  @override
  State<SendButton> createState() => _SendButtonState();
}

class _SendButtonState extends State<SendButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget._isListening) {
      _controller.forward();
    } else {
      _controller.reverse();
    }

    return ScaleTransition(
      scale: _animation,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: widget._isListening
              ? Colors.red
              : Theme.of(context).colorScheme.secondary,
          foregroundColor: Theme.of(context).colorScheme.onSecondary,
          shape: const CircleBorder(),
          padding: const EdgeInsets.all(15),
        ),
        onPressed: widget._isReplying
            ? null
            : widget._inputMode == InputMode.text
                ? widget._sendTextMessage
                : widget._sendVoiceMessage,
        child: Icon(
          widget._inputMode == InputMode.text
              ? Icons.send
              : widget._isListening
                  ? Icons.mic
                  : Icons.mic_none,
        ),
      ),
    );
  }
}
