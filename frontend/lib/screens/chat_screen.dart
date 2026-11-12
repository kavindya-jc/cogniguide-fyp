import 'dart:async';

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
import '../widgets/duo_icon.dart';
import '../widgets/measure_height.dart';
import '../widgets/soft_blobs.dart';
import '../widgets/status_bar_fade.dart';
import 'login_screen.dart';
import 'moment_screen.dart';

/// Screen 4: the chat with the coach, through `POST /chat`.
///
/// The coach speaks first. The whole history is sent every time (the
/// server keeps no memory). Only the coach's reply text is shown.
class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.eyebrow,
    required this.problem,
    this.problemId,
    this.sessionId,
    this.history = const [],
  });

  /// For example "Problem 1 · Algebra · Grade 9".
  final String eyebrow;

  /// The problem text, sent to the coach on every call.
  final String problem;

  /// The id of a problem from the list (for example "alg-9-1"), so the coach
  /// can check the student's answer against its answer sheet. Null for a
  /// problem the student typed in themselves.
  final String? problemId;

  /// An old chat from Recent chats: its session and its messages so far.
  /// The student carries on where they left off (the coach does not open
  /// the chat again).
  final String? sessionId;
  final List<ChatTurn> history;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

/// One message on screen.
class _Message {
  _Message(this.role, this.text, {this.old = false});

  final ChatRole role;
  final String text;

  /// From an old chat: shown at once, with no pop-in. Up to 200 bubbles
  /// popping in together would stutter on a cheap phone.
  final bool old;

  /// The student's message that could not be sent yet.
  bool unsent = false;
}

/// How far down the chat starts, below the safe area: room for the two
/// floating round buttons (44) and a little air.
const double _floatingTop = AppSpace.s2 + AppSizes.tap + AppSpace.s3;

class _ChatScreenState extends State<ChatScreen> {
  final _messages = <_Message>[];
  final _input = TextEditingController();
  final _inputFocus = FocusNode();
  final _scroll = ScrollController();

  /// Heights of the floating glass header and input bar (measured after
  /// layout), so the conversation can scroll underneath both.
  double _barHeight = 150;

  String? _code;
  String? _sessionId;
  bool _started = false;

  /// The server was told this chat is over (see [_endSession]).
  bool _ended = false;
  AppServices? _services;
  bool _waiting = false;

  /// The last problem, shown as a notice with "Try again".
  ChatProblem? _problem;

  /// A small fix message under the box (too long, chat too long).
  String? _inputFix;

  /// How long the student has been in this chat (for "Minutes thinking").
  final _time = Stopwatch()..start();

  int get _studentMessages =>
      _messages.where((m) => m.role == ChatRole.student).length;

