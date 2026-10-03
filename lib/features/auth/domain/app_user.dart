class AppUser {
  final String id;
  final String email;
  final String? displayName;
  final bool emailVerified;

  const AppUser({
    required this.id,
    required this.email,
    this.displayName,
    required this.emailVerified,
  });

  AppUser copyWith({
    String? id,
    String? email,
    String? displayName,
    bool? emailVerified,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      emailVerified: emailVerified ?? this.emailVerified,
    );
  }
}
