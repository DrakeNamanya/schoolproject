/// Roles in the Timbitwire system. One account may hold several.
enum UserRole {
  parent,
  teacher, // staff app + marks entry + roll call
  staff, // non-teaching staff (matron, driver, cook without kitchen admin)
  director,
  bursar,
  dos, // Director of Studies
  nurse,
  cook, // head cook / kitchen admin
  registrar,
  admin; // IT / system administrator

  static UserRole fromKey(String key) => UserRole.values.firstWhere(
    (r) => r.name == key,
    orElse: () => UserRole.parent,
  );

  String get label => switch (this) {
    UserRole.parent => 'Parent / Guardian',
    UserRole.teacher => 'Teacher',
    UserRole.staff => 'Staff',
    UserRole.director => 'Director',
    UserRole.bursar => 'Bursar',
    UserRole.dos => 'Director of Studies',
    UserRole.nurse => 'Nurse',
    UserRole.cook => 'Kitchen',
    UserRole.registrar => 'Registrar',
    UserRole.admin => 'Administrator',
  };

  /// Which shell this role opens into.
  AppShell get shell => switch (this) {
    UserRole.parent => AppShell.parent,
    UserRole.teacher || UserRole.staff => AppShell.staff,
    _ => AppShell.admin,
  };
}

enum AppShell { parent, staff, admin }

class AppUser {
  final String id;
  final String fullName;
  final String? phone;
  final String? email;
  final List<UserRole> roles;
  final String? title; // Ms., Mr., Nurse, Dr.

  const AppUser({
    required this.id,
    required this.fullName,
    required this.roles,
    this.phone,
    this.email,
    this.title,
  });

  String get displayName => title == null ? fullName : '$title $fullName';

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  bool has(UserRole r) => roles.contains(r);

  factory AppUser.fromMap(Map<String, dynamic> m) => AppUser(
    id: m['id'] as String,
    fullName: (m['full_name'] as String?) ?? '',
    phone: m['phone'] as String?,
    email: m['email'] as String?,
    title: m['title'] as String?,
    roles: ((m['roles'] as List?) ?? const [])
        .map((e) => UserRole.fromKey(e.toString()))
        .toList(),
  );
}
