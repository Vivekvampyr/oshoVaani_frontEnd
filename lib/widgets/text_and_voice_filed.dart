import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oshovaani/models/chat_model.dart';
import 'package:oshovaani/providers/chats_provider.dart';
import 'package:oshovaani/services/ai_handler.dart';
import 'package:oshovaani/services/voice_handler.dart';
import 'package:oshovaani/widgets/send_button.dart';

enum InputMode {
  text,
  voice,
}

class TextAndVoiceField extends ConsumerStatefulWidget {
  const TextAndVoiceField({super.key});

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

      if (result != null && result.isNotEmpty) {
        sendTextMessage(result);
      }
    }
  }

  void sendTextMessage(String message) async {
    await _createThreadIfNeeded();

    if (_threadId == null) {
      debugPrint("⚠️ No thread ID available, message cannot be sent");
      return;
    }

    setReplyingState(true);
    addToChatList(message, true, DateTime.now().toString());
    addToChatList('Typing...', false, 'typing');

    try {
      final aiResponse = await _openAI.generateResponse(_threadId!, message);
      removeTyping();
      print("🙂AI Response == ${aiResponse}");
      if (aiResponse != null) {
        addToChatList(aiResponse, false, DateTime.now().toString());
      } else {
        addToChatList(
            "⚠️ Error: AI response was null", false, DateTime.now().toString());
      }
    } catch (e) {
      removeTyping();
      addToChatList(
          "⚠️ Error: Failed to get response", false, DateTime.now().toString());
      debugPrint("❌ AI Response Error: $e");
    } finally {
      setReplyingState(false);
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

  void removeTyping() {
    ref.read(chatsProvider.notifier).removeTyping();
  }

  void addToChatList(dynamic message, bool isMe, String id) {
    final chats = ref.read(chatsProvider.notifier);
    String messageText;

    if (message is String) {
      messageText = message;
    } else if (message is Map<String, dynamic>) {
      messageText = message['choices']?[0]['message']?['content'] ??
          '⚠️ Error: Invalid AI response';
    } else {
      messageText = '⚠️ Error: Unexpected response format';
    }

    chats.add(ChatModel(
      id: id,
      message: messageText,
      isMe: isMe,
    ));
  }
}
