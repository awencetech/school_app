/// User model for the education app.
class User {
  User({
    required this.userId,
    required this.email,
    required this.role,
    this.id,
    this.token,
  });

  final String? id;
  final String userId;
  final String email;
  final String role; // 'student', 'staff', or 'admin'
  final String? token;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String?,
      userId: json['userId'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'student',
      token: json['token'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'email': email,
      'role': role,
    };
  }
}
