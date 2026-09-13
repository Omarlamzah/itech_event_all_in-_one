class User {
  final int id;
  final String name;
  final String email;
  final bool isAdmin;
  final String role;
  final Map<String, dynamic>? doctorProfile;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.isAdmin,
    required this.role,
    this.doctorProfile,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      isAdmin: json['is_admin'] == 1 || json['is_admin'] == true,
      role:
          (json['role'] ??
                  ((json['is_admin'] == 1 || json['is_admin'] == true)
                      ? 'admin'
                      : 'doctor'))
              .toString(),
      doctorProfile: json['doctor_profile'] is Map
          ? Map<String, dynamic>.from(json['doctor_profile'] as Map)
          : null,
    );
  }

  bool get isDoctor => role == 'doctor';

  bool get canUseStaffTools =>
      isAdmin ||
      const {
        'admin',
        'developer',
        'event_manager',
        'team_leader',
        'team_member',
        'checkin_staff',
        'badge_staff',
        'supplier_manager',
        'finance',
      }.contains(role);
}
