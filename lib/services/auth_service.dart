import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// 用户角色
enum UserRole { admin, manager, member }

/// 应用用户模型
class AppUser {
  final String uid;
  final String email;
  String displayName;
  UserRole role;
  DateTime createdAt;
  DateTime? lastLoginAt;

  AppUser({
    required this.uid,
    required this.email,
    this.displayName = '',
    this.role = UserRole.member,
    DateTime? createdAt,
    this.lastLoginAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'email': email,
    'displayName': displayName,
    'role': role.name,
    'createdAt': createdAt.toIso8601String(),
    'lastLoginAt': lastLoginAt?.toIso8601String(),
  };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    uid: json['uid'] as String? ?? '',
    email: json['email'] as String? ?? '',
    displayName: json['displayName'] as String? ?? '',
    role: UserRole.values.firstWhere(
      (e) => e.name == json['role'], orElse: () => UserRole.member,
    ),
    createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    lastLoginAt: json['lastLoginAt'] != null ? DateTime.tryParse(json['lastLoginAt']) : null,
  );
}

/// 全局超时时间
const _timeout = Duration(seconds: 6);

/// Firebase Auth 服务（所有网络调用带超时保护）
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// 当前 Firebase User
  User? get currentFirebaseUser => _auth.currentUser;

  /// 监听登录状态
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// 邮箱注册
  Future<AppUser> register(String email, String password, String displayName) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email, password: password,
    ).timeout(_timeout);
    final user = cred.user!;
    // updateDisplayName 不阻塞
    user.updateDisplayName(displayName).catchError((_) {});

    final appUser = AppUser(
      uid: user.uid,
      email: email,
      displayName: displayName,
      role: UserRole.member,
      lastLoginAt: DateTime.now(),
    );

    // 后台保存到 Firestore，不阻塞注册流程
    _db.collection('users').doc(user.uid).set(appUser.toJson()).catchError((e) {
      if (kDebugMode) debugPrint('[AuthService] save user profile error: $e');
    });
    return appUser;
  }

  /// 邮箱登录
  Future<AppUser> login(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email, password: password,
    ).timeout(_timeout);
    final user = cred.user!;

    // 尝试从 Firestore 获取用户信息（带超时）
    try {
      final doc = await _db.collection('users').doc(user.uid).get()
          .timeout(const Duration(seconds: 4));
      if (doc.exists) {
        final appUser = AppUser.fromJson(doc.data()!);
        appUser.lastLoginAt = DateTime.now();
        // 后台更新 lastLogin
        _db.collection('users').doc(user.uid).update({
          'lastLoginAt': DateTime.now().toIso8601String(),
        }).catchError((_) {});
        return appUser;
      }
    } catch (_) {
      // Firestore 超时/失败，用 Auth 信息构建
    }

    // 降级：用 Firebase Auth 基本信息
    final appUser = AppUser(
      uid: user.uid,
      email: email,
      displayName: user.displayName ?? email.split('@').first,
      lastLoginAt: DateTime.now(),
    );
    // 后台创建 Firestore 记录
    _db.collection('users').doc(user.uid).set(appUser.toJson()).catchError((_) {});
    return appUser;
  }

  /// 获取当前 AppUser（带超时，失败返回基本信息）
  Future<AppUser?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    // 先用 Auth 基本信息构建默认值
    final fallback = AppUser(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? '',
      role: UserRole.admin, // 默认 admin（单用户模式）
    );

    try {
      final doc = await _db.collection('users').doc(user.uid).get()
          .timeout(const Duration(seconds: 4));
      if (doc.exists) return AppUser.fromJson(doc.data()!);
      return fallback;
    } catch (e) {
      if (kDebugMode) debugPrint('[AuthService] getCurrentUser timeout/error: $e');
      return fallback;
    }
  }

  /// 获取所有用户（带超时）
  Future<List<AppUser>> getAllUsers() async {
    try {
      final snap = await _db.collection('users').get()
          .timeout(const Duration(seconds: 4));
      return snap.docs.map((d) => AppUser.fromJson(d.data())).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('[AuthService] getAllUsers timeout/error: $e');
      return [];
    }
  }

  /// 更新用户角色
  Future<void> updateUserRole(String uid, UserRole role) async {
    await _db.collection('users').doc(uid).update({'role': role.name})
        .timeout(_timeout);
  }

  /// 更新个人信息
  Future<void> updateProfile(String uid, String displayName) async {
    await _db.collection('users').doc(uid).update({'displayName': displayName})
        .timeout(_timeout);
    _auth.currentUser?.updateDisplayName(displayName).catchError((_) {});
  }

  /// 修改密码
  Future<void> changePassword(String newPassword) async {
    await _auth.currentUser?.updatePassword(newPassword);
  }

  /// 登出
  Future<void> logout() async {
    await _auth.signOut();
  }
}
