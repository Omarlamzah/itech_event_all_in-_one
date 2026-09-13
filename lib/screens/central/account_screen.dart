import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../login_screen.dart';
import '../main_screen.dart';
import '../register_screen.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isAuthenticated) return const _GuestAccount();

    final user = auth.user!;
    final profile = user.doctorProfile ?? const <String, dynamic>{};
    final specialty = profile['specialty']?.toString();
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 22, 18, 115),
        children: [
          const Text(
            'MON ESPACE',
            style: TextStyle(
              color: Color(0xFF0B7A69),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Mon profil',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF063C49), Color(0xFF0B7A69)],
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x30066D60),
                  blurRadius: 30,
                  offset: Offset(0, 15),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 68,
                  height: 68,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .15),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Text(
                    _initials(user.name),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      if (specialty?.isNotEmpty == true) ...[
                        const SizedBox(height: 7),
                        Text(
                          specialty!,
                          style: const TextStyle(
                            color: Color(0xFFFFD884),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    _roleLabel(user.role),
                    style: const TextStyle(
                      color: Color(0xFF075E54),
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _SettingsTile(
            icon: Icons.manage_accounts_rounded,
            title: 'Informations personnelles',
            subtitle: 'Nom, spécialité, ville et établissement',
            onTap: () {},
          ),
          const _SettingsTile(
            icon: Icons.notifications_active_rounded,
            title: 'Notifications',
            subtitle: 'Rappels des sessions et actualités',
          ),
          const _SettingsTile(
            icon: Icons.language_rounded,
            title: 'Langue',
            subtitle: 'Français',
          ),
          const _SettingsTile(
            icon: Icons.help_outline_rounded,
            title: 'Aide et assistance',
            subtitle: 'Contacter l’équipe iTechEvent',
          ),
          if (user.canUseStaffTools) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3DE),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFFFDB9E)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Espace équipe',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Scanner les badges et accéder aux outils autorisés pour votre rôle.',
                    style: TextStyle(color: Color(0xFF72531D), fontSize: 12),
                  ),
                  const SizedBox(height: 13),
                  FilledButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MainScreen()),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF9A6411),
                    ),
                    icon: const Icon(Icons.admin_panel_settings_rounded),
                    label: const Text('Ouvrir les outils staff'),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: () async => auth.logout(),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade700,
            ),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts
        .take(2)
        .where((part) => part.isNotEmpty)
        .map((part) => part[0])
        .join()
        .toUpperCase();
  }

  static String _roleLabel(String role) => switch (role) {
    'admin' => 'ADMIN',
    'developer' => 'DEV',
    'doctor' => 'MÉDECIN',
    _ => 'STAFF',
  };
}

class _GuestAccount extends StatelessWidget {
  const _GuestAccount();

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Column(
            children: [
              Container(
                width: 94,
                height: 94,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x25106359),
                      blurRadius: 30,
                      offset: Offset(0, 15),
                    ),
                  ],
                ),
                child: Image.asset('assets/icon/app_icon.png'),
              ),
              const SizedBox(height: 24),
              const Text(
                'Votre espace iTechEvent',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 9),
              const Text(
                'Connectez-vous comme médecin, participant ou membre du staff avec le même écran.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF687973), height: 1.45),
              ),
              const SizedBox(height: 26),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ),
                  icon: const Icon(Icons.login_rounded),
                  label: const Text('Se connecter'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  ),
                  icon: const Icon(Icons.person_add_alt_1_rounded),
                  label: const Text('Créer un compte médecin'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 9),
    child: ListTile(
      onTap: onTap,
      leading: Container(
        width: 43,
        height: 43,
        decoration: BoxDecoration(
          color: const Color(0xFFE5F4F0),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: const Color(0xFF087A69)),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
      ),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
      trailing: const Icon(Icons.chevron_right_rounded),
    ),
  );
}
