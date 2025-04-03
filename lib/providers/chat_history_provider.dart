import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oshovaani/models/chat_model.dart';

final chatHistoryProvider =
    StateNotifierProvider<ChatHistoryNotifier, Map<String, List<ChatModel>>>(
        (ref) {
  return ChatHistoryNotifier();
});

class ChatHistoryNotifier extends StateNotifier<Map<String, List<ChatModel>>> {
  ChatHistoryNotifier() : super({}) {
    _loadChatHistory();
  }

  final Map<String, String> _chatTitles = {};

  Future<void> _loadChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final chatHistoryJson = prefs.getString('chatHistory');
    final chatTitlesJson = prefs.getString('chatTitles');

    if (chatTitlesJson != null) {
      final Map<String, dynamic> decodedTitles = json.decode(chatTitlesJson);
      _chatTitles.addAll(Map<String, String>.from(decodedTitles));
    }

    if (chatHistoryJson != null) {
      final Map<String, dynamic> decoded = json.decode(chatHistoryJson);
      final Map<String, List<ChatModel>> loadedChats = {};

      decoded.forEach((chatId, messages) {
        loadedChats[chatId] =
            (messages as List).map((msg) => ChatModel.fromJson(msg)).toList();
      });

      state = loadedChats;
    }
  }

  Future<void> _saveChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, List<Map<String, dynamic>>> encodedChats = {};

    state.forEach((chatId, messages) {
      encodedChats[chatId] = messages.map((msg) => msg.toJson()).toList();
    });

    await prefs.setString('chatHistory', json.encode(encodedChats));
    await prefs.setString('chatTitles', json.encode(_chatTitles));
  }

  String getChatTitle(String chatId) {
    return _chatTitles[chatId] ?? "New Chat";
  }

  Future<void> setLastSelectedChat(String chatId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastSelectedChat', chatId);
  }

  Future<String?> getLastSelectedChat() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('lastSelectedChat');
  }

  Future<void> addChat(String title) async {
    final String chatId = DateTime.now().millisecondsSinceEpoch.toString();
    final updatedChats = Map<String, List<ChatModel>>.from(state);
    updatedChats[chatId] = [];
    _chatTitles[chatId] = title;
    state = updatedChats;
    await _saveChatHistory();
    await setLastSelectedChat(chatId);
  }

  Future<void> deleteChat(String chatId) async {
    final updatedChats = Map<String, List<ChatModel>>.from(state);
    updatedChats.remove(chatId);
    _chatTitles.remove(chatId);
    state = updatedChats;
    await _saveChatHistory();

    // If we deleted the last selected chat, select the most recent one
    final lastSelected = await getLastSelectedChat();
    if (lastSelected == chatId && updatedChats.isNotEmpty) {
      await setLastSelectedChat(updatedChats.keys.first);
    }
  }

  Future<void> renameChat(String chatId, String newTitle) async {
    if (state.containsKey(chatId)) {
      _chatTitles[chatId] = newTitle;
      // Create a new state to trigger UI update
      final updatedChats = Map<String, List<ChatModel>>.from(state);
      state = updatedChats;
      await _saveChatHistory();
    }
  }

  Future<void> addMessage(String chatId, ChatModel message) async {
    final updatedChats = Map<String, List<ChatModel>>.from(state);
    if (updatedChats.containsKey(chatId)) {
      updatedChats[chatId] = [...updatedChats[chatId]!, message];
      state = updatedChats;
      await _saveChatHistory();
    }
  }

  Future<void> clearAllChats() async {
    state = {};
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('chatHistory');
    await prefs.remove('chatTitles');
    await prefs.remove('lastSelectedChat');
  }

  Future<void> removeMessage(String chatId, String messageId) async {
    if (state.containsKey(chatId)) {
      final updatedChats = Map<String, List<ChatModel>>.from(state);
      updatedChats[chatId] =
          updatedChats[chatId]!.where((msg) => msg.id != messageId).toList();
      state = updatedChats;
      await _saveChatHistory();
    }
  }
}
