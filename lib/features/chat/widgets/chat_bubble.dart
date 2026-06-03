import 'package:flutter/material.dart';
import '../domain/models/chat_message.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final isLoading = !isUser && message.text.isEmpty && !message.hasError;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: isUser ? _buildUserBubble(context) : _buildAiBubble(context, isLoading),
      ),
    );
  }

  Widget _buildUserBubble(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (message.imageUrl != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              message.imageUrl!,
              height: 180,
              width: 180,
              fit: BoxFit.cover,
              loadingBuilder: (_, child, progress) =>
                  progress == null ? child : const SizedBox(height: 180, width: 180, child: Center(child: CircularProgressIndicator())),
            ),
          ),
        if (message.text.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0052CC), Color(0xFF003D9B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(4),
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF003D9B).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Text(
              message.text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14.5,
                fontFamily: 'Inter',
                height: 1.4,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAiBubble(BuildContext context, bool isLoading) {
    if (isLoading) {
      return _buildLoadingBubble();
    }
    if (message.hasError) {
      return _buildErrorBubble();
    }
    // Has structured fields → rich card
    if (message.summary != null) {
      return _buildStructuredCard(context);
    }
    // Plain text fallback
    return _buildPlainTextBubble();
  }

  Widget _buildLoadingBubble() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(20),
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _DotLoader(),
          const SizedBox(width: 8),
          const Text('HealthSathi AI is thinking...', style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontFamily: 'Inter')),
        ],
      ),
    );
  }

  Widget _buildErrorBubble() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(20),
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        border: Border.all(color: const Color(0xFFFECDD3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFE11D48), size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message.text,
              style: const TextStyle(color: Color(0xFF9F1239), fontSize: 13.5, fontFamily: 'Inter'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlainTextBubble() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(20),
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Text(
        message.text,
        style: const TextStyle(color: Color(0xFF1E293B), fontSize: 14.5, fontFamily: 'Inter', height: 1.5),
      ),
    );
  }

  Widget _buildStructuredCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(20),
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF003D9B), Color(0xFF0052CC)]),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(20)),
            ),
            child: const Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text('HealthSathi AI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontFamily: 'Inter', fontSize: 13)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary
                if (message.summary != null && message.summary!.isNotEmpty) ...[
                  const Text('Summary', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, fontFamily: 'Inter', color: Color(0xFF1E293B))),
                  const SizedBox(height: 4),
                  Text(message.summary!, style: const TextStyle(fontSize: 14, fontFamily: 'Inter', color: Color(0xFF334155), height: 1.45)),
                  const SizedBox(height: 14),
                ],
                // Key Points
                if (message.keyPoints != null && message.keyPoints!.isNotEmpty) ...[
                  const Text('Key Points', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, fontFamily: 'Inter', color: Color(0xFF1E293B))),
                  const SizedBox(height: 6),
                  ...message.keyPoints!.map((point) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(color: Color(0xFF003D9B), fontWeight: FontWeight.bold)),
                        Expanded(child: Text(point, style: const TextStyle(fontSize: 13.5, fontFamily: 'Inter', color: Color(0xFF334155), height: 1.4))),
                      ],
                    ),
                  )),
                  const SizedBox(height: 14),
                ],
                // Simple Explanation
                if (message.simpleExplanation != null && message.simpleExplanation!.isNotEmpty) ...[
                  const Text('Simple Explanation', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, fontFamily: 'Inter', color: Color(0xFF1E293B))),
                  const SizedBox(height: 4),
                  Text(message.simpleExplanation!, style: const TextStyle(fontSize: 14, fontFamily: 'Inter', color: Color(0xFF334155), height: 1.45)),
                  const SizedBox(height: 14),
                ],
                // Possible Meaning
                if (message.possibleMeaning != null && message.possibleMeaning!.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F4FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBFD1FF)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline, color: Color(0xFF003D9B), size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(message.possibleMeaning!, style: const TextStyle(fontSize: 13.5, fontFamily: 'Inter', color: Color(0xFF1E3A8A), height: 1.4))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                // Recommendation
                if (message.recommendation != null && message.recommendation!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FFF4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.local_hospital_outlined, color: Color(0xFF16A34A), size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(message.recommendation!, style: const TextStyle(fontSize: 13.5, fontFamily: 'Inter', color: Color(0xFF166534), height: 1.4))),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Animated 3-dot loader
class _DotLoader extends StatefulWidget {
  @override
  State<_DotLoader> createState() => _DotLoaderState();
}

class _DotLoaderState extends State<_DotLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final delay = i / 3;
            final t = (_controller.value - delay).clamp(0.0, 1.0);
            final opacity = (t < 0.5 ? t * 2 : (1 - t) * 2).clamp(0.3, 1.0);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Opacity(
                opacity: opacity,
                child: const CircleAvatar(radius: 4, backgroundColor: Color(0xFF003D9B)),
              ),
            );
          }),
        );
      },
    );
  }
}
