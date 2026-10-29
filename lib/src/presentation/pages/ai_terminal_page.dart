import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/index.dart';
import '../providers/app_providers.dart';

class AiTerminalPage extends ConsumerStatefulWidget {
  const AiTerminalPage({super.key});

  @override
  ConsumerState<AiTerminalPage> createState() => _AiTerminalPageState();
}

class _AiTerminalPageState extends ConsumerState<AiTerminalPage> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<TerminalMessage> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _loadInitialMessages();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadInitialMessages() {
    _messages.addAll([
      TerminalMessage(
        type: MessageType.overclock,
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        content: 'Operational surge verified. You completed 3 Physical Sessions today. Cortical synapse efficiency overclocked by +12%.',
        badge: const BadgeInfo(
          name: 'Thunder Strike III',
          description: '+150 Bonus Wattage EXP',
          iconColor: AppColors.highVoltageYellow,
        ),
      ),
      TerminalMessage(
        type: MessageType.quest,
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
        title: 'EMERGENCY PROTOCOL: DEEP CODE RUN',
        content: 'Neural activity indicates high neuroplastic focus. Complete 45 minutes of undisturbed architecture engineering.',
        questRank: 'B-RANK',
        timeRemaining: const Duration(hours: 3, minutes: 41, seconds: 58),
        rewards: const [
          QuestReward(icon: Icons.bolt, label: '+120 EXP', color: AppColors.electricCyan),
          QuestReward(icon: Icons.military_tech, label: "'Code Weaver' Title", color: AppColors.electricViolet),
          QuestReward(icon: Icons.battery_charging_full, label: 'Core Cell +1', color: AppColors.highVoltageYellow),
        ],
      ),
      TerminalMessage(
        type: MessageType.insight,
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        content: 'Willpower Index is down -4% compared to the previous cycle. Micro-stress spikes registered during multi-tasking.',
        advice: '15m CORTEX RESET REBOOT',
        adviceColor: AppColors.electricViolet,
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            Container(
              height: 72,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow.withOpacity(0.8),
                border: Border(bottom: BorderSide(color: AppColors.brushedMetallicTrim, width: 0.5)),
              ),
              child: Row(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(gradient: AppColors.cyanGlowGradient, border: Border.all(color: AppColors.electricCyan, width: 1)),
                        child: const Icon(Icons.bolt, color: AppColors.coreVoid, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('PERSONAL LIFE RPG', style: AppTextStyles.labelSmallUpper.copyWith(color: AppColors.electricCyan)),
                          Text('AI Terminal', style: AppTextStyles.headlineSmall),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.surfaceContainerHigh, border: Border.all(color: AppColors.brushedMetallicTrim, width: 1)),
                    child: Row(children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.highVoltageYellow, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text('LVL 28 • CYBER_RUNNER', style: AppTextStyles.labelSmallUpper.copyWith(color: AppColors.highVoltageYellow)),
                    ]),
                  ),
                  const SizedBox(width: 12),
                  Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.surfaceContainerHigh, border: Border.all(color: AppColors.brushedMetallicTrim, width: 1)), child: IconButton(icon: const Icon(Icons.home, color: AppColors.electricCyan, size: 22), onPressed: () {})),
                ],
              ),
            ),
            // Terminal Header
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                border: Border.all(color: AppColors.brushedMetallicTrim, width: 1),
                boxShadow: AppColors.cardElevation,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.electricCyan, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Text('NEURAL AI // A.E.G.I.S. v4.09', style: AppTextStyles.labelSmallUpper.copyWith(color: AppColors.electricCyan)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.surfaceContainerHigh, border: Border.all(color: AppColors.brushedMetallicTrim, width: 1)),
                        child: Text('COHERENCE: 99.4%', style: AppTextStyles.labelSmallUpper.copyWith(color: AppColors.highVoltageYellow)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, border: Border.all(color: AppColors.brushedMetallicTrim, width: 1)),
                    child: Column(
                      children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Row(children: [const Icon(Icons.hub, color: AppColors.electricCyan, size: 14), const SizedBox(width: 6), Text('DIRECT SYNAPSE LINK', style: AppTextStyles.labelSmallUpper)]),
                          Text('CH-08 ACTIVE', style: AppTextStyles.labelSmallUpper.copyWith(color: AppColors.electricCyan)),
                        ]),
                        const SizedBox(height: 8),
                        // Waveform
                        SizedBox(
                          height: 24,
                          child: CustomPaint(
                            painter: _WaveformPainter(),
                            size: const Size(double.infinity, 24),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Message Feed
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _messages.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length && _isTyping) {
                    return _buildTypingIndicator();
                  }
                  return _buildMessage(_messages[index]);
                },
              ),
            ),
            // Input Panel
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow.withOpacity(0.85),
                border: Border(top: BorderSide(color: AppColors.brushedMetallicTrim, width: 1)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Row(children: [Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.highVoltageYellow, shape: BoxShape.circle)), const SizedBox(width: 8), Text('DIRECT COGNITIVE UPLINK', style: AppTextStyles.labelSmallUpper)]),
                      const Spacer(),
                      Text('BUFF: FOCUS_BURST ACTIVE', style: AppTextStyles.labelSmallUpper.copyWith(color: AppColors.electricCyan)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: AppColors.surfaceContainerHigh, border: Border.all(color: AppColors.brushedMetallicTrim, width: 1)),
                        child: const Icon(Icons.terminal, color: AppColors.electricCyan, size: 18),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _inputController,
                          style: AppTextStyles.labelMedium.copyWith(color: AppColors.onSurface),
                          decoration: InputDecoration(
                            hintText: '> Query agent or report telemetry...',
                            hintStyle: AppTextStyles.labelMedium.copyWith(color: AppColors.outlineVariant),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onSubmitted: _sendMessage,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.surfaceContainerHigh, border: Border.all(color: AppColors.brushedMetallicTrim, width: 1)), child: IconButton(icon: const Icon(Icons.mic, color: AppColors.onSurfaceVariant, size: 18), onPressed: () {})),
                      const SizedBox(width: 8),
                      Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.electricCyan, border: Border.all(color: AppColors.electricCyan, width: 1)), child: IconButton(icon: const Icon(Icons.send, color: AppColors.coreVoid, size: 18), onPressed: () => _sendMessage(_inputController.text))),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage(TerminalMessage message) {
    switch (message.type) {
      case MessageType.overclock:
        return _OverclockMessage(message: message);
      case MessageType.quest:
        return _QuestMessage(message: message, onAccept: () {}, onPostpone: () {});
      case MessageType.insight:
        return _InsightMessage(message: message);
      case MessageType.user:
        return _UserMessage(message: message);
      case MessageType.ai:
        return _AiMessage(message: message);
    }
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        border: Border.all(color: AppColors.brushedMetallicTrim, width: 1),
      ),
      child: Row(
        children: [
          _PulsingDot(),
          const SizedBox(width: 4),
          _PulsingDot(delay: 200),
          const SizedBox(width: 4),
          _PulsingDot(delay: 400),
          const SizedBox(width: 12),
          Text('A.E.G.I.S. COMPUTING', style: AppTextStyles.labelSmallUpper.copyWith(color: AppColors.electricCyan)),
        ],
      ),
    );
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    
    setState(() {
      _messages.add(TerminalMessage(
        type: MessageType.user,
        timestamp: DateTime.now(),
        content: text,
      ));
      _inputController.clear();
      _isTyping = true;
    });
    
    _scrollToBottom();
    
    // Simulate AI response
    Future.delayed(const Duration(seconds: 1), () {
      final responses = [
        "Affirmative, Operator. Recalibrating biometric thresholds to preserve cognitive stamina.",
        "Neural thread synched. Adding +25 EXP to Professional Skill telemetry.",
        "Diagnostics green. Keep executing at this pace to lock in the 'Overclock' multiplier.",
        "Cortical pathways optimized. Recommend initiating Deep Work protocol for maximum yield.",
      ];
      
      setState(() {
        _isTyping = false;
        _messages.add(TerminalMessage(
          type: MessageType.ai,
          timestamp: DateTime.now(),
          content: responses[DateTime.now().millisecond % responses.length],
        ));
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}

class _PulsingDot extends StatefulWidget {
  final int delay;
  const _PulsingDot({this.delay = 0});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 600), vsync: this)..repeat(reverse: true);
    Future.delayed(Duration(milliseconds: widget.delay), () { if (mounted) _controller.forward(); });
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => Container(width: 8, height: 8, decoration: BoxDecoration(color: AppColors.electricCyan.withOpacity(0.3 + 0.7 * _controller.value), shape: BoxShape.circle)),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.electricCyan..style = PaintingStyle.stroke..strokeWidth = 1.5..strokeCap = StrokeCap.round;
    final path = Path();
    final width = size.width;
    final height = size.height;
    final midY = height / 2;
    
    for (double x = 0; x <= width; x += 4) {
      final y = midY + (x % 60 < 30 ? 8 : -8) * (0.5 + 0.5 * (x / width));
      if (x == 0) path.moveTo(x, y);
      else path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Message data classes
enum MessageType { overclock, quest, insight, user, ai }

class BadgeInfo {
  final String name;
  final String description;
  final Color iconColor;
  const BadgeInfo({required this.name, required this.description, required this.iconColor});
}

class QuestReward {
  final IconData icon;
  final String label;
  final Color color;
  const QuestReward({required this.icon, required this.label, required this.color});
}

class TerminalMessage {
  final MessageType type;
  final DateTime timestamp;
  final String? title;
  final String content;
  final BadgeInfo? badge;
  final String? questRank;
  final Duration? timeRemaining;
  final List<QuestReward>? rewards;
  final String? advice;
  final Color? adviceColor;

  TerminalMessage({
    required this.type,
    required this.timestamp,
    this.title,
    required this.content,
    this.badge,
    this.questRank,
    this.timeRemaining,
    this.rewards,
    this.advice,
    this.adviceColor,
  });
}

// Message Widgets
class _OverclockMessage extends StatelessWidget {
  final TerminalMessage message;
  const _OverclockMessage({required this.message});

  @override Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.surfaceContainerHigh, border: Border.all(color: AppColors.brushedMetallicTrim, width: 1), boxShadow: AppColors.cardElevation), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [const Icon(Icons.bolt, color: AppColors.highVoltageYellow, size: 16), const SizedBox(width: 8), Text('// OVERCLOCK DETECTED', style: AppTextStyles.labelSmallUpper.copyWith(color: AppColors.highVoltageYellow)), const Spacer(), Text(_formatTime(message.timestamp), style: AppTextStyles.labelSmall.copyWith(color: AppColors.onSurfaceVariant))]),
    const SizedBox(height: 8),
    Text(message.content, style: AppTextStyles.bodyMedium),
    if (message.badge != null) ...[const SizedBox(height: 12), _buildBadge(message.badge!)],
  ]));

  String _formatTime(DateTime t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')} UTC';

  Widget _buildBadge(BadgeInfo badge) => Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, border: Border.all(color: AppColors.brushedMetallicTrim, width: 1)), child: Row(children: [
    Container(width: 48, height: 48, decoration: BoxDecoration(color: AppColors.surfaceContainerHigh, border: Border.all(color: badge.iconColor, width: 1), boxShadow: [BoxShadow(color: badge.iconColor.withOpacity(0.3), blurRadius: 12)]), child: const Icon(Icons.bolt, size: 24)),
    const SizedBox(width: 12),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('BADGE UNLOCKED', style: AppTextStyles.labelSmallUpper.copyWith(color: AppColors.highVoltageYellow)),
      Text(badge.name, style: AppTextStyles.headlineSmall.copyWith(color: badge.iconColor)),
      Text(badge.description, style: AppTextStyles.labelSmall.copyWith(color: AppColors.onSurfaceVariant)),
    ])),
    Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: AppColors.surfaceVariant, border: Border.all(color: AppColors.electricCyan, width: 1)), child: const Icon(Icons.verified, color: AppColors.electricCyan, size: 18)),
  ]));
}

