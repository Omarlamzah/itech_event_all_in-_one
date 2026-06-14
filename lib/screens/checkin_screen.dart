import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/event.dart';
import '../models/participant.dart';
import '../services/checkin_service.dart';
import '../services/participant_service.dart';

class CheckInScreen extends StatefulWidget {
  final Event event;
  const CheckInScreen({super.key, required this.event});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> with SingleTickerProviderStateMixin {
  final _checkInService   = CheckInService();
  final _participantSvc   = ParticipantService();
  final _controller       = MobileScannerController();
  final _searchController = TextEditingController();
  final _manualController = TextEditingController();
  late final _tabController = TabController(length: 2, vsync: this);

  bool _processing = false;
  Map<String, dynamic>? _lastResult;
  Map<String, dynamic> _stats = {};
  List<Participant> _participants = [];
  bool _loadingParticipants = true;
  bool _loadingStats = true;
  String _search = '';

  // For undo: store last checked-in participant id
  int? _lastCheckedInId;
  bool _showUndo = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
    _loadParticipants();
    _searchController.addListener(() {
      setState(() => _search = _searchController.text);
      _loadParticipants(search: _searchController.text);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _tabController.dispose();
    _searchController.dispose();
    _manualController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    try {
      final s = await _checkInService.getStats(widget.event.id);
      if (mounted) setState(() { _stats = s; _loadingStats = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingStats = false);
    }
  }

  Future<void> _loadParticipants({String? search}) async {
    setState(() => _loadingParticipants = true);
    try {
      final list = await _participantSvc.getParticipants(widget.event.id, search: search);
      if (mounted) setState(() { _participants = list; _loadingParticipants = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingParticipants = false);
    }
  }

  Future<void> _processCode(String code) async {
    if (_processing || code.trim().isEmpty) return;
    setState(() { _processing = true; _lastResult = null; });
    try {
      final result = await _checkInService.scan(code.trim());
      if (mounted) {
        setState(() {
          _lastResult = result;
          _processing = false;
          if (result['status'] == 'checked_in' && result['participant'] != null) {
            _lastCheckedInId = result['participant']['id'];
            _showUndo = true;
          }
        });
        HapticFeedback.mediumImpact();
        _loadStats();
        _loadParticipants(search: _search);
        // Auto-clear after 4s
        await Future.delayed(const Duration(seconds: 4));
        if (mounted) setState(() { _lastResult = null; _showUndo = false; });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _lastResult = {'status': 'error', 'message': e.toString()};
          _processing = false;
        });
        HapticFeedback.heavyImpact();
        await Future.delayed(const Duration(seconds: 3));
        if (mounted) setState(() => _lastResult = null);
      }
    }
  }

  Future<void> _undoCheckIn() async {
    if (_lastCheckedInId == null) return;
    try {
      await _checkInService.resetCheckIn(_lastCheckedInId!);
      setState(() { _showUndo = false; _lastCheckedInId = null; _lastResult = null; });
      _loadStats();
      _loadParticipants(search: _search);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Check-in annulé'), backgroundColor: Colors.orange),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _checkInParticipant(Participant p) async {
    if (p.checkedIn) {
      // Ask to undo
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Annuler le check-in ?'),
          content: Text('${p.nmComplet} est déjà enregistré. Annuler ?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Non')),
            TextButton(onPressed: () => Navigator.pop(context, true),
                child: const Text('Annuler check-in', style: TextStyle(color: Colors.orange))),
          ],
        ),
      );
      if (ok == true) {
        try {
          await _checkInService.resetCheckIn(p.id);
          _loadStats();
          _loadParticipants(search: _search);
        } catch (e) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
          );
        }
      }
      return;
    }
    if (p.codebare != null) {
      await _processCode(p.codebare!);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ce participant n\'a pas de code barre'), backgroundColor: Colors.orange),
      );
    }
  }

  Color _resultColor(String? status) {
    switch (status) {
      case 'checked_in': return Colors.green.shade700;
      case 'already_checked_in': return Colors.orange.shade700;
      case 'not_found': return Colors.red.shade700;
      default: return Colors.red.shade700;
    }
  }

  IconData _resultIcon(String? status) {
    switch (status) {
      case 'checked_in': return Icons.check_circle;
      case 'already_checked_in': return Icons.info;
      case 'not_found': return Icons.cancel;
      default: return Icons.error;
    }
  }

  int get _total      => _stats['total'] ?? 0;
  int get _checkedIn  => _stats['checked_in'] ?? 0;
  int get _remaining  => _stats['remaining'] ?? 0;
  double get _progress => _total > 0 ? _checkedIn / _total : 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Check-In — ${widget.event.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
            tooltip: 'Torche',
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: () => _controller.switchCamera(),
            tooltip: 'Retourner',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.qr_code_scanner), text: 'Scanner'),
            Tab(icon: Icon(Icons.people), text: 'Participants'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildStatsRow(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildScannerTab(),
                _buildParticipantsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final statItems = [
      ('Total', _total, Colors.blue, Icons.people),
      ('Enregistrés', _checkedIn, Colors.green, Icons.check_circle),
      ('En attente', _remaining, Colors.orange, Icons.schedule),
      ('${(_progress * 100).toStringAsFixed(0)}%', null, Colors.purple, Icons.bar_chart),
    ];

    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Column(
        children: [
          Row(
            children: statItems.map((s) {
              final color = s.$3;
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color.withOpacity(0.2)),
                  ),
                  child: Column(children: [
                    Icon(s.$4, size: 16, color: color),
                    const SizedBox(height: 2),
                    Text(s.$2 != null ? '${s.$2}' : s.$1,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
                    Text(s.$2 != null ? s.$1 : 'Taux',
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                        textAlign: TextAlign.center),
                  ]),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 6,
              backgroundColor: Colors.green.withOpacity(0.15),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerTab() {
    return Stack(
      children: [
        MobileScanner(
          controller: _controller,
          onDetect: (capture) {
            final barcode = capture.barcodes.firstOrNull?.rawValue;
            if (barcode != null) _processCode(barcode);
          },
        ),
        // Scan frame overlay
        Center(
          child: Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 2.5),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        // Hint text
        const Positioned(
          top: 20,
          left: 0,
          right: 0,
          child: Text(
            'Pointez la caméra sur un QR code ou code barre',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 14, shadows: [
              Shadow(blurRadius: 4, color: Colors.black),
            ]),
          ),
        ),
        // Processing indicator
        if (_processing)
          const Center(child: CircularProgressIndicator(color: Colors.white)),
        // Result banner
        if (_lastResult != null)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: _resultColor(_lastResult!['status']),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_resultIcon(_lastResult!['status']), color: Colors.white, size: 30),
                  const SizedBox(height: 6),
                  Text(
                    _lastResult!['message'] ?? '',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  if (_lastResult!['participant'] != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _lastResult!['participant']['NmComplet'] ?? '',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (_showUndo) ...[
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _undoCheckIn,
                      icon: const Icon(Icons.undo, color: Colors.white, size: 16),
                      label: const Text('Annuler', style: TextStyle(color: Colors.white)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white54),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        // Manual entry at bottom-right
        Positioned(
          bottom: _lastResult != null ? 160 : 16,
          right: 16,
          child: FloatingActionButton.small(
            onPressed: _showManualEntry,
            backgroundColor: Colors.black54,
            child: const Icon(Icons.keyboard, color: Colors.white),
          ),
        ),
      ],
    );
  }

  void _showManualEntry() {
    _manualController.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Saisie manuelle', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                controller: _manualController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Code barre / QR',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.qr_code),
                ),
                onSubmitted: (v) {
                  Navigator.pop(context);
                  _processCode(v);
                },
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final v = _manualController.text;
                    Navigator.pop(context);
                    _processCode(v);
                  },
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Valider'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParticipantsTab() {
    final pending    = _participants.where((p) => !p.checkedIn).toList();
    final checkedIn  = _participants.where((p) => p.checkedIn).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher un participant…',
              prefixIcon: const Icon(Icons.search),
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              suffixIcon: _search.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () { _searchController.clear(); _loadParticipants(); },
                    )
                  : null,
            ),
          ),
        ),
        Expanded(
          child: _loadingParticipants
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () => _loadParticipants(search: _search),
                  child: _participants.isEmpty
                      ? const Center(child: Text('Aucun participant trouvé', style: TextStyle(color: Colors.grey)))
                      : ListView(
                          padding: const EdgeInsets.only(bottom: 16),
                          children: [
                            if (pending.isNotEmpty) ...[
                              _sectionHeader('En attente (${pending.length})', Colors.orange),
                              ...pending.map((p) => _participantTile(p)),
                            ],
                            if (checkedIn.isNotEmpty) ...[
                              _sectionHeader('Enregistrés (${checkedIn.length})', Colors.green),
                              ...checkedIn.map((p) => _participantTile(p)),
                            ],
                          ],
                        ),
                ),
        ),
      ],
    );
  }

  Widget _sectionHeader(String title, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: color.withOpacity(0.08),
      child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
    );
  }

  Widget _participantTile(Participant p) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: p.checkedIn ? Colors.green : Colors.grey.shade300,
        child: Icon(
          p.checkedIn ? Icons.check : Icons.person,
          color: p.checkedIn ? Colors.white : Colors.grey.shade600,
          size: 20,
        ),
      ),
      title: Text(p.nmComplet, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Row(children: [
        if (p.typeInscri != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(p.typeInscri!, style: const TextStyle(fontSize: 10, color: Colors.blue)),
          ),
          const SizedBox(width: 6),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: p.paymentColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(p.paymentStatus, style: TextStyle(fontSize: 10, color: p.paymentColor)),
        ),
        if (p.checkedIn && p.checkedInAt != null) ...[
          const SizedBox(width: 6),
          Text(_formatTime(p.checkedInAt!), style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ]),
      trailing: p.checkedIn
          ? IconButton(
              icon: const Icon(Icons.undo, color: Colors.orange),
              onPressed: () => _checkInParticipant(p),
              tooltip: 'Annuler check-in',
            )
          : IconButton(
              icon: const Icon(Icons.how_to_reg, color: Colors.green),
              onPressed: () => _checkInParticipant(p),
              tooltip: 'Check-in',
            ),
      onTap: () => _checkInParticipant(p),
    );
  }

  String _formatTime(String iso) {
    try {
      final d = DateTime.parse(iso).toLocal();
      return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
}
