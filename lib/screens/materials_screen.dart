import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../models/material_item.dart';
import '../models/supplier.dart';
import '../services/material_service.dart';
import '../services/supplier_service.dart';

class MaterialsScreen extends StatefulWidget {
  const MaterialsScreen({super.key});

  @override
  State<MaterialsScreen> createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends State<MaterialsScreen> {
  final _matSvc  = MaterialService();
  final _supSvc  = SupplierService();
  List<MaterialItem> _items     = [];
  List<Supplier>     _suppliers = [];
  bool _loading = true;

  static const _categoryColors = {
    'equipment':  Colors.blue,
    'document':   Colors.indigo,
    'consumable': Colors.orange,
    'kit':        Colors.teal,
  };

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([_matSvc.getMaterials(), _supSvc.getSuppliers()]);
      setState(() {
        _items     = results[0] as List<MaterialItem>;
        _suppliers = results[1] as List<Supplier>;
        _loading   = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) _showError(e.toString());
    }
  }

  void _showError(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));

  Future<void> _openForm([MaterialItem? item]) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MaterialForm(item: item, service: _matSvc, suppliers: _suppliers),
    );
    if (result == true) _load();
  }

  Future<void> _delete(MaterialItem item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer'),
        content: Text('Supprimer "${item.name}" ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: const Text('Supprimer', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok != true) return;
    try { await _matSvc.delete(item.id); _load(); }
    catch (e) { _showError(e.toString()); }
  }

  String _photoUrl(String path) {
    final base = AppConfig.baseUrl.replaceAll('/api', '');
    if (path.startsWith('/storage/') || path.startsWith('storage/')) {
      return '$base${path.startsWith('/') ? path : '/$path'}';
    }
    return '$base/storage/$path';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Matériaux')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _items.isEmpty
                  ? const Center(child: Text('Aucun matériau.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _items.length,
                      itemBuilder: (_, i) {
                        final m = _items[i];
                        final color = _categoryColors[m.category] ?? Colors.grey;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: m.photo != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      _photoUrl(m.photo!),
                                      width: 44, height: 44, fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => _defaultIcon(color),
                                    ),
                                  )
                                : _defaultIcon(color),
                            title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(MaterialItem.categoryLabels[m.category] ?? m.category,
                                        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
                                  ),
                                  const SizedBox(width: 8),
                                  Text('Qté: ${m.totalQuantity}',
                                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                ]),
                                if (m.supplier != null)
                                  Text(m.supplier!.name,
                                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                            trailing: PopupMenuButton(
                              itemBuilder: (_) => [
                                const PopupMenuItem(value: 'edit', child: Text('Modifier')),
                                const PopupMenuItem(value: 'delete',
                                    child: Text('Supprimer', style: TextStyle(color: Colors.red))),
                              ],
                              onSelected: (v) {
                                if (v == 'edit') _openForm(m);
                                else if (v == 'delete') _delete(m);
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }

  Widget _defaultIcon(Color color) => Container(
        width: 44, height: 44,
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(Icons.inventory_2, color: color, size: 22),
      );
}

class _MaterialForm extends StatefulWidget {
  final MaterialItem? item;
  final MaterialService service;
  final List<Supplier> suppliers;
  const _MaterialForm({this.item, required this.service, required this.suppliers});

  @override
  State<_MaterialForm> createState() => _MaterialFormState();
}

class _MaterialFormState extends State<_MaterialForm> {
  final _formKey  = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.item?.name ?? '');
  late final _desc = TextEditingController(text: widget.item?.description ?? '');
  late final _qty  = TextEditingController(text: widget.item?.totalQuantity.toString() ?? '0');
  late String _category = widget.item?.category ?? 'equipment';
  late int?   _supplierId = widget.item?.supplierId;
  bool _saving = false;

  @override
  void dispose() { _name.dispose(); _desc.dispose(); _qty.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final data = {
        'name': _name.text.trim(),
        'category': _category,
        'description': _desc.text.trim().isEmpty ? null : _desc.text.trim(),
        'total_quantity': int.tryParse(_qty.text) ?? 0,
        'supplier_id': _supplierId,
      };
      if (widget.item != null) await widget.service.update(widget.item!.id, data);
      else await widget.service.create(data);
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
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.item != null ? 'Modifier matériau' : 'Nouveau matériau',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Nom *', border: OutlineInputBorder(), isDense: true),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(labelText: 'Catégorie', border: OutlineInputBorder(), isDense: true),
                items: MaterialItem.categoryLabels.entries
                    .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _qty,
                decoration: const InputDecoration(labelText: 'Quantité totale', border: OutlineInputBorder(), isDense: true),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              if (widget.suppliers.isNotEmpty)
                DropdownButtonFormField<int?>(
                  value: _supplierId,
                  decoration: const InputDecoration(labelText: 'Fournisseur', border: OutlineInputBorder(), isDense: true),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('— Aucun —')),
                    ...widget.suppliers.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))),
                  ],
                  onChanged: (v) => setState(() => _supplierId = v),
                ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _desc,
                decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder(), isDense: true),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(widget.item != null ? 'Mettre à jour' : 'Créer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