class _QuestMessage extends StatelessWidget {
  final TerminalMessage message;
  final VoidCallback onAccept;
  final VoidCallback onPostpone;
  const _QuestMessage({required this.message, required this.onAccept, required this.onPostpone});

  @override Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.surfaceContainerHigh, border: Border.all(color: AppColors.brushedMetallicTrim, width: 1), boxShadow: AppColors.cardElevation), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [const Icon(Icons.priority_high, color: AppColors.electricCyan, size: 16), const SizedBox(width: 8), Text('// SPONTANEOUS QUEST ALERT', style: AppTextStyles.labelSmallUpper.copyWith(color: AppColors.electricCyan)), const Spacer(), Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: AppColors.overloadCrimson.withOpacity(0.2), border: Border.all(color: AppColors.overloadCrimson, width: 1)), child: Text(message.questRank ?? 'B-RANK', style: AppTextStyles.labelSmallUpper.copyWith(color: AppColors.overloadCrimson)))]),
    const SizedBox(height: 8),
    if (message.title != null) Text(message.title!, style: AppTextStyles.headlineSmall),
    const SizedBox(height: 8),
    Text(message.content, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.onSurfaceVariant)),
    const SizedBox(height: 12),
    Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, border: Border.all(color: AppColors.brushedMetallicTrim, width: 1)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(children: [const Icon(Icons.timer, color: AppColors.highVoltageYellow, size: 14), const SizedBox(width: 6), Text('EXPIRATION WINDOW', style: AppTextStyles.labelSmallUpper)]),
        Text(message.timeRemaining != null ? _formatDuration(message.timeRemaining!) : '00:00:00', style: AppTextStyles.hudMetricSmall.copyWith(color: AppColors.highVoltageYellow, fontSize: 16)),
      ]),
      const SizedBox(height: 12),
      Row(children: [Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: AppColors.surfaceContainerHigh, border: Border.all(color: AppColors.electricCyan, width: 1)), child: Text('PROJECTED LOOT REWARDS', style: AppTextStyles.labelSmallUpper.copyWith(color: AppColors.electricCyan)))]),
      const SizedBox(height: 8),
      Wrap(
          spacing: 8,
          runSpacing: 8,
          children: (message.rewards ?? []).map<Widget>((r) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHighest,
              border: Border.all(color: r.color, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(r.icon, size: 12, color: r.color),
                const SizedBox(width: 6),
                Text(r.label, style: AppTextStyles.labelSmall.copyWith(color: r.color)),
              ],
            ),
          )).toList(),
        ),
    ])),
    const SizedBox(height: 12),
    Row(children: [
      Expanded(child: ElevatedButton.icon(onPressed: onAccept, icon: const Icon(Icons.play_arrow, size: 16), label: Text('ENGAGE', style: AppTextStyles.labelMediumUpper), style: ElevatedButton.styleFrom(backgroundColor: AppColors.electricCyan, foregroundColor: AppColors.coreVoid, padding: const EdgeInsets.symmetric(vertical: 12), shape: const ContinuousRectangleBorder(borderRadius: BorderRadius.zero)))),
      const SizedBox(width: 8),
      Expanded(child: OutlinedButton.icon(onPressed: onPostpone, icon: const Icon(Icons.snooze, size: 16), label: Text('POSTPONE', style: AppTextStyles.labelMediumUpper), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)))),
    ]),
  ]));

  String _formatDuration(Duration d) => '${d.inHours.toString().padLeft(2, '0')}:${(d.inMinutes % 60).toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
}

