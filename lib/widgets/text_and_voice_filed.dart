import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oshovaani/models/chat_model.dart';
import 'package:oshovaani/providers/chat_history_provider.dart';
import 'package:oshovaani/services/ai_handler.dart';
import 'package:oshovaani/services/voice_handler.dart';
import 'package:oshovaani/widgets/send_button.dart';

enum InputMode {
  text,
  voice,
}

class TextAndVoiceField extends ConsumerStatefulWidget {
  final Function(String) onMessageSent;
  final String chatId;

  const TextAndVoiceField({
    super.key,
    required this.onMessageSent,
    required this.chatId,
  });

  @override
  ConsumerState<TextAndVoiceField> createState() => _TextAndVoiceFieldState();
}

class _TextAndVoiceFieldState extends ConsumerState<TextAndVoiceField> {
  InputMode _inputMode = InputMode.voice;
  final _messageController = TextEditingController();
  final AIHandler _openAI = AIHandler();
  final VoiceHandler voiceHandler = VoiceHandler();
  var _isReplying = false;
  var _isListening = false;
  String? _threadId;

  @override
  void initState() {
    super.initState();
    voiceHandler.initSpeech();
    _loadThreadId();
  }

  Future<void> _loadThreadId() async {
    final prefs = await SharedPreferences.getInstance();
    final savedThreadId = prefs.getString('thread_id');

    if (savedThreadId != null && savedThreadId.isNotEmpty) {
      setState(() {
        _threadId = savedThreadId;
      });
    }
  }

  Future<void> _createThreadIfNeeded() async {
    if (_threadId == null) {
      print("❤ CREATE THREAD!!!!");
      final newThreadId = await _openAI.createThread();
      if (newThreadId != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('thread_id', newThreadId);
        setState(() {
          _threadId = newThreadId;
        });
      } else {
        debugPrint("⚠️ Failed to create thread");
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _messageController,
            onChanged: (value) {
              setInputMode(value.isNotEmpty ? InputMode.text : InputMode.voice);
              print("${value.toString()} this is input value");
            },
            cursorColor: Theme.of(context).colorScheme.onPrimary,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        SendButton(
          isListening: _isListening,
          isReplying: _isReplying,
          inputMode: _inputMode,
          sendTextMessage: () {
            final message = _messageController.text.trim();
            if (message.isNotEmpty) {
              _messageController.clear();
              sendTextMessage(message);
              print("😂 Button is working");
            }
          },
          sendVoiceMessage: sendVoiceMessage,
        ),
      ],
    );
  }

  void setInputMode(InputMode inputMode) {
    setState(() {
      _inputMode = inputMode;
      print("this is input $_inputMode");
    });
  }

  void sendVoiceMessage() async {
    if (!voiceHandler.isEnabled) {
      debugPrint('⚠️ Voice recognition is not supported');
      return;
    }

    if (voiceHandler.speechToText.isListening) {
      await voiceHandler.stopListening();
      setListeningState(false);
    } else {
      setListeningState(true);
      final result = await voiceHandler.startListening();
      setListeningState(false);

      if (result.isNotEmpty) {
        sendTextMessage(result);
      }
    }
  }

  void sendTextMessage(String message) async {
    print("😒BUTTON IS WORKING HERE!!!");
    await _createThreadIfNeeded();

    if (_threadId == null) {
      print("⚠️ No thread ID available, message cannot be sent");
      return;
    }

    setReplyingState(true);

    // Add user message
    ref.read(chatHistoryProvider.notifier).addMessage(
          widget.chatId,
          ChatModel(
            id: DateTime.now().toString(),
            message: message,
            isMe: true,
            chatId: widget.chatId,
            title: "New Chat",
          ),
        );

    try {
      final aiResponse = await _openAI.generateResponse(_threadId!, message);
      print("🙂AI Response == $aiResponse");

      // Add AI response
      ref.read(chatHistoryProvider.notifier).addMessage(
            widget.chatId,
            ChatModel(
              id: DateTime.now().toString(),
              message: aiResponse,
              isMe: false,
              chatId: widget.chatId,
              title: "New Chat",
            ),
          );
    } catch (e) {
      // Add error message
      ref.read(chatHistoryProvider.notifier).addMessage(
            widget.chatId,
            ChatModel(
              id: DateTime.now().toString(),
              message: "⚠️ Error: Failed to get response",
              isMe: false,
              chatId: widget.chatId,
              title: "New Chat",
            ),
          );
      debugPrint("❌ AI Response Error: $e");
    } finally {
      setReplyingState(false);
      _messageController.clear();
      setInputMode(InputMode.voice);
    }
  }

  void setReplyingState(bool isReplying) {
    setState(() {
      _isReplying = isReplying;
    });
  }

  void setListeningState(bool isListening) {
    setState(() {
      _isListening = isListening;
    });
  }
}
