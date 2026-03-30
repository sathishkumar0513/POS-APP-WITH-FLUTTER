class UserModel {
  final int? id;
  final String name;
  final String username;
  final String password;
  final String role; // 'admin' or 'cashier'
  final bool isActive;

  UserModel({
    this.id,
    required this.name,
    required this.username,
    required this.password,
    required this.role,
    this.isActive = true,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      name: map['name'],
      username: map['username'],
      password: map['password'],
      role: map['role'],
      isActive: map['is_active'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'username': username,
      'password': password,
      'role': role,
      'is_active': isActive ? 1 : 0,
    };
  }

  UserModel copyWith({
    int? id,
    String? name,
    String? username,
    String? password,
    String? role,
    bool? isActive,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      password: password ?? this.password,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
    );
  }
}
