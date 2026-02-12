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

/// Firebase Auth 服务
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// 当前 Firebase User
  User? get currentFirebaseUser => _auth.currentUser;

  /// 监听登录状态
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// 邮箱注册
  Future<AppUser> register(String email, String password, String displayName) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    final user = cred.user!;
    await user.updateDisplayName(displayName);

    final appUser = AppUser(
      uid: user.uid,
      email: email,
      displayName: displayName,
      role: UserRole.member,
      lastLoginAt: DateTime.now(),
    );

    // 保存到 Firestore
    await _db.collection('users').doc(user.uid).set(appUser.toJson());
    return appUser;
  }

  /// 邮箱登录
  Future<AppUser> login(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
    final user = cred.user!;

    // 从 Firestore 获取用户信息
    final doc = await _db.collection('users').doc(user.uid).get();
    if (doc.exists) {
      final appUser = AppUser.fromJson(doc.data()!);
      appUser.lastLoginAt = DateTime.now();
      await _db.collection('users').doc(user.uid).update({'lastLoginAt': DateTime.now().toIso8601String()});
      return appUser;
    } else {
      // Firestore 没有记录，创建一个
      final appUser = AppUser(
        uid: user.uid,
        email: email,
        displayName: user.displayName ?? email.split('@').first,
        lastLoginAt: DateTime.now(),
      );
      await _db.collection('users').doc(user.uid).set(appUser.toJson());
      return appUser;
    }
  }

  /// 获取当前 AppUser
  Future<AppUser?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    try {
      final doc = await _db.collection('users').doc(user.uid).get();
      if (doc.exists) return AppUser.fromJson(doc.data()!);
      return AppUser(uid: user.uid, email: user.email ?? '', displayName: user.displayName ?? '');
    } catch (e) {
      if (kDebugMode) debugPrint('[AuthService] getCurrentUser error: $e');
      return AppUser(uid: user.uid, email: user.email ?? '', displayName: user.displayName ?? '');
    }
  }

  /// 获取所有用户 (管理员用)
  Future<List<AppUser>> getAllUsers() async {
    try {
      final snap = await _db.collection('users').get();
      return snap.docs.map((d) => AppUser.fromJson(d.data())).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('[AuthService] getAllUsers error: $e');
      return [];
    }
  }

  /// 更新用户角色
  Future<void> updateUserRole(String uid, UserRole role) async {
    await _db.collection('users').doc(uid).update({'role': role.name});
  }

  /// 更新个人信息
  Future<void> updateProfile(String uid, String displayName) async {
    await _db.collection('users').doc(uid).update({'displayName': displayName});
    await _auth.currentUser?.updateDisplayName(displayName);
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
