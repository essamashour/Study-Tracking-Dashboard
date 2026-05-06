import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'dashboard_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool isLogin = true;
  final AuthService _authService = AuthService();
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _loading) return;
    setState(() {
      _loading = true;
    });
    try {
      final email = _email.text.trim();
      final password = _password.text;
      final name = _name.text.trim();
      if (isLogin) {
        await _authService.signIn(email, password);
      } else {
        await _authService.signUp(name, email, password);
      }
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder<void>(
          pageBuilder: (_, __, ___) => const DashboardScreen(),
          transitionDuration: const Duration(milliseconds: 320),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
        (_) => false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _heroHeader(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            cs.primary.withValues(alpha: 0.95),
            cs.primaryContainer.withValues(alpha: 0.95),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Study Dashboard',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: cs.onPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'تابع كورساتك ومهامك وتقدمك في مكان واحد.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: cs.onPrimary.withValues(alpha: 0.92),
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: cs.onPrimary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.school_rounded, color: cs.onPrimary),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              children: [
                _heroHeader(context),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          isLogin ? 'تسجيل الدخول' : 'إنشاء حساب',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 12),
                        SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment(value: true, label: Text('دخول')),
                            ButtonSegment(value: false, label: Text('تسجيل')),
                          ],
                          selected: {isLogin},
                          onSelectionChanged: (v) =>
                              setState(() => isLogin = v.first),
                        ),
                        const SizedBox(height: 14),
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              if (!isLogin) ...[
                                TextFormField(
                                  controller: _name,
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(
                                    labelText: 'الاسم',
                                    prefixIcon: Icon(Icons.badge_outlined),
                                  ),
                                  validator: (v) => v == null || v.trim().isEmpty
                                      ? 'الاسم مطلوب'
                                      : null,
                                ),
                                const SizedBox(height: 10),
                              ],
                              TextFormField(
                                controller: _email,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'البريد الإلكتروني',
                                  prefixIcon: Icon(Icons.alternate_email),
                                ),
                                validator: (v) => v == null ||
                                        !v.contains('@') ||
                                        v.trim().length < 5
                                    ? 'بريد غير صالح'
                                    : null,
                              ),
                              const SizedBox(height: 10),
                              TextFormField(
                                controller: _password,
                                obscureText: true,
                                textInputAction: TextInputAction.done,
                                decoration: const InputDecoration(
                                  labelText: 'كلمة المرور',
                                  prefixIcon: Icon(Icons.lock_outline),
                                ),
                                validator: (v) => v == null || v.length < 6
                                    ? 'كلمة المرور يجب أن تكون 6 أحرف على الأقل'
                                    : null,
                                onFieldSubmitted: (_) => _submit(),
                              ),
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: FilledButton(
                                  onPressed: _loading ? null : _submit,
                                  child: _loading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text(isLogin ? 'دخول' : 'إنشاء الحساب'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                if (width < 380)
                  Text(
                    'نصيحة: استخدم كلمة مرور قوية لحماية حسابك.',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
