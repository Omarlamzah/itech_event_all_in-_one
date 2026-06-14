import 'package:flutter/material.dart';
import '../models/event.dart';
import '../models/participant.dart';
import '../services/participant_service.dart';

class ParticipantFormScreen extends StatefulWidget {
  final Event event;
  final Participant? participant;
  const ParticipantFormScreen({super.key, required this.event, this.participant});

  @override
  State<ParticipantFormScreen> createState() => _ParticipantFormScreenState();
}

class _ParticipantFormScreenState extends State<ParticipantFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = ParticipantService();
  bool _loading = false;

  late final TextEditingController _name;
  late final TextEditingController _ville;
  late final TextEditingController _email;
  late final TextEditingController _tele;
  late final TextEditingController _labo;
  String _typeInscri = 'participant';
  String _paymentStatus = 'non paye';

  final _types = ['participant', 'speaker', 'moderateur', 'vip', 'accompagnateur', 'medecin'];
  final _paymentStatuses = ['non paye', 'paye', 'pec'];

  @override
  void initState() {
    super.initState();
    final p = widget.participant;
    _name = TextEditingController(text: p?.nmComplet ?? '');
    _ville = TextEditingController(text: p?.ville ?? '');
    _email = TextEditingController(text: p?.email ?? '');
    _tele = TextEditingController(text: p?.tele ?? '');
    _labo = TextEditingController(text: p?.laboratoire ?? '');
    if (p != null) {
      _typeInscri = p.typeInscri ?? 'participant';
      _paymentStatus = p.paymentStatus;
    }
  }

  @override
  void dispose() {
    _name.dispose(); _ville.dispose(); _email.dispose();
    _tele.dispose(); _labo.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final data = {
      'NmComplet': _name.text.trim(),
      'ville': _ville.text.trim(),
      'email': _email.text.trim(),
      'tele': _tele.text.trim(),
      'aboratoire': _labo.text.trim(),
      'typeInscri': _typeInscri,
      'paymentstatus': _paymentStatus,
    };

    try {
      if (widget.participant == null) {
        await _service.createParticipant(widget.event.id, data);
      } else {
        await _service.updateParticipant(widget.event.id, widget.participant!.id, data);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.participant != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Participant' : 'New Participant')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Full Name *', border: OutlineInputBorder()),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _tele,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ville,
                decoration: const InputDecoration(labelText: 'City', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _labo,
                decoration: const InputDecoration(labelText: 'Laboratory / Organization', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _typeInscri,
                decoration: const InputDecoration(labelText: 'Registration Type', border: OutlineInputBorder()),
                items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setState(() => _typeInscri = v!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _paymentStatus,
                decoration: const InputDecoration(labelText: 'Payment Status', border: OutlineInputBorder()),
                items: _paymentStatuses.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setState(() => _paymentStatus = v!),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(isEdit ? 'Update Participant' : 'Add Participant'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
