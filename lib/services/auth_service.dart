import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

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

      if (kDebugMode) {
        debugPrint('[AuthService] Attempting registration for: $email');
      }

      final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      final uid = credential.user!.uid;

      // Update display name
      await credential.user!.updateDisplayName(name);

      // Create Firestore user profile
      final user = AppUser(id: uid, name: name, email: email, role: 'admin');
      try {
        await _db.collection('users').doc(uid).set(user.toJson());
      } catch (dbErr) {
        // Profile save failed but auth succeeded - still OK
        if (kDebugMode) {
          debugPrint('[AuthService] Profile save warning: $dbErr');
        }
      }

      return (ok: true, message: '注册成功', user: user);
    } on FirebaseAuthException catch (e) {
      return (ok: false, message: _authErrorMessage(e.code), user: null);
    } catch (e) {
      // Catch all errors and extract meaningful message
      final errStr = e.toString();
      if (kDebugMode) {
        debugPrint('[AuthService] Registration error: $errStr');
      }

      // Parse Firebase error codes from generic exceptions
      if (errStr.contains('email-already-in-use')) {
        return (ok: false, message: '该邮箱已注册', user: null);
      } else if (errStr.contains('invalid-email')) {
        return (ok: false, message: '邮箱格式不正确', user: null);
      } else if (errStr.contains('weak-password')) {
        return (ok: false, message: '密码强度不够，至少6位', user: null);
      } else if (errStr.contains('network-request-failed')) {
        return (ok: false, message: '网络连接失败，请检查网络', user: null);
      } else if (errStr.contains('operation-not-allowed')) {
        return (ok: false, message: 'Email/Password 登录未启用，请在 Firebase Console 中启用', user: null);
      }
      return (ok: false, message: '注册失败: $errStr', user: null);
    }
  }

  /// 登录 — Firebase Auth
  Future<({bool ok, String message, AppUser? user})> login(String email, String password) async {
    try {
      if (kDebugMode) {
        debugPrint('[AuthService] Attempting login for: $email');
      }

      final credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      final uid = credential.user!.uid;

      // Get or create Firestore user profile
      AppUser user;
      try {
        final doc = await _db.collection('users').doc(uid).get();
        if (doc.exists && doc.data() != null) {
          user = AppUser.fromJson(doc.data()!);
        } else {
          user = AppUser(
            id: uid,
            name: credential.user!.displayName ?? email.split('@').first,
            email: email,
          );
          await _db.collection('users').doc(uid).set(user.toJson());
        }
      } catch (dbErr) {
        // DB access failed but auth succeeded
        user = AppUser(
          id: uid,
          name: credential.user!.displayName ?? email.split('@').first,
          email: email,
        );
      }

      return (ok: true, message: '登录成功', user: user);
    } on FirebaseAuthException catch (e) {
      return (ok: false, message: _authErrorMessage(e.code), user: null);
    } catch (e) {
      final errStr = e.toString();
      if (kDebugMode) {
        debugPrint('[AuthService] Login error: $errStr');
      }

      if (errStr.contains('user-not-found')) {
        return (ok: false, message: '账号不存在', user: null);
      } else if (errStr.contains('wrong-password') || errStr.contains('invalid-credential')) {
        return (ok: false, message: '邮箱或密码错误', user: null);
      } else if (errStr.contains('user-disabled')) {
        return (ok: false, message: '账号已被禁用', user: null);
      } else if (errStr.contains('network-request-failed')) {
        return (ok: false, message: '网络连接失败，请检查网络', user: null);
      }
      return (ok: false, message: '登录失败: $errStr', user: null);
    }
  }

  /// 获取当前登录用户
  Future<AppUser?> getCurrentUser() async {
    final fbUser = _auth.currentUser;
    if (fbUser == null) return null;
    try {
      final doc = await _db.collection('users').doc(fbUser.uid).get();
      if (doc.exists && doc.data() != null) return AppUser.fromJson(doc.data()!);
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
    } catch (e) {
      final errStr = e.toString();
      if (errStr.contains('user-not-found')) {
        return (ok: false, message: '该邮箱未注册');
      }
      return (ok: false, message: '发送失败: $errStr');
    }
  }

  /// 监听认证状态变化
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// 统一错误消息映射
  String _authErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use': return '该邮箱已注册';
      case 'invalid-email': return '邮箱格式不正确';
      case 'weak-password': return '密码强度不够，至少6位';
      case 'user-not-found': return '账号不存在';
      case 'wrong-password': return '密码错误';
      case 'invalid-credential': return '邮箱或密码错误';
      case 'user-disabled': return '账号已被禁用';
      case 'operation-not-allowed': return 'Email/Password 登录未启用';
      case 'network-request-failed': return '网络连接失败';
      case 'too-many-requests': return '请求过于频繁，请稍后再试';
      default: return '操作失败 ($code)';
    }
  }
}
