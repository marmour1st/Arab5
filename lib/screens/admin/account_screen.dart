import 'package:flutter/material.dart';

import '../../core/api.dart';
import '../../core/app_state.dart';
import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';
import 'admin_common.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    super.dispose();
  }

  bool _strong(String v) => v.length >= 10 && RegExp(r'[A-Za-z]').hasMatch(v) && RegExp(r'\d').hasMatch(v);

  Future<void> _change() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      await AppScope.read(context).api.post('/auth/password', {
        'currentPassword': _current.text,
        'newPassword': _next.text,
      });
      if (!mounted) return;
      _current.clear();
      _next.clear();
      toast(context, context.t('acc.changed'));
    } catch (e) {
      if (!mounted) return;
      if (e is ApiException && e.code == 'wrong_current_password') {
        toast(context, context.t('acc.wrong'), error: true);
      } else if (e is ApiException && e.status == 422) {
        toast(context, context.t('acc.weak'), error: true);
      } else {
        handleAdminError(context, e);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _logout() async {
    final state = AppScope.read(context);
    final navigator = Navigator.of(context);
    await state.adminLogout();
    navigator.popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final admin = AppScope.of(context).admin;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: p.navy,
        foregroundColor: Palette.light.onNavy,
        surfaceTintColor: Colors.transparent,
        title: Text(context.t('admin.account')),
      ),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        if (admin != null)
          Panel(
            child: Row(children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: p.brassSoft,
                child: Text(
                  admin.name.isNotEmpty ? admin.name.characters.first : '?',
                  style: TextStyle(color: p.brass, fontWeight: FontWeight.w700, fontSize: 18),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(context.t('acc.signedInAs'), style: TextStyle(color: p.muted, fontSize: 12.5)),
                  Text(admin.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5)),
                  Text(admin.email, textDirection: TextDirection.ltr, style: TextStyle(color: p.muted, fontSize: 13)),
                ]),
              ),
            ]),
          ),
        const SizedBox(height: 16),
        Panel(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _form,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(context.t('acc.password'), style: displayStyle(context, 17)),
              const SizedBox(height: 14),
              TextFormField(
                controller: _current,
                obscureText: true,
                textDirection: TextDirection.ltr,
                decoration: fieldDeco(context, context.t('acc.current')),
                validator: (v) => (v ?? '').isEmpty ? context.t('errors.required') : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _next,
                obscureText: true,
                textDirection: TextDirection.ltr,
                decoration: fieldDeco(context, context.t('acc.new')).copyWith(helperText: context.t('acc.newHint')),
                validator: (v) => _strong(v ?? '') ? null : context.t('acc.weak'),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _busy ? null : _change,
                child: _busy
                    ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: p.onBrass))
                    : Text(context.t('act.save')),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        Text(context.t('acc.teamOnWeb'), style: TextStyle(color: p.muted, fontSize: 12.5, height: 1.5)),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: _logout,
          style: OutlinedButton.styleFrom(foregroundColor: p.bad, side: BorderSide(color: p.bad, width: 1.4)),
          icon: const Icon(Icons.logout_rounded),
          label: Text(context.t('admin.logout')),
        ),
      ]),
    );
  }
}
