import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/app_services.dart';
import '../services/chat_api.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_sizes.dart';
import '../theme/app_text.dart';
import '../widgets/appear.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/glass_surface.dart';
import '../widgets/maths_keys.dart';
import '../widgets/notice_card.dart';
import '../widgets/pill_button.dart';
import '../widgets/pip.dart';
import '../widgets/round_icon_button.dart';
import '../widgets/tap_surface.dart';
import '../utils/maths_text.dart';
import '../widgets/typing_dots.dart';

/// Screen 4: the chat with the coach, through `POST /chat`.
///
/// The coach speaks first. The whole history is sent every time (the
/// server keeps no memory). Only the coach's reply text is shown.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.eyebrow, required this.problem});

  /// For example "Problem 1 · Algebra · Grade 9".
  final String eyebrow;

  /// The problem text, sent to the coach on every call.
  final String problem;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

/// One message on screen.
class _Message {
  _Message(this.role, this.text);

  final ChatRole role;
  final String text;

  /// The student's message that could not be sent yet.
  bool unsent = false;
}

class _ChatScreenState extends State<ChatScreen> {
  final _messages = <_Message>[];
  final _input = TextEditingController();
  final _inputFocus = FocusNode();
  final _scroll = ScrollController();

  /// Height of the floating input bar (measured after layout).
  double _barHeight = 150;

  String? _code;
  String? _sessionId;
  bool _started = false;
  bool _waiting = false;
  bool _expanded = false;

  /// The last problem, shown as a notice with "Try again".
  ChatProblem? _problem;

