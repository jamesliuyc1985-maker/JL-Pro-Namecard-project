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
              const SizedBox(height: 32),

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

              const SizedBox(height: 16),

              // Toggle
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(_isLogin ? '没有账户？' : '已有账户？', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                TextButton(
                  onPressed: () => setState(() { _isLogin = !_isLogin; _error = null; }),
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
    setState(() { _error = null; _isLoading = true; });

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
}
