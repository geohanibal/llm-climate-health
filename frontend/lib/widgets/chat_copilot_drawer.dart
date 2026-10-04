/// Climate-Health Copilot drawer: interactive conversational AI assistant
/// tailored specifically for the ETL climate-health thesis platform.
///
/// Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
library;

import 'package:flutter/material.dart';

import '../models/chat_models.dart';
import '../models/integration_result.dart';
import '../models/parsed_request.dart';
import '../models/platform_options.dart';
import '../services/api_client.dart';

class ChatCopilotDrawer extends StatefulWidget {
  final PlatformOptions? options;
  final IntegrationResult? activeResult;
  final String? currentDisease;
  final String? currentRegion;
  final DateTime? currentStartDate;
  final DateTime? currentEndDate;
  final ValueChanged<ParsedRequest> onApplyPrefill;
  final VoidCallback onClose;

  const ChatCopilotDrawer({
    super.key,
    required this.options,
    required this.activeResult,
    required this.currentDisease,
    required this.currentRegion,
    required this.currentStartDate,
    required this.currentEndDate,
    required this.onApplyPrefill,
    required this.onClose,
  });

  @override
  State<ChatCopilotDrawer> createState() => _ChatCopilotDrawerState();
}

class _ChatCopilotDrawerState extends State<ChatCopilotDrawer> {
  final ApiClient _api = const ApiClient();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  List<String> _currentPrompts = [];

  @override
  void initState() {
    super.initState();
    _initWelcome();
  }

  void _initWelcome() {
    _messages.clear();
    _messages.add(
      ChatMessage(
        role: 'assistant',
        content:
            "👋 **Hello! I am the Climate-Health Copilot.**\n\n"
            "Your intelligent research assistant for this Climate-Health Data Integration Platform.\n\n"
            "You can ask me in **any language** (English, Deutsch, or ქართულად):\n"
            "• Available diseases (Dengue, Malaria, Cholera) and geographic coverage;\n"
            "• How ERA5 climate reanalysis works (temperature & precipitation);\n"
            "• Biological vector breeding cycles and why lagged correlations (Lag 1-3) matter;\n"
            "• How to prepare your custom CSV file for upload;\n"
            "• Or ask me to automatically populate the query form for you!\n\n"
            "*(Deutsch: Ich antworte in Ihrer Sprache. / ქართულად: შეგიძლიათ ქართულადაც მომწეროთ.)*",
      ),
    );
    _updateDefaultPrompts();
  }

  void _updateDefaultPrompts() {
    if (widget.activeResult != null) {
      final res = widget.activeResult!;
      _currentPrompts = [
        "📊 Analyze active results on screen",
        "🦟 Why is lagged cross-correlation important?",
        "🌡️ Which weather variable has higher impact in ${res.region}?",
        "🇬🇪 ქართულად ამიხსენი მიღებული შედეგები",
      ];
    } else {
      _currentPrompts = [
        "🌍 What data is available for Thailand?",
        "📋 Set form for Dengue in Thailand (2018-2022)",
        "🔬 What is ERA5 Reanalysis vs station data?",
        "Welche Krankheiten werden unterstützt?",
      ];
    }
  }

