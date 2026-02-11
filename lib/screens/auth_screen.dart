import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/theme.dart';

class AuthScreen extends StatefulWidget {
  final VoidCallback onAuthenticated;
  const AuthScreen({super.key, required this.onAuthenticated});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscure = true;
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _authService = AuthService();
  String? _error;
  String? _success;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // Logo
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(gradient: AppTheme.gradient, borderRadius: BorderRadius.circular(24)),
                child: const Center(child: Text('DN', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold))),
              ),
              const SizedBox(height: 16),
              const Text('Deal Navigator', style: TextStyle(color: AppTheme.textPrimary, fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(_isLogin ? '登录到您的账户' : '创建新账户', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
              const SizedBox(height: 8),
              // Firebase badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.cloud_done, color: Colors.orange, size: 14),
                  SizedBox(width: 4),
                  Text('Firebase 云端认证', style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.w600)),
                ]),
              ),
              const SizedBox(height: 24),

              // Name (register only)
              if (!_isLogin) ...[
                _inputField(_nameCtrl, '姓名', Icons.person, TextInputType.name),
                const SizedBox(height: 12),
              ],

              // Email
              _inputField(_emailCtrl, '邮箱', Icons.email, TextInputType.emailAddress),
              const SizedBox(height: 12),

              // Password
              TextField(
                controller: _passwordCtrl,
                obscureText: _obscure,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  labelText: '密码',
                  prefixIcon: const Icon(Icons.lock, color: AppTheme.textSecondary, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: AppTheme.textSecondary, size: 20),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),

              // Confirm password (register only)
              if (!_isLogin) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _confirmCtrl,
                  obscureText: true,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(labelText: '确认密码', prefixIcon: Icon(Icons.lock_outline, color: AppTheme.textSecondary, size: 20)),
                ),
              ],

              // Error
              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppTheme.danger.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                  child: Row(children: [
                    const Icon(Icons.error_outline, color: AppTheme.danger, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error!, style: const TextStyle(color: AppTheme.danger, fontSize: 12))),
                  ]),
                ),
              ],

              // Success message
              if (_success != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppTheme.success.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                  child: Row(children: [
                    const Icon(Icons.check_circle_outline, color: AppTheme.success, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_success!, style: const TextStyle(color: AppTheme.success, fontSize: 12))),
                  ]),
                ),
              ],

              const SizedBox(height: 24),

              // Submit
              SizedBox(
                width: double.infinity, height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(_isLogin ? '登录' : '注册', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),

              // Forgot password (login only)
              if (_isLogin) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _isLoading ? null : _forgotPassword,
                  child: const Text('忘记密码？', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                ),
              ],

              const SizedBox(height: 8),

              // Toggle
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(_isLogin ? '没有账户？' : '已有账户？', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                TextButton(
                  onPressed: () => setState(() { _isLogin = !_isLogin; _error = null; _success = null; }),
                  child: Text(_isLogin ? '立即注册' : '去登录', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _inputField(TextEditingController ctrl, String label, IconData icon, TextInputType type) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, color: AppTheme.textSecondary, size: 20)),
    );
  }

  Future<void> _submit() async {
    setState(() { _error = null; _success = null; _isLoading = true; });

    if (_isLogin) {
      if (_emailCtrl.text.isEmpty || _passwordCtrl.text.isEmpty) {
        setState(() { _error = '请填写邮箱和密码'; _isLoading = false; });
        return;
      }
      final result = await _authService.login(_emailCtrl.text.trim(), _passwordCtrl.text);
      if (result.ok) {
        widget.onAuthenticated();
      } else {
        setState(() { _error = result.message; _isLoading = false; });
      }
    } else {
      if (_nameCtrl.text.isEmpty || _emailCtrl.text.isEmpty || _passwordCtrl.text.isEmpty) {
        setState(() { _error = '请填写所有字段'; _isLoading = false; });
        return;
      }
      if (_passwordCtrl.text != _confirmCtrl.text) {
        setState(() { _error = '两次密码不一致'; _isLoading = false; });
        return;
      }
      final result = await _authService.register(_nameCtrl.text.trim(), _emailCtrl.text.trim(), _passwordCtrl.text);
      if (result.ok) {
        widget.onAuthenticated();
      } else {
        setState(() { _error = result.message; _isLoading = false; });
      }
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() { _error = '请先输入邮箱地址'; _success = null; });
      return;
    }
    setState(() { _isLoading = true; _error = null; _success = null; });
    final result = await _authService.resetPassword(email);
    setState(() {
      _isLoading = false;
      if (result.ok) {
        _success = result.message;
        _error = null;
      } else {
        _error = result.message;
        _success = null;
      }
    });
  }
}
