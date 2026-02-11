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

  static String roleLabel(String r) {
    switch (r) {
      case 'admin': return '管理员';
      case 'manager': return '经理';
      case 'member': return '成员';
      default: return r;
    }
  }
}
