import 'package:flutter/material.dart';

class ChatDetailScreen extends StatelessWidget {
  final String chatId;

  const ChatDetailScreen({Key? key, required this.chatId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
      ),
      body: const Center(
        child: Text('Detalle del chat'),
      ),
    );
  }
}