class _InsightMessage extends StatelessWidget {
  final TerminalMessage message;
  const _InsightMessage({required this.message});

  @override Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.surfaceContainerHigh, border: Border.all(color: AppColors.brushedMetallicTrim, width: 1), boxShadow: AppColors.cardElevation), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [const Icon(Icons.psychology, color: AppColors.electricViolet, size: 16), const SizedBox(width: 8), Text('// BIOMETRIC EQUILIBRIUM', style: AppTextStyles.labelSmallUpper.copyWith(color: AppColors.electricViolet)), const Spacer(), Text(_formatTime(message.timestamp), style: AppTextStyles.labelSmall.copyWith(color: AppColors.onSurfaceVariant))]),
    const SizedBox(height: 8),
    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.electricViolet.withOpacity(0.2), border: Border.all(color: AppColors.electricViolet, width: 1)), child: const Icon(Icons.monitor_heart, color: AppColors.electricViolet, size: 20)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(message.content, style: AppTextStyles.bodyMedium),
        if (message.advice != null) ...[const SizedBox(height: 12), Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, border: Border.all(color: AppColors.brushedMetallicTrim, width: 1)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('OVERSEER ADVICE:', style: AppTextStyles.labelSmallUpper.copyWith(color: AppColors.onSurfaceVariant)), Text(message.advice!, style: AppTextStyles.labelSmallUpper.copyWith(color: message.adviceColor ?? AppColors.electricViolet, fontWeight: FontWeight.bold))]))],
      ])),
    ]),
  ]));

  String _formatTime(DateTime t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')} UTC';
}