  /// "I worked it out!": the celebration, with numbers the app knows.
  void _workedItOut() {
    _endSession('worked_it_out');
    final minutes = (_time.elapsed.inSeconds / 60).ceil().clamp(1, 999);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) =>
            MomentScreen(messages: _studentMessages, minutes: minutes),
      ),
    );
  }

  /// Tells the server the chat is over ("worked_it_out" or "left"), once.
  /// Research data only: it runs in the background and never shows an error.
  void _endSession(String reason) {
    final services = _services;
    final sessionId = _sessionId;
    if (_ended || services == null || sessionId == null) return;
    _ended = true;
    unawaited(() async {
      final token = await services.auth.token();
      await services.chat.endSession(
        sessionId: sessionId,
        reason: reason,
        token: token,
      );
    }());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _services = AppServices.of(context);
    if (!_started) {
      _started = true;
      _openChat();
    }
  }

  @override
  void dispose() {
    _endSession('left'); // does nothing after "I worked it out!"
    _input.dispose();
    _inputFocus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// First call: empty history and no session, so the coach opens the chat.
  /// An old chat shows its messages and waits for the student instead.
  Future<void> _openChat() async {
    _code = await AppServices.of(context).auth.currentCode();
    if (!mounted) return;
    if (widget.history.isNotEmpty) {
      setState(() {
        _sessionId = widget.sessionId;
        _messages.addAll([
          for (final t in widget.history)
            _Message(t.role, t.content, old: true),
        ]);
      });
      _scrollToEnd();
      return;
    }
    _sessionId = widget.sessionId;
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

    final services = AppServices.of(context);
    final result = await services.chat.send(
      problem: widget.problem,
      problemId: widget.problemId,
      history: _history,
      studentId: _code,
      sessionId: _sessionId,
      token: await services.auth.token(),
    );
    if (!mounted) return;
    if (result case ChatFailure(problem: ChatProblem.loginExpired)) {
      await sendBackToLogin(context);
      return;
    }

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

  Widget _bubble(_Message m) => ChatBubble(
    // Coach maths like $x$ is shown as plain x (the original text is what
    // goes back to the server).
    text: m.role == ChatRole.teacher ? readableMaths(m.text) : m.text,
    kind: m.role == ChatRole.teacher
        ? BubbleKind.coach
        : m.unsent
        ? BubbleKind.unsent
        : BubbleKind.student,
    buddy: AppServices.of(context).settings.buddyOrFallback,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final mood = _waiting
        ? PipMood.thinking
        : _problem == ChatProblem.busy
        ? PipMood.sleepy
        : PipMood.idle;

    return Scaffold(
      // The conversation scrolls underneath the floating glass header and
      // the floating input bar. Only these two are glass (the blur limit).
      body: Stack(
        children: [
          const Positioned.fill(child: SoftBlobs()),
          Positioned.fill(
            child: Semantics(
              label: l10n.chatConversation,
              container: true,
              child: ListView(
                controller: _scroll,
                // Room above for the two floating buttons, and below so the
                // last message can scroll clear of the input bar.
                padding: EdgeInsets.fromLTRB(
                  AppSpace.s4,
                  MediaQuery.paddingOf(context).top + _floatingTop,
                  AppSpace.s4,
                  AppSpace.s4 + _barHeight,
                ),
                children: [
                  // Who you talk to and the problem: the first card of the
                  // chat, so it scrolls away and the chat gets the screen.
                  _ProblemCard(
                    eyebrow: widget.eyebrow,
                    problem: widget.problem,
                    mood: mood,
                  ),
                  const SizedBox(height: AppSpace.s5),
                  for (final m in _messages) ...[
                    // Each new bubble pops in once (the key stops it
                    // replaying when the list rebuilds). Old ones do not.
                    if (m.old)
                      KeyedSubtree(key: ObjectKey(m), child: _bubble(m))
                    else
                      Appear(
                        key: ObjectKey(m),
                        style: m.role == ChatRole.teacher
                            ? AppearStyle.popLeft
                            : AppearStyle.popRight,
                        child: _bubble(m),
                      ),
                    const SizedBox(height: 14),
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
                      child: _ProblemNotice(problem: _problem!, onRetry: _ask),
                    ),
                ],
              ),
            ),
          ),
          // The page colour behind the phone's clock, so messages do not
          // show through there when they scroll up.
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(child: StatusBarFade()),
          ),
          // Two small floating buttons instead of a top bar (team request):
          // Back, and the problem in a sheet. Solid, not glass, so the only
          // blur on this screen is the input bar.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.s3,
                  AppSpace.s2,
                  AppSpace.s3,
                  0,
                ),
                child: Row(
                  children: [
                    RoundIconButton(
                      icon: AppIcon.back,
                      semanticLabel: l10n.chatBack,
                      tone: RoundIconTone.glass,
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    const Spacer(),
                    RoundIconButton(
                      icon: AppIcon.book,
                      semanticLabel: l10n.chatShowProblem,
                      tone: RoundIconTone.glass,
                      onPressed: () => _showProblemSheet(
                        context,
                        eyebrow: widget.eyebrow,
                        problem: widget.problem,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: MeasureHeight(
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
                // Only once the student has said something.
                onWorkedItOut: _studentMessages > 0 ? _workedItOut : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The first card of the chat: Pip (with the coach's mood), the coach's
/// name, and the whole problem on a soft lilac card. It scrolls with the
/// chat, so the conversation gets the whole screen (team request).
///
/// Not glass (it scrolls), so nothing here redraws a blur.
class _ProblemCard extends StatelessWidget {
  const _ProblemCard({
    required this.eyebrow,
    required this.problem,
    required this.mood,
  });

  final String eyebrow;
  final String problem;
  final PipMood mood;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: c.surfaceRaised,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: mood == PipMood.thinking ? c.skySoft : c.lilacSoft,
                  shape: BoxShape.circle,
                ),
                clipBehavior: Clip.antiAlias,
                alignment: Alignment.center,
                child: Pip(mood: mood, size: 54),
              ),
              const SizedBox(width: AppSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        l10n.chatCoachTitle,
                        style: AppText.h2.copyWith(
                          color: c.ink,
                          fontSize: 19,
                          height: 24 / 19,
                        ),
                      ),
                    ),
                    Text(
                      l10n.chatCoachSubtitle,
                      style: AppText.caption.copyWith(
                        color: c.inkMuted,
                        fontSize: 14,
                        height: 18 / 14,
                        fontWeight: FontWeight.w600,
                        fontVariations: const [FontVariation('wght', 600)],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.s3),
          _ProblemText(eyebrow: eyebrow, problem: problem),
        ],
      ),
    );
  }
}

/// The eyebrow and the whole problem on a soft lilac card.
class _ProblemText extends StatelessWidget {
  const _ProblemText({required this.eyebrow, required this.problem});

  final String eyebrow;
  final String problem;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: c.lilacSoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow,
            style: AppText.caption.copyWith(
              color: c.lilacInk,
              fontWeight: FontWeight.w700,
              fontVariations: const [FontVariation('wght', 700)],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            problem,
            style: AppText.title.copyWith(
              color: c.ink,
              fontWeight: FontWeight.w700,
              fontVariations: const [FontVariation('wght', 700)],
            ),
          ),
        ],
      ),
    );
  }
}

/// The floating Problem button's sheet: the whole problem, any time, even
/// when the first card has scrolled away. A plain solid sheet (no blur).
Future<void> _showProblemSheet(
  BuildContext context, {
  required String eyebrow,
  required String problem,
}) {
  final c = AppColors.of(context);
  final l10n = AppLocalizations.of(context);
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: c.surfaceRaised,
    barrierColor: c.night.withValues(alpha: 0.3),
    constraints: const BoxConstraints(maxWidth: 480),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    sheetAnimationStyle: AppMotion.reduced(context)
        ? AnimationStyle.noAnimation
        : null,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.screen,
          AppSpace.s5,
          AppSpace.screen,
          AppSpace.s4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                l10n.chatProblemSheetTitle,
                style: AppText.h2.copyWith(color: c.ink),
              ),
            ),
            const SizedBox(height: AppSpace.s3),
            _ProblemText(eyebrow: eyebrow, problem: problem),
            const SizedBox(height: AppSpace.s5),
            PillButton(
              label: l10n.chatProblemSheetClose,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    ),
  );
}

