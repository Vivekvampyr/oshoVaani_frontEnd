import 'package:flutter/material.dart';

@immutable
class ChatModel {
  final String id;
  final String message;
  final bool isMe;
  final String chatId;
  final String title;

  const ChatModel({
    required this.id,
    required this.message,
    required this.isMe,
    required this.chatId,
    required this.title,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message': message,
      'isMe': isMe,
      'chatId': chatId,
      'title': title,
    };
  }

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      id: json['id'],
      message: json['message'],
      isMe: json['isMe'],
      chatId: json['chatId'],
      title: json['title'],
    );
  }
}