class _UserMessage extends StatelessWidget {
  final TerminalMessage message;
  const _UserMessage({required this.message});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surfaceContainerHigh,
      border: Border.all(color: AppColors.electricCyan, width: 1),
      boxShadow: AppColors.cardElevation,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              _formatTime(message.timestamp),
              style: AppTextStyles.labelSmall.copyWith(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(width: 8),
            Text('// OPERATOR', style: AppTextStyles.labelSmallUpper),
            const SizedBox(width: 8),
            Icon(Icons.person, color: AppColors.highVoltageYellow, size: 16),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            border: Border.all(color: AppColors.brushedMetallicTrim, width: 1),
          ),
          child: Text(message.content, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.highVoltageYellow)),
        ),
      ],
    ),
  );

  String _formatTime(DateTime t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')} UTC';
}

class _AiMessage extends StatelessWidget {
  final TerminalMessage message;
  const _AiMessage({required this.message});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surfaceContainerHigh,
      border: Border.all(color: AppColors.electricViolet, width: 1),
      boxShadow: AppColors.cardElevation,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.psychology, color: AppColors.electricViolet, size: 16),
            const SizedBox(width: 8),
            Text('// A.E.G.I.S.', style: AppTextStyles.labelSmallUpper),
            const Spacer(),
            Text(_formatTime(message.timestamp), style: AppTextStyles.labelSmall.copyWith(color: AppColors.onSurfaceVariant)),
          ],
        ),
        const SizedBox(height: 8),
        Text(message.content, style: AppTextStyles.bodyMedium),
      ],
    ),
  );

  String _formatTime(DateTime t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')} UTC';
}