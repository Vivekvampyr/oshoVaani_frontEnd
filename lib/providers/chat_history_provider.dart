import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final chatHistoryProvider =
    StateNotifierProvider<ChatHistoryNotifier, List<String>>((ref) {
  return ChatHistoryNotifier();
});

class ChatHistoryNotifier extends StateNotifier<List<String>> {
  ChatHistoryNotifier() : super([]) {
    _loadChatHistory();
  }

  Future<void> _loadChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getStringList('chatHistory') ?? [];
  }

  Future<void> addChat(String chatTitle) async {
    final updatedChats = [chatTitle, ...state];
    state = updatedChats;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('chatHistory', updatedChats);
  }

  Future<void> deleteChat(String chatTitle) async {
    final updatedChats = state.where((chat) => chat != chatTitle).toList();
    state = updatedChats;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('chatHistory', updatedChats);
  }

  Future<void> clearChats() async {
    state = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('chatHistory');
  }
}