  /// A small fix message under the box (too long, chat too long).
  String? _inputFix;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _openChat();
    }
  }

  @override
  void dispose() {
    _input.dispose();
    _inputFocus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// First call: empty history and no session, so the coach opens the chat.
  Future<void> _openChat() async {
    _code = await AppServices.of(context).auth.currentCode();
    if (!mounted) return;
    await _ask();
  }

  /// Everything said so far, in the server's format.
  List<ChatTurn> get _history => [
    for (final m in _messages) ChatTurn(m.role, m.text),
  ];

  /// Sends the conversation and waits for the coach.
  /// Also used by "Try again": it sends the very same request again.
  Future<void> _ask() async {
    setState(() {
      _waiting = true;
      _problem = null;
    });
    _scrollToEnd();

    final result = await AppServices.of(context).chat.send(
      problem: widget.problem,
      history: _history,
      studentId: _code,
      sessionId: _sessionId,
    );
    if (!mounted) return;

    setState(() {
      _waiting = false;
      final last = _messages.isEmpty ? null : _messages.last;
      switch (result) {
        case ChatReply(:final reply, :final sessionId):
          last?.unsent = false;
          _sessionId = sessionId ?? _sessionId;
          _messages.add(_Message(ChatRole.teacher, reply));
        case ChatFailure(:final problem):
          if (last?.role == ChatRole.student) last!.unsent = true;
          _problem = problem;
      }
    });
    _scrollToEnd();
  }

  void _send() {
    final l10n = AppLocalizations.of(context);
    final text = _input.text.trim();
    if (text.isEmpty || _waiting || _problem != null) return;

    if (text.length > maxMessageLength) {
      setState(() => _inputFix = l10n.chatMessageTooLong);
      return;
    }
    // The server takes at most 50 history items.
    if (_messages.length + 1 > maxHistoryItems) {
      setState(() => _inputFix = l10n.chatLimitReached);
      return;
    }

    setState(() {
      _inputFix = null;
      _messages.add(_Message(ChatRole.student, text));
      _input.clear();
    });
    _ask();
  }

  /// Types a maths key's text where the cursor is.
  void _insertKey(String text) {
    final value = _input.value;
    final sel = value.selection.isValid
        ? value.selection
        : TextSelection.collapsed(offset: value.text.length);
    _input.value = TextEditingValue(
      text: value.text.replaceRange(sel.start, sel.end, text),
      selection: TextSelection.collapsed(offset: sel.start + text.length),
    );
    _inputFocus.requestFocus();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final end = _scroll.position.maxScrollExtent;
      if (MediaQuery.disableAnimationsOf(context)) {
        _scroll.jumpTo(end);
      } else {
        _scroll.animateTo(
          end,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final mood = _waiting
        ? PipMood.thinking
        : _problem == ChatProblem.busy
        ? PipMood.sleepy
        : PipMood.idle;

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(
            eyebrow: widget.eyebrow,
            problem: widget.problem,
            mood: mood,
            expanded: _expanded,
            onToggle: () => setState(() => _expanded = !_expanded),
          ),
          Expanded(
            // The input bar floats over the bottom of the conversation, so
            // messages scroll softly underneath its glass.
            child: Stack(
              children: [
                Positioned.fill(
                  child: Semantics(
                    label: l10n.chatConversation,
                    container: true,
                    child: ListView(
                      controller: _scroll,
                      // Room at the bottom so the last message can scroll
                      // up above the floating bar.
                      padding: EdgeInsets.fromLTRB(
                        AppSpace.s4,
                        AppSpace.s4,
                        AppSpace.s4,
                        AppSpace.s4 + _barHeight,
                      ),
                      children: [
                        for (final m in _messages) ...[
                          // Each new bubble pops in once (the key stops it
                          // replaying when the list rebuilds).
                          Appear(
                            key: ObjectKey(m),
                            style: m.role == ChatRole.teacher
                                ? AppearStyle.popLeft
                                : AppearStyle.popRight,
                            child: ChatBubble(
                              // Coach maths like $x$ is shown as plain x (the
                              // original text is what goes back to the server).
                              text: m.role == ChatRole.teacher
                                  ? readableMaths(m.text)
                                  : m.text,
                              kind: m.role == ChatRole.teacher
                                  ? BubbleKind.coach
                                  : m.unsent
                                  ? BubbleKind.unsent
                                  : BubbleKind.student,
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                        if (_waiting)
                          const Appear(
                            style: AppearStyle.popLeft,
                            child: TypingDots(),
                          ),
                        if (_problem != null)
                          Appear(
                            key: ValueKey(_problem),
                            style: AppearStyle.drop,
                            child: _ProblemNotice(
                              problem: _problem!,
                              onRetry: _ask,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _MeasureHeight(
                    onHeight: (h) {
                      if (h != _barHeight) setState(() => _barHeight = h);
                    },
                    child: _InputBar(
                      controller: _input,
                      focusNode: _inputFocus,
                      canSend: !_waiting && _problem == null,
                      fixMessage: _inputFix,
                      onKey: _insertKey,
                      onSend: _send,
                    ),
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

/// Tells its parent how tall [child] is after each layout, so the
/// conversation can leave room for the floating input bar.
class _MeasureHeight extends StatefulWidget {
  const _MeasureHeight({required this.child, required this.onHeight});

  final Widget child;
  final ValueChanged<double> onHeight;

  @override
  State<_MeasureHeight> createState() => _MeasureHeightState();
}

class _MeasureHeightState extends State<_MeasureHeight> {
  final _key = GlobalKey();

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final box = _key.currentContext?.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) widget.onHeight(box.size.height);
    });
    return KeyedSubtree(key: _key, child: widget.child);
  }
}

/// The teal header: Back, Pip, the coach's name and the pinned problem.
class _Header extends StatelessWidget {
  const _Header({
    required this.eyebrow,
    required this.problem,
    required this.mood,
    required this.expanded,
    required this.onToggle,
  });

  final String eyebrow;
  final String problem;
  final PipMood mood;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: c.teal,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  RoundIconButton(
                    icon: Icons.arrow_back_rounded,
                    semanticLabel: l10n.chatBack,
                    tone: RoundIconTone.light,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: c.tealSoft,
                      shape: BoxShape.circle,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Pip(mood: mood, size: 52),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(
                            l10n.chatCoachTitle,
                            style: AppText.title.copyWith(
                              color: c.onTeal,
                              fontSize: 19,
                            ),
                          ),
                        ),
                        Text(
                          l10n.chatCoachSubtitle,
                          style: AppText.caption.copyWith(
                            color: c.onTeal,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.s3),
              // The pinned problem. Tap to show the whole text.
              Semantics(
                button: true,
                expanded: expanded,
                hint: l10n.chatToggleProblem,
                child: TapSurface(
                  onTap: onToggle,
                  color: c.surfaceRaised,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 56),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  eyebrow.toUpperCase(),
                                  style: AppText.eyebrow.copyWith(
                                    color: c.tealInk,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                // Grows open smoothly to show the whole
                                // problem (one small size animation).
                                AnimatedSize(
                                  duration: AppMotion.of(
                                    context,
                                    AppMotion.medium,
                                  ),
                                  curve: AppMotion.ease,
                                  alignment: Alignment.topLeft,
                                  child: Text(
                                    problem,
                                    maxLines: expanded ? null : 1,
                                    overflow: expanded
                                        ? TextOverflow.visible
                                        : TextOverflow.ellipsis,
                                    style: AppText.title.copyWith(color: c.ink),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            // The arrow turns to point up when open.
                            child: AnimatedRotation(
                              turns: expanded ? 0.5 : 0,
                              duration: AppMotion.of(context, AppMotion.medium),
                              curve: AppMotion.ease,
                              child: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: c.ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The mustard notice for busy / something went wrong / no internet.
class _ProblemNotice extends StatelessWidget {
  const _ProblemNotice({required this.problem, required this.onRetry});

  final ChatProblem problem;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (IconData icon, String title, String text) = switch (problem) {
      ChatProblem.busy => (
        Icons.schedule_rounded,
        l10n.chatBusyTitle,
        l10n.chatBusyText,
      ),
      ChatProblem.failed => (
        Icons.error_outline_rounded,
        l10n.chatErrorTitle,
        l10n.chatErrorText,
      ),
      ChatProblem.offline => (
        Icons.wifi_off_rounded,
        l10n.chatOfflineTitle,
        l10n.chatOfflineText,
      ),
    };

    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.s1),
      child: NoticeCard(
        icon: icon,
        title: title,
        text: text,
        action: PillButton(label: l10n.tryAgain, onPressed: onRetry),
      ),
    );
  }
}

/// The white bar at the bottom: maths keys, the message box and Send.
class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.canSend,
    required this.fixMessage,
    required this.onKey,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool canSend;
  final String? fixMessage;
  final ValueChanged<String> onKey;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);

    // Light frosted glass over the end of the conversation, but plain
    // solid white while the student is typing. The emulator test showed
    // the blur is about 6x heavier then, and with the keyboard open nobody
    // can see through the bar anyway.
    return ListenableBuilder(
      listenable: focusNode,
      builder: (context, child) => GlassSurface(
        blur: !focusNode.hasFocus,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: child!,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 10, bottom: AppSpace.s4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MathsKeyRow(onKey: onKey),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.s3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Semantics(
                        label: l10n.chatMessageLabel,
                        child: TextField(
                          controller: controller,
                          focusNode: focusNode,
                          minLines: 1,
                          maxLines: 3,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => onSend(),
                          style: AppText.chat.copyWith(
                            color: c.ink,
                            height: 24 / 17,
                          ),
                          cursorColor: c.ink,
                          decoration: InputDecoration(
                            hintText: l10n.chatMessageHint,
                            filled: true,
                            fillColor: c.surface,
                            constraints: const BoxConstraints(
                              minHeight: AppSizes.tap,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(
                                color: c.fieldLine,
                                width: 1.5,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(
                                color: c.fieldLine,
                                width: 1.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(color: c.ink, width: 2),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpace.s2),
                    RoundIconButton(
                      icon: Icons.arrow_forward_rounded,
                      semanticLabel: l10n.chatSend,
                      tone: RoundIconTone.dark,
                      size: AppSizes.send,
                      onPressed: canSend ? onSend : null,
                    ),
                  ],
                ),
              ),
              if (fixMessage != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpace.s4,
                    6,
                    AppSpace.s4,
                    0,
                  ),
                  child: Semantics(
                    liveRegion: true,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 18,
                          color: c.mustardInk,
                        ),
                        const SizedBox(width: AppSpace.s2),
                        Expanded(
                          child: Text(
                            fixMessage!,
                            style: AppText.help.copyWith(color: c.mustardInk),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
