// User model — base for Customer and BusinessOwner

enum UserRole { customer, businessOwner }

class User {
  final String id;
  final String name;
  final String email;
  final String passwordHash;
  final UserRole role;
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.passwordHash,
    required this.role,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role.name,
        'createdAt': createdAt.toIso8601String(),
      };

  @override
  String toString() => 'User(id=$id, name=$name, role=${role.name})';
}
