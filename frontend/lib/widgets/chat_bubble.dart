import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import '../theme/app_text.dart';
import '../models/buddy.dart';
import 'buddy_avatar.dart';
import 'duo_icon.dart';
import 'pip.dart';

/// Who a chat bubble is from.
enum BubbleKind {
  /// The coach's reply: white, on the left, with a small Pip beside it.
  coach,

  /// The student's message: violet, on the right.
  student,

  /// A student message that could not be sent: soft violet, "Not sent".
  unsent,
}

/// One message in the chat.
///
/// It only takes the message [text]. The coach's hint level, scaffold level
/// and reflection type are never shown, so there is no place for them here.
class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.text,
    required this.kind,
    this.buddy,
  });

  final String text;
  final BubbleKind kind;

  /// The student's buddy, shown beside their own messages.
  final Buddy? buddy;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    final fromCoach = kind == BubbleKind.coach;

    final (Color bg, Color fg) = switch (kind) {
      BubbleKind.coach => (c.surfaceRaised, c.ink),
      BubbleKind.student => (c.primary, c.onPrimary),
      BubbleKind.unsent => (c.primarySoft, c.ink),
    };

    const big = Radius.circular(AppRadius.bubble);
    const tail = Radius.circular(AppRadius.bubbleTail);
    final shape = RoundedRectangleBorder(
      borderRadius: fromCoach
          ? const BorderRadius.only(
              topLeft: big,
              topRight: big,
              bottomRight: big,
              bottomLeft: tail,
            )
          : const BorderRadius.only(
              topLeft: big,
              topRight: big,
              bottomLeft: big,
              bottomRight: tail,
            ),
      side: kind == BubbleKind.unsent
          ? BorderSide(color: c.primary, width: 1.5)
          : BorderSide.none,
    );
    // A thin darker band under each bubble (the chunky look): grey under
    // the coach's, darker violet under the student's.
    final edge = switch (kind) {
      BubbleKind.coach => c.line,
      BubbleKind.student => c.primaryEdge,
      BubbleKind.unsent => Colors.transparent,
    };

    final who = fromCoach ? l10n.chatFromCoach : l10n.chatFromYou;
    final status = kind == BubbleKind.unsent ? '. ${l10n.chatNotSent}' : '';

    return Semantics(
      label: '$who: $text$status',
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (fromCoach) ...[
            const CoachAvatar(),
            const SizedBox(width: AppSpace.s2),
          ],
          Expanded(
            child: Align(
              alignment: fromCoach
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              child: FractionallySizedBox(
                widthFactor: 0.84,
                alignment: fromCoach
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                child: Align(
                  alignment: fromCoach
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.s4,
                      vertical: AppSpace.s3,
                    ),
                    decoration: ShapeDecoration(
                      color: bg,
                      shape: shape,
                      shadows: [
                        BoxShadow(color: edge, offset: const Offset(0, 3)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          text,
                          style: AppText.chat.copyWith(
                            color: fg,
                            fontWeight: fromCoach
                                ? FontWeight.w400
                                : FontWeight.w600,
                            fontVariations: [
                              FontVariation.weight(fromCoach ? 400 : 600),
                            ],
                          ),
                        ),
                        if (kind == BubbleKind.unsent) ...[
                          const SizedBox(height: AppSpace.s1),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              DuoIcon(
                                AppIcon.cloudOff,
                                size: 16,
                                color: c.primaryInk,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                l10n.chatNotSent,
                                style: AppText.help.copyWith(
                                  color: c.primaryInk,
                                  fontWeight: FontWeight.w600,
                                  fontVariations: const [
                                    FontVariation.weight(600),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (!fromCoach && buddy != null) ...[
            const SizedBox(width: AppSpace.s2),
            BuddyAvatar(buddy: buddy!),
          ],
        ],
      ),
    );
  }
}

/// Pip's small face in a soft circle, beside the coach's messages.
class CoachAvatar extends StatelessWidget {
  const CoachAvatar({super.key, this.mood = PipMood.idle});

  final PipMood mood;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return ExcludeSemantics(
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: mood == PipMood.thinking ? c.skySoft : c.lilacSoft,
          shape: BoxShape.circle,
        ),
        clipBehavior: Clip.antiAlias,
        alignment: Alignment.center,
        child: Pip(mood: mood, size: 40),
      ),
    );
  }
}