/// The butter notice for busy / something went wrong / no internet.
class _ProblemNotice extends StatelessWidget {
  const _ProblemNotice({required this.problem, required this.onRetry});

  final ChatProblem problem;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (AppIcon icon, String title, String text) = switch (problem) {
      ChatProblem.busy => (
        AppIcon.clock,
        l10n.chatBusyTitle,
        l10n.chatBusyText,
      ),
      ChatProblem.failed || ChatProblem.loginExpired => (
        AppIcon.alert,
        l10n.chatErrorTitle,
        l10n.chatErrorText,
      ),
      ChatProblem.offline => (
        AppIcon.wifiOff,
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

/// The bottom of the chat: a row of chunky maths keys, then a floating
/// glass pill with the message box and the violet Send button.
class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.canSend,
    required this.fixMessage,
    required this.onKey,
    required this.onSend,
    required this.onWorkedItOut,
  });

  final TextEditingController controller;
  final FocusNode focusNode;

  /// Opens the celebration. Null hides the button (nothing said yet).
  final VoidCallback? onWorkedItOut;
  final bool canSend;
  final String? fixMessage;
  final ValueChanged<String> onKey;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);

    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(24),
      borderSide: BorderSide(color: c.fieldLine, width: 1.5),
    );

    final pill = Padding(
      padding: const EdgeInsets.all(AppSpace.s2),
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
                style: AppText.chat.copyWith(color: c.ink, height: 24 / 17),
                cursorColor: c.ink,
                decoration: InputDecoration(
                  hintText: l10n.chatMessageHint,
                  filled: true,
                  fillColor: c.surfaceRaised,
                  constraints: const BoxConstraints(minHeight: AppSizes.send),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  border: fieldBorder,
                  enabledBorder: fieldBorder,
                  focusedBorder: fieldBorder.copyWith(
                    borderSide: BorderSide(color: c.ink, width: 2),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpace.s2),
          RoundIconButton(
            icon: AppIcon.send,
            semanticLabel: l10n.chatSend,
            tone: RoundIconTone.primary,
            size: AppSizes.send,
            onPressed: canSend ? onSend : null,
          ),
        ],
      ),
    );

    // A soft fade from see-through to the page colour behind the buttons, so
    // messages that scroll under them fade away instead of showing through
    // the gaps between the keys (phone test, 9 Nov). A plain gradient, not a
    // blur, so it costs almost nothing on low-end phones.
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            c.surface.withValues(alpha: 0),
            c.surface.withValues(alpha: 0.94),
            c.surface,
          ],
          stops: const [0, 0.22, 1],
        ),
      ),
      child: _content(context, c, l10n, pill),
    );
  }

  Widget _content(
    BuildContext context,
    AppColors c,
    AppLocalizations l10n,
    Widget pill,
  ) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, AppSpace.s5, 0, AppSpace.s3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (onWorkedItOut != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, AppSpace.s2),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _WorkedItOutButton(onTap: onWorkedItOut!),
                ),
              ),
            MathsKeyRow(onKey: onKey),
            const SizedBox(height: AppSpace.s2),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              // See-through liquid glass over the end of the conversation,
              // but plain solid while the student is typing: the emulator
              // test showed the blur is about 6x heavier then, and with the
              // keyboard open nobody can see through the bar anyway.
              child: ListenableBuilder(
                listenable: focusNode,
                builder: (context, child) => GlassSurface(
                  tone: GlassTone.clear,
                  blur: !focusNode.hasFocus,
                  borderRadius: BorderRadius.circular(32),
                  child: child!,
                ),
                child: pill,
              ),
            ),
            if (fixMessage != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.s5,
                  6,
                  AppSpace.s5,
                  0,
                ),
                child: Semantics(
                  liveRegion: true,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DuoIcon(AppIcon.alert, size: 18, color: c.butterInk),
                      const SizedBox(width: AppSpace.s2),
                      Expanded(
                        child: Text(
                          fixMessage!,
                          style: AppText.help.copyWith(color: c.butterInk),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// "I worked it out!": a friendly butter pill above the maths keys.
class _WorkedItOutButton extends StatelessWidget {
  const _WorkedItOutButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);

    return Semantics(
      button: true,
      label: l10n.chatWorkedItOut,
      excludeSemantics: true,
      child: TapSurface(
        onTap: onTap,
        color: c.butterSoft,
        shape: StadiumBorder(side: BorderSide(color: c.butter, width: 2)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.tap),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.s4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                DuoIcon(AppIcon.star, size: 20, color: c.butterInk),
                const SizedBox(width: AppSpace.s2),
                Text(
                  l10n.chatWorkedItOut,
                  style: AppText.label.copyWith(
                    color: c.butterInk,
                    fontWeight: FontWeight.w800,
                    fontVariations: const [FontVariation('wght', 800)],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
