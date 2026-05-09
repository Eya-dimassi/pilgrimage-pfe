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
  final List<_ChatBubbleMessage> _messages = <_ChatBubbleMessage>[
    const _ChatBubbleMessage(
      role: 'assistant',
      text:
          'Salam. Je peux vous aider pour les rites, le planning du voyage, et les reperes pratiques du pelerinage.',
    ),
  ];

  bool _sending = false;
  _ChatLanguage _language = _ChatLanguage.fr;
  String? _activeUserId;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
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
          const _ChatBubbleMessage(
            role: 'assistant',
            text:
                'Salam. Je peux vous aider pour les rites, le planning du voyage, et les reperes pratiques du pelerinage.',
          ),
        );
      _sending = false;
      _messageController.clear();
    }

    final supportsChat = user.role == 'PELERIN' || user.role == 'FAMILLE';

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
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
              child: _ChatHeader(
                language: _language,
                onLanguageChanged: (value) {
                  setState(() => _language = value);
                },
              ),
            ),
            Expanded(
              child: supportsChat
                  ? _buildChatBody()
                  : const _GuideChatUnavailableCard(),
            ),
            if (supportsChat) _buildComposer(),
          ],
        ),
      ],
    );
  }

  Widget _buildChatBody() {
    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
      itemCount: _messages.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index == 0) {
          return const _ChatIntroCard();
        }

        final message = _messages[index - 1];
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
                decoration: const InputDecoration(
                  hintText: 'Posez votre question au chatbot',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.symmetric(
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
            language: _language.code,
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
          const _ChatBubbleMessage(
            role: 'assistant',
            text:
                'Je n ai pas pu repondre pour le moment. Verifiez la connexion ou reessayez dans un instant.',
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

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({
    required this.language,
    required this.onLanguageChanged,
  });

  final _ChatLanguage language;
  final ValueChanged<_ChatLanguage> onLanguageChanged;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      radius: 24,
      gradient: const LinearGradient(
        colors: [
          Color(0xFFF6FBF8),
          Color(0xFFFFFFFF),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              AppIconBadge(
                icon: Icons.auto_awesome_rounded,
                size: 42,
                backgroundColor: AppColors.goldSoft,
                foregroundColor: AppColors.gold,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chatbot spirituel',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Questions pratiques sur la Omra, le Hajj, et le parcours.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _ChatLanguage.values
                .map(
                  (item) => InkWell(
                    onTap: () => onLanguageChanged(item),
                    borderRadius: BorderRadius.circular(999),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: item == language
                            ? AppColors.primaryDark
                            : AppColors.section,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: item == language
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _ChatIntroCard extends StatelessWidget {
  const _ChatIntroCard();

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      padding: EdgeInsets.all(16),
      radius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vous pouvez demander par exemple :',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Comment faire la Omra etape par etape ?',
            style: TextStyle(
              fontSize: 12.5,
              color: AppColors.textMuted,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Que faire si je me sens fatigue pendant les rites ?',
            style: TextStyle(
              fontSize: 12.5,
              color: AppColors.textMuted,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Quels reperes officiels dois-je suivre sur place ?',
            style: TextStyle(
              fontSize: 12.5,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideChatUnavailableCard extends StatelessWidget {
  const _GuideChatUnavailableCard();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: AppCard(
          padding: const EdgeInsets.all(22),
          radius: 24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              AppIconBadge(
                icon: Icons.forum_outlined,
                size: 56,
                backgroundColor: AppColors.blueSoft,
                foregroundColor: AppColors.blue,
              ),
              SizedBox(height: 16),
              Text(
                'Chatbot bientot disponible pour les guides',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Le backend actuel ouvre le chatbot aux pelerins et aux familles. On peut etendre le support guide juste apres cette passe UI.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.5,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

enum _ChatLanguage {
  fr('Francais', 'fr'),
  ar('Arabe', 'ar'),
  en('English', 'en');

  const _ChatLanguage(this.label, this.code);

  final String label;
  final String code;
}
