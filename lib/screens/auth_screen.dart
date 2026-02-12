import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/theme.dart';

class AuthScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  const AuthScreen({super.key, required this.onLoginSuccess});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  bool _isLoading = false;
  String? _error;
  bool _obscurePassword = true;

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _auth = AuthService();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _error = null; });

    try {
      if (_isLogin) {
        await _auth.login(_emailCtrl.text.trim(), _passwordCtrl.text);
      } else {
        await _auth.register(
          _emailCtrl.text.trim(),
          _passwordCtrl.text,
          _nameCtrl.text.trim(),
        );
      }
      widget.onLoginSuccess();
    } catch (e) {
      String msg = e.toString();
      if (msg.contains('user-not-found')) msg = '用户不存在';
      else if (msg.contains('wrong-password') || msg.contains('invalid-credential')) msg = '密码错误';
      else if (msg.contains('email-already-in-use')) msg = '邮箱已注册';
      else if (msg.contains('weak-password')) msg = '密码至少6位';
      else if (msg.contains('invalid-email')) msg = '邮箱格式不正确';
      else if (msg.contains('network-request-failed')) msg = '网络连接失败';
      setState(() => _error = msg);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Form(
              key: _formKey,
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                // Logo
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    gradient: AppTheme.gradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: AppTheme.primaryPurple.withValues(alpha: 0.4), blurRadius: 20)],
                  ),
                  child: const Icon(Icons.handshake_rounded, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 24),
                const Text('Deal Navigator', style: TextStyle(color: AppTheme.textPrimary, fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(_isLogin ? '登录您的账户' : '创建新账户',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                const SizedBox(height: 32),

                // Error
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.error_outline, color: AppTheme.danger, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_error!, style: const TextStyle(color: AppTheme.danger, fontSize: 13))),
                    ]),
                  ),
                  const SizedBox(height: 16),
                ],

                // Name (register only)
                if (!_isLogin) ...[
                  TextFormField(
                    controller: _nameCtrl,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: _inputDecoration('姓名', Icons.person),
                    validator: (v) => v != null && v.trim().isNotEmpty ? null : '请输入姓名',
                  ),
                  const SizedBox(height: 14),
                ],

                // Email
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: _inputDecoration('邮箱', Icons.email),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return '请输入邮箱';
                    if (!v.contains('@') || !v.contains('.')) return '邮箱格式不正确';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Password
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: _inputDecoration('密码', Icons.lock).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: AppTheme.textSecondary, size: 20),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return '请输入密码';
                    if (v.length < 6) return '密码至少6位';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Submit
                SizedBox(
                  width: double.infinity, height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryPurple,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(_isLogin ? '登录' : '注册', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 16),

                // Toggle login/register
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(_isLogin ? '还没有账户? ' : '已有账户? ',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  GestureDetector(
                    onTap: () => setState(() { _isLogin = !_isLogin; _error = null; }),
                    child: Text(_isLogin ? '立即注册' : '登录',
                      style: const TextStyle(color: AppTheme.primaryPurple, fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ]),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppTheme.textSecondary),
      prefixIcon: Icon(icon, color: AppTheme.textSecondary, size: 20),
      filled: true,
      fillColor: AppTheme.cardBg,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primaryPurple, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.danger),
      ),
    );
  }
}
