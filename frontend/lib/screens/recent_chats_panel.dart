import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../services/app_services.dart';
import '../services/chat_api.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_sizes.dart';
import '../theme/app_text.dart';
import '../widgets/duo_icon.dart';
import '../widgets/notice_card.dart';
import '../widgets/pill_button.dart';
import '../widgets/round_icon_button.dart';
import '../widgets/tap_surface.dart';
import 'chat_screen.dart';

/// Recent chats (team request): a panel that slides in from the left with
/// the student's newest chats. Tapping one opens it again, with its
/// messages, so the student carries on where they left off.
///
/// PERFORMANCE: solid, not glass (no extra blur); only a slide, and with
/// "reduce motion" it opens at once.
Future<void> showRecentChats(BuildContext context) {
  final c = AppColors.of(context);
  final l10n = AppLocalizations.of(context);
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: l10n.recentChatsClose,
    barrierColor: c.night.withValues(alpha: 0.3),
    transitionDuration: AppMotion.of(context, AppMotion.medium),
    pageBuilder: (context, _, _) => const _RecentChatsPanel(),
    transitionBuilder: (context, animation, _, child) => SlideTransition(
      position: Tween(
        begin: const Offset(-1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: AppMotion.ease)),
      child: child,
    ),
  );
}

class _RecentChatsPanel extends StatefulWidget {
  const _RecentChatsPanel();

  @override
  State<_RecentChatsPanel> createState() => _RecentChatsPanelState();
}

class _RecentChatsPanelState extends State<_RecentChatsPanel> {
  Future<List<RecentChat>?>? _chats;

  /// The chat whose messages are loading right now.
  String? _opening;

  /// The last chat that was tapped could not be opened.
  bool _openFailed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _chats ??= _load();
  }

  Future<List<RecentChat>?> _load() async {
    final services = AppServices.of(context);
    return services.chat.recentChats(token: await services.auth.token());
  }

  Future<void> _open(RecentChat chat) async {
    if (_opening != null) return;
    setState(() {
      _opening = chat.sessionId;
      _openFailed = false;
    });
    final services = AppServices.of(context);
    final messages = await services.chat.chatMessages(
      sessionId: chat.sessionId,
      token: await services.auth.token(),
    );
    if (!mounted) return;
    if (messages == null) {
      setState(() {
        _opening = null;
        _openFailed = true;
      });
      return;
    }
    final l10n = AppLocalizations.of(context);
    final navigator = Navigator.of(context);
    navigator.pop();
    navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => ChatScreen(
          eyebrow: l10n.recentChatEyebrow,
          problem: chat.problem,
          problemId: chat.problemId,
          sessionId: chat.sessionId,
          history: messages,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    final width = math.min(MediaQuery.sizeOf(context).width * 0.88, 400.0);

    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: width,
        height: double.infinity,
        child: Material(
          color: c.surfaceRaised,
          borderRadius: const BorderRadius.horizontal(
            right: Radius.circular(28),
          ),
          clipBehavior: Clip.antiAlias,
          child: SafeArea(
            right: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.s5,
                AppSpace.s3,
                AppSpace.s3,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Semantics(
                          header: true,
                          child: Text(
                            l10n.recentChatsTitle,
                            style: AppText.h2.copyWith(color: c.ink),
                          ),
                        ),
                      ),
                      RoundIconButton(
                        icon: AppIcon.back,
                        semanticLabel: l10n.recentChatsClose,
                        tone: RoundIconTone.light,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpace.s3),
                    child: Text(
                      l10n.recentChatsHint,
                      style: AppText.body.copyWith(color: c.inkMuted),
                    ),
                  ),
                  const SizedBox(height: AppSpace.s4),
                  if (_openFailed)
                    Padding(
                      padding: const EdgeInsets.only(
                        right: AppSpace.s2,
                        bottom: AppSpace.s3,
                      ),
                      child: NoticeCard(
                        icon: AppIcon.cloudOff,
                        text: l10n.recentChatsOpenFailed,
                      ),
                    ),
                  Expanded(
                    child: FutureBuilder(
                      future: _chats,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState != ConnectionState.done) {
                          return Text(
                            l10n.recentChatsLoading,
                            style: AppText.body.copyWith(color: c.inkMuted),
                          );
                        }
                        final chats = snapshot.data;
                        if (chats == null) {
                          return Align(
                            alignment: Alignment.topCenter,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                right: AppSpace.s2,
                              ),
                              child: NoticeCard(
                                icon: AppIcon.cloudOff,
                                text: l10n.recentChatsFailed,
                                action: PillButton(
                                  label: l10n.tryAgain,
                                  onPressed: () =>
                                      setState(() => _chats = _load()),
                                ),
                              ),
                            ),
                          );
                        }
                        if (chats.isEmpty) {
                          return Text(
                            l10n.recentChatsEmpty,
                            style: AppText.body.copyWith(color: c.ink),
                          );
                        }
                        return ListView.separated(
                          padding: const EdgeInsets.only(
                            right: AppSpace.s2,
                            bottom: AppSpace.s6,
                          ),
                          itemCount: chats.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppSpace.s3),
                          itemBuilder: (context, i) => _ChatRow(
                            chat: chats[i],
                            opening: _opening == chats[i].sessionId,
                            onTap: () => _open(chats[i]),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One old chat: the problem, the day it started, and "Solved" (an icon
/// and the word, never colour alone).
class _ChatRow extends StatelessWidget {
  const _ChatRow({
    required this.chat,
    required this.opening,
    required this.onTap,
  });

  final RecentChat chat;
  final bool opening;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final started = chat.startedAt;
    final small = AppText.caption.copyWith(
      fontSize: 14,
      height: 18 / 14,
      fontWeight: FontWeight.w600,
      fontVariations: const [FontVariation('wght', 600)],
    );

    return MergeSemantics(
      child: Semantics(
        button: true,
        child: TapSurface(
          onTap: onTap,
          pressScale: 0.98,
          color: c.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            side: BorderSide(color: c.line),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSizes.button),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.s4,
                AppSpace.s3,
                AppSpace.s3,
                AppSpace.s3,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          chat.problem,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.body.copyWith(
                            color: c.ink,
                            fontWeight: FontWeight.w600,
                            fontVariations: const [FontVariation('wght', 600)],
                          ),
                        ),
                        const SizedBox(height: AppSpace.s1),
                        Wrap(
                          spacing: AppSpace.s3,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (started != null)
                              Text(
                                DateFormat('d MMM', locale).format(started),
                                style: small.copyWith(color: c.inkMuted),
                              ),
                            if (chat.solved)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  DuoIcon(
                                    AppIcon.check,
                                    size: 16,
                                    color: c.mintInk,
                                  ),
                                  const SizedBox(width: AppSpace.s1),
                                  Text(
                                    l10n.recentChatsSolved,
                                    style: small.copyWith(color: c.mintInk),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpace.s2),
                  opening
                      ? Text(
                          l10n.recentChatsOpening,
                          style: small.copyWith(color: c.lilacInk),
                        )
                      : DuoIcon(AppIcon.forward, size: 20, color: c.inkMuted),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
