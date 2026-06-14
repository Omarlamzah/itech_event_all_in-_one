import 'package:flutter/material.dart';
import '../models/event.dart';
import '../models/event_material.dart';
import '../models/material_item.dart';
import '../services/event_material_service.dart';
import '../services/material_service.dart';

class EventMaterialsScreen extends StatefulWidget {
  final Event event;
  const EventMaterialsScreen({super.key, required this.event});

  @override
  State<EventMaterialsScreen> createState() => _EventMaterialsScreenState();
}

class _EventMaterialsScreenState extends State<EventMaterialsScreen> {
  final _svc    = EventMaterialService();
  final _matSvc = MaterialService();
  List<EventMaterial>  _items   = [];
  List<MaterialItem>   _catalog = [];
  Map<String, dynamic> _stats   = {};
  bool _loading = true;

  static const _statusColors = {
    'pending':   Colors.orange,
    'confirmed': Colors.blue,
    'delivered': Colors.green,
    'returned':  Colors.grey,
  };

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _svc.getItems(widget.event.id),
        _svc.getStats(widget.event.id),
        _matSvc.getMaterials(),
      ]);
      setState(() {
        _items   = results[0] as List<EventMaterial>;
        _stats   = results[1] as Map<String, dynamic>;
        _catalog = results[2] as List<MaterialItem>;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      _showError(e.toString());
    }
  }

  void _showError(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));

  Future<void> _openForm([EventMaterial? item]) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EventMaterialForm(
        item: item, eventId: widget.event.id,
        service: _svc, catalog: _catalog,
      ),
    );
    if (result == true) _load();
  }

  Future<void> _delete(EventMaterial item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Retirer'),
        content: Text('Retirer "${item.material?.name}" de cet événement ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: const Text('Retirer', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok != true) return;
    try { await _svc.remove(widget.event.id, item.id); _load(); }
    catch (e) { _showError(e.toString()); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Matériel — ${widget.event.name}')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Assigner'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: CustomScrollView(
                slivers: [
                  // Stats row
                  SliverToBoxAdapter(child: _buildStats()),
                  // Items list
                  _items.isEmpty
                      ? SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey),
                                const SizedBox(height: 12),
                                const Text('Aucun matériel assigné', style: TextStyle(color: Colors.grey)),
                                const SizedBox(height: 8),
                                TextButton.icon(
                                  onPressed: () => _openForm(),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Assigner le premier'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.all(12),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (_, i) => _buildItem(_items[i]),
                              childCount: _items.length,
                            ),
                          ),
                        ),
                ],
              ),
            ),
    );
  }

  Widget _buildStats() {
    final statItems = [
      ('Total', _stats['total_items'] ?? 0, Colors.blue, Icons.inventory_2),
      ('Livrés', _stats['delivered'] ?? 0, Colors.green, Icons.local_shipping),
      ('En attente', _stats['pending'] ?? 0, Colors.orange, Icons.schedule),
      ('Nécessaire', _stats['total_needed'] ?? 0, Colors.purple, Icons.format_list_numbered),
    ];
    return Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: statItems.map((s) {
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              decoration: BoxDecoration(
                color: (s.$3 as Color).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: (s.$3 as Color).withOpacity(0.2)),
              ),
              child: Column(children: [
                Icon(s.$4 as IconData, size: 18, color: s.$3 as Color),
                const SizedBox(height: 4),
                Text('${s.$2}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: s.$3 as Color)),
                Text(s.$1 as String, style: const TextStyle(fontSize: 10, color: Colors.grey), textAlign: TextAlign.center),
              ]),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildItem(EventMaterial item) {
    final color = _statusColors[item.status] ?? Colors.grey;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(Icons.inventory_2, color: color),
        ),
        title: Text(item.material?.name ?? '—', style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                child: Text(EventMaterial.statusLabels[item.status] ?? item.status,
                    style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
              ),
            ]),
            Text('Nécessaire: ${item.quantityNeeded} · Disponible: ${item.quantityAvailable} · Utilisé: ${item.quantityUsed}',
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            if (item.notes != null && item.notes!.isNotEmpty)
              Text(item.notes!, style: const TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Text('Modifier')),
            const PopupMenuItem(value: 'remove', child: Text('Retirer', style: TextStyle(color: Colors.red))),
          ],
          onSelected: (v) {
            if (v == 'edit') _openForm(item);
            else if (v == 'remove') _delete(item);
          },
        ),
      ),
    );
  }
}

// ── Form ─────────────────────────────────────────────────────────────────────
class _EventMaterialForm extends StatefulWidget {
  final EventMaterial? item;
  final int eventId;
  final EventMaterialService service;
  final List<MaterialItem> catalog;
  const _EventMaterialForm({this.item, required this.eventId, required this.service, required this.catalog});

  @override
  State<_EventMaterialForm> createState() => _EventMaterialFormState();
}

class _EventMaterialFormState extends State<_EventMaterialForm> {
  int? _materialId;
  late final _needed    = TextEditingController(text: widget.item?.quantityNeeded.toString() ?? '1');
  late final _available = TextEditingController(text: widget.item?.quantityAvailable.toString() ?? '0');
  late final _used      = TextEditingController(text: widget.item?.quantityUsed.toString() ?? '0');
  late String _status   = widget.item?.status ?? 'pending';
  late final _notes     = TextEditingController(text: widget.item?.notes ?? '');
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _materialId = widget.item?.materialId;
  }

  @override
  void dispose() { _needed.dispose(); _available.dispose(); _used.dispose(); _notes.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (widget.item == null && _materialId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sélectionnez un matériau'), backgroundColor: Colors.red));
      return;
    }
    setState(() => _saving = true);
    try {
      final data = {
        if (widget.item == null) 'material_id': _materialId,
        'quantity_needed': int.tryParse(_needed.text) ?? 0,
        'quantity_available': int.tryParse(_available.text) ?? 0,
        'quantity_used': int.tryParse(_used.text) ?? 0,
        'status': _status,
        'notes': _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      };
      if (widget.item != null) await widget.service.update(widget.eventId, widget.item!.id, data);
      else await widget.service.assign(widget.eventId, data);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.item != null ? 'Modifier assignation' : 'Assigner un matériau',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (widget.item == null)
              DropdownButtonFormField<int>(
                value: _materialId,
                decoration: const InputDecoration(labelText: 'Matériau *', border: OutlineInputBorder(), isDense: true),
                items: widget.catalog.map((m) => DropdownMenuItem(value: m.id, child: Text(m.name))).toList(),
                onChanged: (v) => setState(() => _materialId = v),
              ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _numField(_needed, 'Nécessaire')),
              const SizedBox(width: 8),
              Expanded(child: _numField(_available, 'Disponible')),
              const SizedBox(width: 8),
              Expanded(child: _numField(_used, 'Utilisé')),
            ]),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _status,
              decoration: const InputDecoration(labelText: 'Statut', border: OutlineInputBorder(), isDense: true),
              items: EventMaterial.statusLabels.entries
                  .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (v) => setState(() => _status = v!),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notes,
              decoration: const InputDecoration(labelText: 'Remarques', border: OutlineInputBorder(), isDense: true),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(widget.item != null ? 'Mettre à jour' : 'Assigner'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _numField(TextEditingController ctrl, String label) => TextFormField(
        controller: ctrl,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), isDense: true),
        keyboardType: TextInputType.number,
      );
}
