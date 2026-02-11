import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// App 用户信息 (Firebase Auth + Firestore profile)
class AppUser {
  final String id;
  final String name;
  final String email;
  final String role; // admin, manager, member
  final DateTime createdAt;

  AppUser({required this.id, required this.name, required this.email, this.role = 'admin', DateTime? createdAt})
    : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'email': email, 'role': role,
    'createdAt': createdAt.toIso8601String(),
  };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    email: json['email'] as String? ?? '',
    role: json['role'] as String? ?? 'admin',
    createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
  );
}

/// Firebase Auth 认证服务
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// 注册 — Firebase Auth + Firestore profile
  Future<({bool ok, String message, AppUser? user})> register(String name, String email, String password) async {
    try {
      if (password.length < 6) {
        return (ok: false, message: '密码至少6位', user: null);
      }

      final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      final uid = credential.user!.uid;

      // Update display name
      await credential.user!.updateDisplayName(name);

      // Create Firestore user profile
      final user = AppUser(id: uid, name: name, email: email, role: 'admin');
      await _db.collection('users').doc(uid).set(user.toJson());

      return (ok: true, message: '注册成功', user: user);
    } on FirebaseAuthException catch (e) {
      String msg;
      switch (e.code) {
        case 'email-already-in-use':
          msg = '该邮箱已注册';
          break;
        case 'invalid-email':
          msg = '邮箱格式不正确';
          break;
        case 'weak-password':
          msg = '密码强度不够，至少6位';
          break;
        default:
          msg = '注册失败: ${e.message}';
      }
      return (ok: false, message: msg, user: null);
    } catch (e) {
      return (ok: false, message: '注册失败: $e', user: null);
    }
  }

  /// 登录 — Firebase Auth
  Future<({bool ok, String message, AppUser? user})> login(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      final uid = credential.user!.uid;

      // Get or create Firestore user profile
      final doc = await _db.collection('users').doc(uid).get();
      AppUser user;
      if (doc.exists) {
        user = AppUser.fromJson(doc.data()!);
      } else {
        user = AppUser(
          id: uid,
          name: credential.user!.displayName ?? email.split('@').first,
          email: email,
        );
        await _db.collection('users').doc(uid).set(user.toJson());
      }

      return (ok: true, message: '登录成功', user: user);
    } on FirebaseAuthException catch (e) {
      String msg;
      switch (e.code) {
        case 'user-not-found':
          msg = '账号不存在';
          break;
        case 'wrong-password':
          msg = '密码错误';
          break;
        case 'invalid-email':
          msg = '邮箱格式不正确';
          break;
        case 'user-disabled':
          msg = '账号已被禁用';
          break;
        case 'invalid-credential':
          msg = '邮箱或密码错误';
          break;
        default:
          msg = '登录失败: ${e.message}';
      }
      return (ok: false, message: msg, user: null);
    } catch (e) {
      return (ok: false, message: '登录失败: $e', user: null);
    }
  }

  /// 获取当前登录用户
  Future<AppUser?> getCurrentUser() async {
    final fbUser = _auth.currentUser;
    if (fbUser == null) return null;
    try {
      final doc = await _db.collection('users').doc(fbUser.uid).get();
      if (doc.exists) return AppUser.fromJson(doc.data()!);
      return AppUser(
        id: fbUser.uid,
        name: fbUser.displayName ?? fbUser.email?.split('@').first ?? '',
        email: fbUser.email ?? '',
      );
    } catch (_) {
      return AppUser(
        id: fbUser.uid,
        name: fbUser.displayName ?? '',
        email: fbUser.email ?? '',
      );
    }
  }

  /// 登出
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// 检查是否已登录
  Future<bool> isLoggedIn() async {
    return _auth.currentUser != null;
  }

  /// 重置密码
  Future<({bool ok, String message})> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return (ok: true, message: '密码重置邮件已发送到 $email');
    } on FirebaseAuthException catch (e) {
      return (ok: false, message: '发送失败: ${e.message}');
    } catch (e) {
      return (ok: false, message: '发送失败: $e');
    }
  }

  /// 监听认证状态变化
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
