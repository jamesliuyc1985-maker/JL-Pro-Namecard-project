import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 用户信息
class AppUser {
  final String id;
  final String name;
  final String email;
  final String role; // admin, manager, member
  final DateTime createdAt;

  AppUser({required this.id, required this.name, required this.email, this.role = 'admin', DateTime? createdAt})
    : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'email': email, 'role': role, 'createdAt': createdAt.toIso8601String()};
  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: json['id'] as String, name: json['name'] as String, email: json['email'] as String,
    role: json['role'] as String? ?? 'admin', createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now());
}

/// 认证服务 (本地存储)
class AuthService {
  static const _usersKey = 'crm_users';
  static const _sessionKey = 'crm_session';

  /// 注册
  Future<({bool ok, String message, AppUser? user})> register(String name, String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey);
    final users = <String, dynamic>{};
    if (usersJson != null) { users.addAll(jsonDecode(usersJson) as Map<String, dynamic>); }

    if (users.containsKey(email)) {
      return (ok: false, message: '该邮箱已注册', user: null);
    }
    if (password.length < 6) {
      return (ok: false, message: '密码至少6位', user: null);
    }

    final id = 'user_${DateTime.now().millisecondsSinceEpoch}';
    final hashed = _hashPassword(password);
    final user = AppUser(id: id, name: name, email: email);
    users[email] = {'password': hashed, 'user': user.toJson()};
    await prefs.setString(_usersKey, jsonEncode(users));
    await _saveSession(user);
    return (ok: true, message: '注册成功', user: user);
  }

  /// 登录
  Future<({bool ok, String message, AppUser? user})> login(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey);
    if (usersJson == null) return (ok: false, message: '账号不存在', user: null);

    final users = jsonDecode(usersJson) as Map<String, dynamic>;
    if (!users.containsKey(email)) return (ok: false, message: '账号不存在', user: null);

    final record = users[email] as Map<String, dynamic>;
    final hashed = _hashPassword(password);
    if (record['password'] != hashed) return (ok: false, message: '密码错误', user: null);

    final user = AppUser.fromJson(record['user'] as Map<String, dynamic>);
    await _saveSession(user);
    return (ok: true, message: '登录成功', user: user);
  }

  /// 获取当前会话
  Future<AppUser?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionJson = prefs.getString(_sessionKey);
    if (sessionJson == null) return null;
    try { return AppUser.fromJson(jsonDecode(sessionJson) as Map<String, dynamic>); } catch (_) { return null; }
  }

  /// 登出
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }

  /// 检查是否已登录
  Future<bool> isLoggedIn() async {
    return (await getCurrentUser()) != null;
  }

  Future<void> _saveSession(AppUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, jsonEncode(user.toJson()));
  }

  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }
}
