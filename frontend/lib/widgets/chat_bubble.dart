import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import '../theme/app_text.dart';

/// Who a chat bubble is from.
enum BubbleKind {
  /// The coach's reply: white, on the left.
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
  const ChatBubble({super.key, required this.text, required this.kind});

  final String text;
  final BubbleKind kind;

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

    final who = fromCoach ? l10n.chatFromCoach : l10n.chatFromYou;
    final status = kind == BubbleKind.unsent ? '. ${l10n.chatNotSent}' : '';

    return Semantics(
      label: '$who: $text$status',
      excludeSemantics: true,
      child: Align(
        alignment: fromCoach ? Alignment.centerLeft : Alignment.centerRight,
        child: FractionallySizedBox(
          widthFactor: 0.84,
          alignment: fromCoach ? Alignment.centerLeft : Alignment.centerRight,
          child: Align(
            alignment: fromCoach ? Alignment.centerLeft : Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.s4,
                vertical: AppSpace.s3,
              ),
              decoration: ShapeDecoration(color: bg, shape: shape),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(text, style: AppText.chat.copyWith(color: fg)),
                  if (kind == BubbleKind.unsent) ...[
                    const SizedBox(height: AppSpace.s1),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.cloud_off_rounded,
                          size: 16,
                          color: c.primaryInk,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          l10n.chatNotSent,
                          style: AppText.help.copyWith(
                            color: c.primaryInk,
                            fontWeight: FontWeight.w600,
                            fontVariations: const [FontVariation.weight(600)],
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
    );
  }
}
