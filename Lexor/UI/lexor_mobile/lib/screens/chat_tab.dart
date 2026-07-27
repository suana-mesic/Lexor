import 'package:flutter/material.dart';
import 'package:lexor_mobile/providers/chat_provider.dart';
import 'package:lexor_mobile/theme/app_colors.dart';
import 'package:provider/provider.dart';

/// Removes Android's stretch/glow overscroll so the chat content doesn't visually
/// stretch (text appearing to enlarge) when the list is pulled past its edge.
class _NoOverscrollBehavior extends MaterialScrollBehavior {
  const _NoOverscrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;
}

class ChatTab extends StatefulWidget {
  const ChatTab({super.key});

  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<ChatProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => provider.loadInitialHistory(),
    );
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
        provider.loadOlder();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _send(ChatProvider provider) {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    _controller.clear();
    provider.send(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutralBg,
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            Expanded(
              child: Consumer<ChatProvider>(
                builder: (context, provider, _) {
                  final messages = provider.messages;
                  if (provider.isLoadingHistory && messages.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (messages.isEmpty && !provider.isSending) {
                    return _emptyState();
                  }

                  final showTyping = provider.isSending;
                  final showLoadingMore = provider.isLoadingMore;
                  final extraBottom = showTyping ? 1 : 0;
                  final extraTop = showLoadingMore ? 1 : 0;

                  return ScrollConfiguration(
                    behavior: const _NoOverscrollBehavior(),
                    child: ListView.builder(
                      controller: _scroll,
                      reverse: true,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length + extraTop + extraBottom,
                      itemBuilder: (context, index) {
                        if (showTyping && index == 0) return _typingBubble();
                        if (showLoadingMore &&
                            index == messages.length + extraBottom) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          );
                        }
                        final i = messages.length - 1 - (index - extraBottom);
                        return _bubble(messages[i]);
                      },
                    ),
                  );
                },
              ),
            ),
            _inputBar(),
          ],
        ),
      ),
    );
  }

  Widget _header() => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    color: AppColors.primary,
    child: const Row(
      children: [
        Icon(Icons.smart_toy_outlined, color: Colors.white),
        SizedBox(width: 10),
        Text(
          'HR Asistent',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );

  Widget _emptyState() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat_bubble_outline, size: 56, color: AppColors.neutralFg),
          const SizedBox(height: 16),
          Text(
            'Postavite pitanje o pravima, odsustvu ili platama.\nOdgovaram na osnovu internih dokumenata kompanije.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.neutralFg),
          ),
        ],
      ),
    ),
  );

  Widget _bubble(ChatMessage m) {
    final isUser = m.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: isUser ? null : Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              m.text,
              style: TextStyle(
                color: isUser ? Colors.white : Colors.black87,
                fontSize: 15,
              ),
            ),
            if (!isUser && m.sources.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Izvor: ${m.sources.join(", ")}',
                style: TextStyle(
                  color: AppColors.neutralFg,
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _typingBubble() => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    ),
  );

  Widget _inputBar() {
    final provider = context.watch<ChatProvider>();
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              // Disable the selection "loupe" that magnifies text under the finger.
              magnifierConfiguration: TextMagnifierConfiguration.disabled,
              onSubmitted: (_) => _send(provider),
              decoration: InputDecoration(
                hintText: 'Napišite pitanje...',
                filled: true,
                fillColor: AppColors.neutralBg,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primary,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: provider.isSending ? null : () => _send(provider),
            ),
          ),
        ],
      ),
    );
  }
}
