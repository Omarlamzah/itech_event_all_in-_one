import 'package:flutter/material.dart';
import '../services/ai_chat_service.dart';

class AiChatWidget extends StatefulWidget {
  const AiChatWidget({super.key});

  @override
  State<AiChatWidget> createState() => _AiChatWidgetState();
}

class _AiChatWidgetState extends State<AiChatWidget>
    with SingleTickerProviderStateMixin {
  bool _open = false;
  final _service    = AiChatService();
  final _messages   = <AiChatMessage>[];
  final _controller = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _loading     = false;
  int? _showSqlIdx;

  late final AnimationController _animCtrl;
  late final Animation<double>    _scaleAnim;
  late final Animation<Offset>    _slideAnim;

  static const _suggestions = [
    'Combien de participants au total ?',
    'Liste des événements en cours',
    'Participants non payés ?',
    'Matériaux livrés ?',
  ];

  static const _gradientColors = [Color(0xFF7C3AED), Color(0xFF2563EB)];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _scaleAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutBack);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _controller.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _open = !_open);
    if (_open) {
      _animCtrl.forward();
    } else {
      _animCtrl.reverse();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send([String? text]) async {
    final msg = (text ?? _controller.text).trim();
    if (msg.isEmpty || _loading) return;
    _controller.clear();
    setState(() {
      _messages.add(AiChatMessage(role: 'user', content: msg));
      _loading = true;
    });
    _scrollToBottom();

    try {
      final reply = await _service.sendMessage(msg);
      setState(() => _messages.add(reply));
    } catch (_) {
      setState(() => _messages.add(const AiChatMessage(
        role: 'assistant',
        content: "Désolé, une erreur s'est produite. Veuillez réessayer.",
      )));
    } finally {
      setState(() => _loading = false);
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ── Chat panel ──────────────────────────────────────────────────────
        if (_open)
          Positioned(
            bottom: 80,
            right: 16,
            child: SlideTransition(
              position: _slideAnim,
              child: ScaleTransition(
                scale: _scaleAnim,
                alignment: Alignment.bottomRight,
                child: _buildPanel(context),
              ),
            ),
          ),

        // ── FAB ─────────────────────────────────────────────────────────────
        Positioned(
          bottom: 16,
          right: 16,
          child: _buildFab(),
        ),
      ],
    );
  }

  Widget _buildFab() {
    return GestureDetector(
      onTap: _toggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: _gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C3AED).withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          _open ? Icons.close : Icons.auto_awesome,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildPanel(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final panelWidth  = (screenWidth - 32).clamp(0.0, 360.0);

    return Material(
      elevation: 12,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: panelWidth,
        height: 480,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildMessages()),
            _buildInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: _gradientColors,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Assistant IA',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                Text('Posez-moi n\'importe quelle question',
                    style: TextStyle(color: Colors.white70, fontSize: 11)),
              ],
            ),
          ),
          GestureDetector(
            onTap: _toggle,
            child: const Icon(Icons.keyboard_arrow_down, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildMessages() {
    return Container(
      color: const Color(0xFFF8F8F8),
      child: ListView(
        controller: _scrollCtrl,
        padding: const EdgeInsets.all(12),
        children: [
          // Welcome + suggestions
          if (_messages.isEmpty) ...[
            _buildBotBubble(
              'Bonjour ! Je suis votre assistant IA. Je peux répondre à vos questions sur les événements, participants, matériaux et plus encore.',
            ),
            const SizedBox(height: 8),
            const Text('Suggestions :',
                style: TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 6),
            ..._suggestions.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: GestureDetector(
                    onTap: () => _send(s),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Text(s,
                          style: const TextStyle(fontSize: 12, color: Colors.black87)),
                    ),
                  ),
                )),
          ],

          // Messages
          ..._messages.asMap().entries.map((entry) {
            final i   = entry.key;
            final msg = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: msg.role == 'user'
                  ? _buildUserMessage(msg)
                  : _buildAssistantMessage(msg, i),
            );
          }),

          // Typing indicator
          if (_loading)
            Row(
              children: [
                _avatar(isBot: true),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
                  ),
                  child: const _TypingIndicator(),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildUserMessage(AiChatMessage msg) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: _gradientColors),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(4),
              ),
            ),
            child: Text(msg.content,
                style: const TextStyle(color: Colors.white, fontSize: 13)),
          ),
        ),
        const SizedBox(width: 8),
        _avatar(isBot: false),
      ],
    );
  }

  Widget _buildAssistantMessage(AiChatMessage msg, int i) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _avatar(isBot: true),
            const SizedBox(width: 8),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(4),
                    bottomRight: Radius.circular(16),
                  ),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4)],
                ),
                child: Text(msg.content,
                    style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4)),
              ),
            ),
          ],
        ),
        // SQL toggle
        if (msg.sql != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => setState(() => _showSqlIdx = _showSqlIdx == i ? null : i),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.code, size: 13, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        _showSqlIdx == i ? 'Masquer SQL' : 'Voir SQL',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                if (_showSqlIdx == i) ...[
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      msg.sql!,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: Color(0xFF34D399),
                        height: 1.5,
                      ),
                    ),
                  ),
                  // Results mini-table
                  if (msg.results != null &&
                      msg.results!.isNotEmpty &&
                      msg.results!.length <= 10) ...[
                    const SizedBox(height: 6),
                    _buildResultsTable(msg.results!),
                  ],
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildResultsTable(List<Map<String, dynamic>> rows) {
    final cols = rows.first.keys.toList();
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: 32,
          dataRowMinHeight: 28,
          dataRowMaxHeight: 36,
          horizontalMargin: 10,
          columnSpacing: 12,
          headingTextStyle: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
          dataTextStyle: const TextStyle(fontSize: 11, color: Colors.black87),
          columns: cols
              .map((c) => DataColumn(label: Text(c)))
              .toList(),
          rows: rows
              .map((row) => DataRow(
                    cells: cols
                        .map((c) => DataCell(Text(row[c]?.toString() ?? '—')))
                        .toList(),
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildBotBubble(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _avatar(isBot: true),
        const SizedBox(width: 8),
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4)],
            ),
            child: Text(text,
                style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4)),
          ),
        ),
      ],
    );
  }

  Widget _avatar({required bool isBot}) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: isBot ? const Color(0xFFEDE9FE) : const Color(0xFF2563EB),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        isBot ? Icons.smart_toy : Icons.person,
        size: 15,
        color: isBot ? const Color(0xFF7C3AED) : Colors.white,
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _controller,
                enabled: !_loading,
                style: const TextStyle(fontSize: 13),
                decoration: const InputDecoration.collapsed(
                  hintText: 'Posez votre question...',
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                onSubmitted: (_) => _send(),
                textInputAction: TextInputAction.send,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _loading ? null : _send,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _loading
                      ? [Colors.grey.shade300, Colors.grey.shade300]
                      : _gradientColors,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 17),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Typing dots indicator ────────────────────────────────────────────────────
class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with TickerProviderStateMixin {
  final _controllers = <AnimationController>[];
  final _anims       = <Animation<double>>[];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 3; i++) {
      final c = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      );
      final a = Tween<double>(begin: 0, end: -5).animate(
        CurvedAnimation(parent: c, curve: Curves.easeInOut),
      );
      _controllers.add(c);
      _anims.add(a);
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) c.repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) => AnimatedBuilder(
        animation: _anims[i],
        builder: (_, __) => Transform.translate(
          offset: Offset(0, _anims[i].value),
          child: Container(
            width: 7,
            height: 7,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              shape: BoxShape.circle,
            ),
          ),
        ),
      )),
    );
  }
}
