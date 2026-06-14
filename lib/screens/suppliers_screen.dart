import 'package:flutter/material.dart';
import '../models/supplier.dart';
import '../services/supplier_service.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  final _service = SupplierService();
  List<Supplier> _suppliers = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _service.getSuppliers();
      setState(() { _suppliers = data; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) _showError(e.toString());
    }
  }

  void _showError(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));

  Future<void> _openForm([Supplier? supplier]) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SupplierForm(supplier: supplier, service: _service),
    );
    if (result == true) _load();
  }

  Future<void> _delete(Supplier s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer'),
        content: Text('Supprimer "${s.name}" ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: const Text('Supprimer', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _service.delete(s.id);
      _load();
    } catch (e) { _showError(e.toString()); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fournisseurs')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _suppliers.isEmpty
                  ? const Center(child: Text('Aucun fournisseur.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _suppliers.length,
                      itemBuilder: (_, i) {
                        final s = _suppliers[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.orange.withOpacity(0.1),
                              child: const Icon(Icons.storefront, color: Colors.orange),
                            ),
                            title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (s.contactPerson != null)
                                  Text(s.contactPerson!, style: const TextStyle(fontSize: 12)),
                                if (s.phone != null)
                                  Row(children: [
                                    const Icon(Icons.phone, size: 12, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(s.phone!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  ]),
                              ],
                            ),
                            trailing: PopupMenuButton(
                              itemBuilder: (_) => [
                                const PopupMenuItem(value: 'edit', child: Text('Modifier')),
                                const PopupMenuItem(value: 'delete',
                                    child: Text('Supprimer', style: TextStyle(color: Colors.red))),
                              ],
                              onSelected: (v) {
                                if (v == 'edit') _openForm(s);
                                else if (v == 'delete') _delete(s);
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}

class _SupplierForm extends StatefulWidget {
  final Supplier? supplier;
  final SupplierService service;
  const _SupplierForm({this.supplier, required this.service});

  @override
  State<_SupplierForm> createState() => _SupplierFormState();
}

class _SupplierFormState extends State<_SupplierForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name    = TextEditingController(text: widget.supplier?.name ?? '');
  late final _contact = TextEditingController(text: widget.supplier?.contactPerson ?? '');
  late final _phone   = TextEditingController(text: widget.supplier?.phone ?? '');
  late final _email   = TextEditingController(text: widget.supplier?.email ?? '');
  late final _address = TextEditingController(text: widget.supplier?.address ?? '');
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose(); _contact.dispose(); _phone.dispose();
    _email.dispose(); _address.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final data = {
        'name': _name.text.trim(),
        'contact_person': _contact.text.trim().isEmpty ? null : _contact.text.trim(),
        'phone': _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        'email': _email.text.trim().isEmpty ? null : _email.text.trim(),
        'address': _address.text.trim().isEmpty ? null : _address.text.trim(),
      };
      if (widget.supplier != null) {
        await widget.service.update(widget.supplier!.id, data);
      } else {
        await widget.service.create(data);
      }
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
              Text(widget.supplier != null ? 'Modifier fournisseur' : 'Nouveau fournisseur',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _field(_name, 'Nom *', required: true),
              _field(_contact, 'Contact'),
              _field(_phone, 'Téléphone', keyboard: TextInputType.phone),
              _field(_email, 'Email', keyboard: TextInputType.emailAddress),
              _field(_address, 'Adresse', maxLines: 2),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(widget.supplier != null ? 'Mettre à jour' : 'Créer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label,
      {bool required = false, TextInputType keyboard = TextInputType.text, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboard,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null : null,
      ),
    );
  }
}
