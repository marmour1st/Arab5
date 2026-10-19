import 'package:flutter/material.dart';

import '../../core/api.dart';
import '../../core/app_state.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';
import '../../widgets/motion.dart';
import 'admin_shell.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    final state = AppScope.read(context);
    try {
      await state.adminLogin(_email.text.trim().toLowerCase(), _password.text);
      if (!mounted) return;
      _password.clear();
      Navigator.of(context).pushReplacement(fadeThrough(const AdminShell()));
    } catch (e) {
      if (!mounted) return;
      String message;
      if (e is ApiException && (e.status == 401 || e.status == 422)) {
        message = context.t('admin.invalidLogin');
      } else if (e is ApiException && e.status == 429) {
        message = context.t('admin.tooMany');
      } else {
        message = errorMessage(context, e);
      }
      setState(() => _error = message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Scaffold(
      backgroundColor: p.navy,
      appBar: AppBar(backgroundColor: Colors.transparent, foregroundColor: Palette.light.onNavy, elevation: 0),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [p.navy, p.navy2]),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Reveal(
                offset: 30,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Material(
                    color: p.surface,
                    borderRadius: BorderRadius.circular(22),
                    elevation: 12,
                    shadowColor: Colors.black54,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _form,
                        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                          const Center(child: BrandMark(size: 64)),
                          const SizedBox(height: 16),
                          Text(context.t('admin.loginTitle'), textAlign: TextAlign.center, style: displayStyle(context, 20)),
                          const SizedBox(height: 4),
                          Text(context.t('admin.loginLead'), textAlign: TextAlign.center, style: TextStyle(color: p.muted)),
                          const SizedBox(height: 20),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 250),
                            child: _error == null
                                ? const SizedBox(width: double.infinity)
                                : Container(
                                    width: double.infinity,
                                    margin: const EdgeInsets.only(bottom: 14),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(color: p.badSoft, borderRadius: BorderRadius.circular(12)),
                                    child: Text(_error!, style: TextStyle(color: p.bad, fontWeight: FontWeight.w600)),
                                  ),
                          ),
                          TextFormField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            textDirection: TextDirection.ltr,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.username, AutofillHints.email],
                            decoration: fieldDeco(context, context.t('form.emailRequired'), prefixIcon: const Icon(Icons.alternate_email_rounded)),
                            validator: (v) => vEmailRequired(context, v),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _password,
                            obscureText: _obscure,
                            textDirection: TextDirection.ltr,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.password],
                            onFieldSubmitted: (_) => _login(),
                            decoration: fieldDeco(
                              context,
                              context.t('admin.password'),
                              prefixIcon: const Icon(Icons.lock_outline_rounded),
                              suffixIcon: IconButton(
                                icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                                onPressed: () => setState(() => _obscure = !_obscure),
                              ),
                            ),
                            validator: (v) => (v ?? '').isEmpty ? context.t('errors.required') : null,
                          ),
                          const SizedBox(height: 20),
                          FilledButton(
                            onPressed: _busy ? null : _login,
                            child: _busy
                                ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: p.onBrass))
                                : Text(context.t('admin.login')),
                          ),
                        ]),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
