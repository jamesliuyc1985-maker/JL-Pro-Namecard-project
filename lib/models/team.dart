class TeamMember {
  String id;
  String name;
  String role; // admin, manager, member
  String email;
  String phone;
  String avatar;
  bool isActive;
  DateTime createdAt;

  TeamMember({
    required this.id,
    required this.name,
    this.role = 'member',
    this.email = '',
    this.phone = '',
    this.avatar = '',
    this.isActive = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'role': role, 'email': email,
    'phone': phone, 'avatar': avatar, 'isActive': isActive,
    'createdAt': createdAt.toIso8601String(),
  };

  factory TeamMember.fromJson(Map<String, dynamic> json) => TeamMember(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    role: json['role'] as String? ?? 'member',
    email: json['email'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    avatar: json['avatar'] as String? ?? '',
    isActive: json['isActive'] as bool? ?? true,
    createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
  );

  static String roleLabel(String r) {
    switch (r) {
      case 'admin': return '管理员';
      case 'manager': return '经理';
      case 'member': return '成员';
      default: return r;
    }
  }
}
