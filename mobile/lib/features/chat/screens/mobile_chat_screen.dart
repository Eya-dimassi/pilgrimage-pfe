import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_surfaces.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/mobile_chat_repository.dart';

class MobileChatScreen extends ConsumerStatefulWidget {
  const MobileChatScreen({super.key});

  @override
  ConsumerState<MobileChatScreen> createState() => _MobileChatScreenState();
}

class _MobileChatScreenState extends ConsumerState<MobileChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatBubbleMessage> _messages = <_ChatBubbleMessage>[];

  bool _sending = false;
  String? _activeUserId;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_messages.isEmpty) {
      _messages.add(
        _ChatBubbleMessage(
          role: 'assistant',
          text: 'chat.welcome'.tr(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authProvider).valueOrNull;
    final user = session?.user;

    if (user == null) {
      return const SizedBox.shrink();
    }

    if (_activeUserId != user.id) {
      _activeUserId = user.id;
      _messages
        ..clear()
        ..add(
           _ChatBubbleMessage(
            role: 'assistant',
            text:
                'chat.welcome'.tr(),
          ),
        );
      _sending = false;
      _messageController.clear();
    }

    return Stack(
      children: [
        Container(color: const Color(0xFFF7F7F3)),
        Positioned(
          top: -70,
          right: -50,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Column(
          children: [
            Expanded(
              child: _buildChatBody(),
            ),
            _buildComposer(),
          ],
        ),
      ],
    );
  }

  Widget _buildChatBody() {
    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
      itemCount: _messages.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isUser = message.role == 'user';
        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 310),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primaryDark : AppColors.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isUser
                      ? AppColors.primaryDark
                      : AppColors.borderSoft,
                ),
                boxShadow: isUser ? const [] : AppShadows.soft,
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.45,
                  color: isUser ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildComposer() {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        radius: 22,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: 'chat.input_hint'.tr(),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 10,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 48,
              height: 48,
              child: ElevatedButton(
                onPressed: _sending ? null : _sendMessage,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  shape: const CircleBorder(),
                ),
                child: _sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.arrow_upward_rounded, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final history = _messages
        .map(
          (message) => MobileChatMessagePayload(
            role: message.role,
            content: message.text,
          ),
        )
        .toList(growable: false);

    setState(() {
      _sending = true;
      _messages.add(_ChatBubbleMessage(role: 'user', text: text));
      _messageController.clear();
    });
    _scrollToBottom();

    try {
      final answer = await ref.read(mobileChatRepositoryProvider).sendMessage(
            message: text,
            history: history,
          );

      if (!mounted) return;
      setState(() {
        _messages.add(_ChatBubbleMessage(role: 'assistant', text: answer));
      });
      _scrollToBottom();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _messages.add(
           _ChatBubbleMessage(
            role: 'assistant',
            text:
                'chat.temporary_unavailable'.tr(),
          ),
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
      _scrollToBottom();
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }
}

class _ChatBubbleMessage {
  const _ChatBubbleMessage({
    required this.role,
    required this.text,
  });

  final String role;
  final String text;
}
