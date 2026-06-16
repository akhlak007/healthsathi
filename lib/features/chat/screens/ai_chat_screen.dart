import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/chat_provider.dart';
import '../data/services/gemini_service.dart';
import '../widgets/chat_bubble.dart';

class AIChatScreen extends ConsumerWidget {
  const AIChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(chatProvider);
    final textController = TextEditingController();
    final openRouter = OpenRouterService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('HealthSathi AI', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB), Color(0xFF90CAF9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[messages.length - 1 - index];
                    return ChatBubble(message: msg);
                  },
                ),
              ),
              const Divider(height: 1, color: Colors.transparent),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  children: [

                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.image, color: Colors.grey),
                              onPressed: () async {
                                await ref.read(chatProvider.notifier).sendImage();
                              },
                            ),
                            Expanded(
                              child: TextField(
                                controller: textController,
                                style: const TextStyle(color: Colors.black87),
                                decoration: const InputDecoration(
                                  hintText: 'Ask something…',
                                  hintStyle: TextStyle(color: Colors.grey),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                onSubmitted: (value) async {
                                  if (value.trim().isNotEmpty) {
                                    await ref.read(chatProvider.notifier).sendText(value.trim());
                                    textController.clear();
                                  }
                                },
                              ),
                            ),
                            InkWell(
                              onTap: () async {
                                final text = textController.text.trim();
                                if (text.isNotEmpty) {
                                  await ref.read(chatProvider.notifier).sendText(text);
                                  textController.clear();
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00B4D8),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.send, color: Colors.white, size: 20),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
