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
  final List<ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _loadWelcomeMessage();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadWelcomeMessage() {
    _messages.add(ChatMessage(
      type: MessageType.ai,
      timestamp: DateTime.now(),
      content: 'Welcome to the AI Assistant. Configure your API in the Config tab to enable AI-powered insights, quest generation, and activity analysis.',
    ));
  }

  @override
  Widget build(BuildContext context) {
    final aiState = ref.watch(aiConfigurationProvider);
    final isConfigured = aiState.isConfigured;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            _buildAppBar(aiState),
            // Configuration Banner (if not configured)
            if (!isConfigured) _buildConfigBanner(aiState),
            // Terminal Header
            _buildTerminalHeader(aiState),
            // Message Feed
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _messages.length,
                itemBuilder: (context, index) => _buildMessage(_messages[index]),
              ),
            ),
            // Input Panel
            if (isConfigured) _buildInputPanel(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(AiConfigState aiState) {
    return Container(
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
                  Text('AI Assistant', style: AppTextStyles.headlineSmall),
                ],
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppColors.surfaceContainerHigh, border: Border.all(color: AppColors.brushedMetallicTrim, width: 1)),
            child: Row(children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(
                color: aiState.isConfigured ? AppColors.electricViolet : AppColors.overloadCrimson,
                shape: BoxShape.circle,
              )),
              const SizedBox(width: 6),
              Text(
                aiState.isConfigured ? 'AI CONNECTED' : 'AI NOT CONFIGURED',
                style: AppTextStyles.labelSmallUpper.copyWith(
                  color: aiState.isConfigured ? AppColors.electricViolet : AppColors.overloadCrimson,
                ),
              ),
            ]),
          ),
          const SizedBox(width: 12),
          Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.surfaceContainerHigh, border: Border.all(color: AppColors.brushedMetallicTrim, width: 1)), child: IconButton(icon: const Icon(Icons.home, color: AppColors.electricCyan, size: 22), onPressed: () {})),
        ],
      ),
    );
  }

  Widget _buildConfigBanner(AiConfigState aiState) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        border: Border.all(color: AppColors.electricViolet, width: 2),
        boxShadow: AppColors.cardElevation,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.settings_suggest, color: AppColors.electricViolet, size: 20),
              const SizedBox(width: 8),
              Text('AI NOT CONFIGURED', style: AppTextStyles.labelSmallUpper.copyWith(color: AppColors.electricViolet)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Configure your AI provider in the Config tab to unlock AI-powered features: personalized insights, quest generation, activity analysis, and smart recommendations.',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to config tab - this would need a navigation controller
              // For now show a snackbar
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Go to Config tab → AI Configuration to set up your API', style: AppTextStyles.bodyMedium),
                  backgroundColor: AppColors.surfaceContainerHigh,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.arrow_forward, size: 18),
            label: Text('OPEN CONFIG', style: AppTextStyles.labelMediumUpper),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.electricViolet,
              foregroundColor: AppColors.coreVoid,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTerminalHeader(AiConfigState aiState) {
    return Container(
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
              Container(width: 8, height: 8, decoration: BoxDecoration(
              color: aiState.isConfigured ? AppColors.electricCyan : AppColors.overloadCrimson,
              shape: BoxShape.circle,
            )),
              const SizedBox(width: 8),
              Text(
                aiState.isConfigured ? 'NEURAL AI // ${aiState.provider.toUpperCase()}' : 'NEURAL AI // OFFLINE',
                style: AppTextStyles.labelSmallUpper.copyWith(color: AppColors.electricCyan),
              ),
              const Spacer(),
              if (aiState.isConfigured)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.surfaceContainerHigh, border: Border.all(color: AppColors.brushedMetallicTrim, width: 1)),
                  child: Text('MODEL: ${aiState.model}', style: AppTextStyles.labelSmallUpper.copyWith(color: AppColors.highVoltageYellow)),
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
                  Row(children: [const Icon(Icons.hub, color: AppColors.electricCyan, size: 14), const SizedBox(width: 6), Text('STATUS', style: AppTextStyles.labelSmallUpper)]),
                  Text(
                    aiState.isConfigured ? 'CONNECTED' : 'DISCONNECTED',
                    style: AppTextStyles.labelSmallUpper.copyWith(
                      color: aiState.isConfigured ? AppColors.electricCyan : AppColors.overloadCrimson,
                    ),
                  ),
                ]),
                const SizedBox(height: 8),
                // Simple status indicator
                SizedBox(
                  height: 24,
                  child: CustomPaint(
                    painter: _WaveformPainter(active: aiState.isConfigured),
                    size: const Size(double.infinity, 24),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(ChatMessage message) {
    switch (message.type) {
      case MessageType.user:
        return _UserMessage(message: message);
      case MessageType.ai:
        return _AiMessage(message: message);
      case MessageType.system:
        return _SystemMessage(message: message);
    }
  }

  Widget _buildInputPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow.withOpacity(0.85),
        border: Border(top: BorderSide(color: AppColors.brushedMetallicTrim, width: 1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Row(children: [Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.highVoltageYellow, shape: BoxShape.circle)), const SizedBox(width: 8), Text('DIRECT MESSAGE', style: AppTextStyles.labelSmallUpper)]),
              const Spacer(),
              Text(_messages.isNotEmpty ? '${_messages.length} MESSAGES' : 'NO MESSAGES', style: AppTextStyles.labelSmallUpper.copyWith(color: AppColors.electricCyan)),
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
                    hintText: 'Ask AI for insights, quests, or analysis...',
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
    );
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    final userMessage = ChatMessage(
      type: MessageType.user,
      timestamp: DateTime.now(),
      content: text,
    );

    setState(() {
      _messages.add(userMessage);
      _inputController.clear();
    });

    _scrollToBottom();

    // Get AI response
    _getAIResponse(text);
  }

  Future<void> _getAIResponse(String userInput) async {
    final aiService = ref.read(aiAgentServiceProvider);
    
    setState(() {
      _messages.add(ChatMessage(
        type: MessageType.ai,
        timestamp: DateTime.now(),
        content: '...',
      ));
    });
    _scrollToBottom();

    try {
      // Use the AI service to get a real response
      final response = await aiService.chat(userInput);
      
      if (mounted) {
        setState(() {
          // Replace the loading message with actual response
          _messages.removeLast();
          _messages.add(ChatMessage(
            type: MessageType.ai,
            timestamp: DateTime.now(),
            content: response,
          ));
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.removeLast();
          _messages.add(ChatMessage(
            type: MessageType.system,
            timestamp: DateTime.now(),
            content: 'Error: ${e.toString()}',
          ));
        });
        _scrollToBottom();
      }
    }
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

class _WaveformPainter extends CustomPainter {
  final bool active;
  const _WaveformPainter({this.active = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = active ? AppColors.electricCyan : AppColors.brushedMetallicTrim
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    final path = Path();
    final width = size.width;
    final height = size.height;
    final midY = height / 2;
    
    for (double x = 0; x <= width; x += 4) {
      final amplitude = active ? 8.0 : 2.0;
      final y = midY + (x % 60 < 30 ? amplitude : -amplitude) * (0.5 + 0.5 * (x / width));
      if (x == 0) path.moveTo(x, y);
      else path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

enum MessageType { user, ai, system }

class ChatMessage {
  final MessageType type;
  final DateTime timestamp;
  final String content;

  ChatMessage({
    required this.type,
    required this.timestamp,
    required this.content,
  });
}

// Message Widgets
class _UserMessage extends StatelessWidget {
  final ChatMessage message;
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
            Text('YOU', style: AppTextStyles.labelSmallUpper),
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

  String _formatTime(DateTime t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}';
}

class _AiMessage extends StatelessWidget {
  final ChatMessage message;
  const _AiMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
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
              Text('AI ASSISTANT', style: AppTextStyles.labelSmallUpper),
              const Spacer(),
              Text(_formatTime(message.timestamp), style: AppTextStyles.labelSmall.copyWith(color: AppColors.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 8),
          Text(message.content, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }

  String _formatTime(DateTime t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}';
}

class _SystemMessage extends StatelessWidget {
  final ChatMessage message;
  const _SystemMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.overloadCrimson.withOpacity(0.1),
        border: Border.all(color: AppColors.overloadCrimson, width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.overloadCrimson, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(message.content, style: AppTextStyles.bodySmall.copyWith(color: AppColors.overloadCrimson))),
        ],
      ),
    );
  }
}