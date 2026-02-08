class AppUser {
  final String id;
  final String email;
  final bool isApproved;

  AppUser({
    required this.id,
    required this.email,
    this.isApproved = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'isApproved': isApproved,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'],
      email: map['email'],
      isApproved: map['isApproved'] ?? false,
    );
  }
}