  @override
  void didUpdateWidget(covariant ChatCopilotDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeResult != widget.activeResult) {
      _updateDefaultPrompts();
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
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

  ChatContext _buildContext() {
    ActiveResultSummary? resultSummary;
    if (widget.activeResult != null) {
      resultSummary = ActiveResultSummary.fromIntegrationResult(widget.activeResult!);
    }

    String? startStr;
    if (widget.currentStartDate != null) {
      startStr =
          '${widget.currentStartDate!.year}-${widget.currentStartDate!.month.toString().padLeft(2, '0')}-01';
    }
    String? endStr;
    if (widget.currentEndDate != null) {
      endStr =
          '${widget.currentEndDate!.year}-${widget.currentEndDate!.month.toString().padLeft(2, '0')}-01';
    }

    return ChatContext(
      currentDisease: widget.currentDisease,
      currentRegion: widget.currentRegion,
      currentStartDate: startStr,
      currentEndDate: endStr,
      activeResult: resultSummary,
    );
  }

  Future<void> _sendMessage(String text) async {
    final clean = text.trim();
    if (clean.isEmpty || _isLoading) return;

    _textController.clear();
    setState(() {
      _messages.add(ChatMessage(role: 'user', content: clean));
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final context = _buildContext();
      final response = await _api.sendChatMessage(
        messages: _messages,
        context: context,
      );

      if (!mounted) return;

      setState(() {
        _messages.add(
          ChatMessage(
            role: 'assistant',
            content: response.reply,
            suggestedAction: response.suggestedAction,
            suggestedPrompts: response.suggestedPrompts,
          ),
        );
        if (response.suggestedPrompts.isNotEmpty) {
          _currentPrompts = response.suggestedPrompts;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          ChatMessage(
            role: 'assistant',
            content: "⚠️ შეცდომა პასუხის მიღებისას: $e",
          ),
        );
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _scrollToBottom();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          left: BorderSide(color: theme.dividerColor.withValues(alpha: 0.15), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(-4, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(context, colorScheme),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < _messages.length) {
                  return _buildMessageBubble(_messages[index], colorScheme);
                } else {
                  return _buildLoadingBubble(colorScheme);
                }
              },
            ),
          ),
          if (_currentPrompts.isNotEmpty && !_isLoading) _buildQuickChips(colorScheme),
          const Divider(height: 1),
          _buildInputBar(context, colorScheme),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colorScheme.primary, colorScheme.tertiary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Climate-Health Copilot',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'AI',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                _buildContextBadge(colorScheme),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: 'ახალი საუბარი / Clear chat',
            onPressed: _isLoading ? null : () => setState(_initWelcome),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            tooltip: 'დახურვა / Close',
            onPressed: widget.onClose,
          ),
        ],
      ),
    );
  }

  Widget _buildContextBadge(ColorScheme colorScheme) {
    if (widget.activeResult != null) {
      final res = widget.activeResult!;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              'Active Data: ${res.disease} • ${res.region}',
              style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    if (widget.currentDisease != null) {
      return Text(
        'Form: ${widget.currentDisease} • ${widget.currentRegion ?? ""}',
        style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
        overflow: TextOverflow.ellipsis,
      );
    }

    return Text(
      'Multilingual Research AI Assistant',
      style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
    );

  }

  Widget _buildMessageBubble(ChatMessage msg, ColorScheme colorScheme) {
    final isUser = msg.role == 'user';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[
                CircleAvatar(
                  radius: 14,
                  backgroundColor: colorScheme.primaryContainer,
                  child: Icon(Icons.smart_toy_outlined, size: 16, color: colorScheme.primary),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isUser
                        ? colorScheme.primary
                        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(4),
                      bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(16),
                    ),
                    border: isUser
                        ? null
                        : Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                  ),
                  child: _formatFormattedText(
                    msg.content,
                    isUser ? Colors.white : colorScheme.onSurface,
                    colorScheme,
                  ),
                ),
              ),
              if (isUser) ...[
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 14,
                  backgroundColor: colorScheme.secondaryContainer,
                  child: Icon(Icons.person, size: 16, color: colorScheme.onSecondaryContainer),
                ),
              ],
            ],
          ),
          if (msg.suggestedAction != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 36),
              child: _buildActionCard(msg.suggestedAction!, colorScheme),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionCard(FormPrefillAction action, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune, size: 18, color: colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                'Suggested Query Parameters',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              if (action.disease != null)
                Chip(
                  visualDensity: VisualDensity.compact,
                  label: Text('Disease: ${action.disease}', style: const TextStyle(fontSize: 11)),
                ),
              if (action.region != null)
                Chip(
                  visualDensity: VisualDensity.compact,
                  label: Text('Region: ${action.region}', style: const TextStyle(fontSize: 11)),
                ),
              if (action.startDate != null && action.endDate != null)
                Chip(
                  visualDensity: VisualDensity.compact,
                  label: Text('${action.startDate} - ${action.endDate}',
                      style: const TextStyle(fontSize: 11)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: Colors.white,
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            icon: const Icon(Icons.arrow_forward, size: 16),
            label: const Text('Apply to Form', style: TextStyle(fontSize: 12)),
            onPressed: () {
              widget.onApplyPrefill(action.toParsedRequest());
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Parameters applied to form! You can now review and run the integration.'),
                  duration: Duration(seconds: 3),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _formatFormattedText(String text, Color defaultColor, ColorScheme colorScheme) {
    final lines = text.split('\n');
    final widgets = <Widget>[];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.isEmpty) {
        widgets.add(const SizedBox(height: 6));
        continue;
      }

      final isBullet = line.trimLeft().startsWith('•') || line.trimLeft().startsWith('- ');
      final cleanText = isBullet ? line.replaceFirst(RegExp(r'^\s*[-•]\s*'), '') : line;

      final spans = _parseInlineFormatting(cleanText, defaultColor, colorScheme);

      if (isBullet) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 6, bottom: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: TextStyle(color: defaultColor, fontWeight: FontWeight.bold)),
                Expanded(child: RichText(text: TextSpan(children: spans))),
              ],
            ),
          ),
        );
      } else {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: RichText(text: TextSpan(children: spans)),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  List<TextSpan> _parseInlineFormatting(String line, Color defaultColor, ColorScheme colorScheme) {
    final spans = <TextSpan>[];
    final regex = RegExp(r'(\*\*.*?\*\*|\*.*?\*|`.*?`)');
    int lastEnd = 0;

    for (final match in regex.allMatches(line)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: line.substring(lastEnd, match.start),
          style: TextStyle(color: defaultColor, fontSize: 13.5, height: 1.4),
        ));
      }

      final matchText = match.group(0)!;
      if (matchText.startsWith('**') && matchText.endsWith('**')) {
        spans.add(TextSpan(
          text: matchText.substring(2, matchText.length - 2),
          style: TextStyle(
            color: defaultColor,
            fontWeight: FontWeight.bold,
            fontSize: 13.5,
            height: 1.4,
          ),
        ));
      } else if (matchText.startsWith('*') && matchText.endsWith('*')) {
        spans.add(TextSpan(
          text: matchText.substring(1, matchText.length - 1),
          style: TextStyle(
            color: defaultColor,
            fontStyle: FontStyle.italic,
            fontSize: 13.5,
            height: 1.4,
          ),
        ));
      } else if (matchText.startsWith('`') && matchText.endsWith('`')) {
        spans.add(TextSpan(
          text: matchText.substring(1, matchText.length - 1),
          style: TextStyle(
            color: colorScheme.primary,
            fontFamily: 'monospace',
            fontWeight: FontWeight.w600,
            fontSize: 12.5,
          ),
        ));
      }

      lastEnd = match.end;
    }

    if (lastEnd < line.length) {
      spans.add(TextSpan(
        text: line.substring(lastEnd),
        style: TextStyle(color: defaultColor, fontSize: 13.5, height: 1.4),
      ));
    }

    return spans;
  }

  Widget _buildLoadingBubble(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: colorScheme.primaryContainer,
            child: Icon(Icons.smart_toy_outlined, size: 16, color: colorScheme.primary),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.primary),
                ),
                const SizedBox(width: 10),
                Text(
                  'Copilot is thinking...',
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChips(ColorScheme colorScheme) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _currentPrompts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final prompt = _currentPrompts[index];
          return ActionChip(
            label: Text(
              prompt,
              style: TextStyle(
                fontSize: 11.5,
                color: colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.3),
            side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.2)),
            onPressed: () => _sendMessage(prompt),
          );
        },
      ),
    );
  }

  Widget _buildInputBar(BuildContext context, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: colorScheme.surface,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              textInputAction: TextInputAction.send,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(
                hintText: 'Ask a question (English, ქართულად, Deutsch)...',
                hintStyle: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: colorScheme.outlineVariant),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.6)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              ),
              onSubmitted: (val) => _sendMessage(val),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: _isLoading ? null : () => _sendMessage(_textController.text),
            icon: const Icon(Icons.send_rounded, size: 18),
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
