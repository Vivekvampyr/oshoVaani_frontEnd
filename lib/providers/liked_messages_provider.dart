import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oshovaani/models/chat_model.dart';
import 'dart:convert';

final likedMessagesProvider =
    StateNotifierProvider<LikedMessagesNotifier, List<ChatModel>>((ref) {
  return LikedMessagesNotifier();
});

class LikedMessagesNotifier extends StateNotifier<List<ChatModel>> {
  LikedMessagesNotifier() : super([]) {
    _loadLikedMessages();
  }

  Future<void> _loadLikedMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final likedMessagesJson = prefs.getString('likedMessages');
    if (likedMessagesJson != null) {
      final List<dynamic> decoded = json.decode(likedMessagesJson);
      state = decoded.map((msg) => ChatModel.fromJson(msg)).toList();
    }
  }

  Future<void> _saveLikedMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final encodedMessages = state.map((msg) => msg.toJson()).toList();
    await prefs.setString('likedMessages', json.encode(encodedMessages));
  }

  Future<void> toggleLike(ChatModel message) async {
    final isLiked = state.any((msg) => msg.id == message.id);
    if (isLiked) {
      state = state.where((msg) => msg.id != message.id).toList();
    } else {
      state = [...state, message];
    }
    await _saveLikedMessages();
  }

  bool isLiked(String messageId) {
    return state.any((msg) => msg.id == messageId);
  }
}
