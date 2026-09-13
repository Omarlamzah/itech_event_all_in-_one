import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _key = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _specialty = TextEditingController();
  final _phone = TextEditingController();
  final _city = TextEditingController();
  final _institution = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    for (final controller in [
      _name,
      _email,
      _password,
      _specialty,
      _phone,
      _city,
      _institution,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_key.currentState!.validate()) return;
    setState(() => _loading = true);
    final auth = context.read<AuthProvider>();
    final success = await auth.register(
      name: _name.text.trim(),
      email: _email.text.trim(),
      password: _password.text,
      specialty: _specialty.text.trim(),
      phone: _phone.text.trim(),
      city: _city.text.trim(),
      institution: _institution.text.trim(),
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (success) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Impossible de créer le compte.'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Créer mon compte')),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Form(
              key: _key,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Compte médecin',
                    style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Un seul compte pour vos congrès, badges et programmes personnalisés.',
                    style: TextStyle(color: Color(0xFF687973), height: 1.4),
                  ),
                  const SizedBox(height: 24),
                  _field(
                    _name,
                    label: 'Nom complet *',
                    icon: Icons.person_rounded,
                  ),
                  _field(
                    _email,
                    label: 'Email professionnel *',
                    icon: Icons.alternate_email_rounded,
                    type: TextInputType.emailAddress,
                    validator: (value) =>
                        value == null ||
                            !RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value)
                        ? 'Email invalide'
                        : null,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 13),
                    child: TextFormField(
                      controller: _password,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: 'Mot de passe *',
                        prefixIcon: const Icon(Icons.lock_rounded),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_rounded
                                : Icons.visibility_off_rounded,
                          ),
                        ),
                      ),
                      validator: (value) => (value?.length ?? 0) < 8
                          ? 'Minimum 8 caractères'
                          : null,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      'Informations professionnelles',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _field(
                    _specialty,
                    label: 'Spécialité',
                    icon: Icons.medical_services_rounded,
                    required: false,
                  ),
                  _field(
                    _institution,
                    label: 'Établissement / Cabinet',
                    icon: Icons.local_hospital_rounded,
                    required: false,
                  ),
                  _field(
                    _phone,
                    label: 'Téléphone',
                    icon: Icons.phone_rounded,
                    type: TextInputType.phone,
                    required: false,
                  ),
                  _field(
                    _city,
                    label: 'Ville',
                    icon: Icons.location_city_rounded,
                    required: false,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: _loading ? null : _submit,
                      icon: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.person_add_alt_1_rounded),
                      label: Text(
                        _loading ? 'Création…' : 'Créer mon compte iTechEvent',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _field(
    TextEditingController controller, {
    required String label,
    required IconData icon,
    TextInputType? type,
    bool required = true,
    String? Function(String?)? validator,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 13),
    child: TextFormField(
      controller: controller,
      keyboardType: type,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      validator:
          validator ??
          (required
              ? (value) => value?.trim().isEmpty == true ? 'Champ requis' : null
              : null),
    ),
  );
}
