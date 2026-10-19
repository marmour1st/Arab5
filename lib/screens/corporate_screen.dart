import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_state.dart';
import '../core/format.dart';
import '../core/i18n.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';

class CorporateScreen extends StatefulWidget {
  const CorporateScreen({super.key});

  @override
  State<CorporateScreen> createState() => _CorporateScreenState();
}

class _CorporateScreenState extends State<CorporateScreen> {
  final _form = GlobalKey<FormState>();
  final _company = TextEditingController();
  final _contact = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _trainees = TextEditingController(text: '10');
  final _topic = TextEditingController();
  final _details = TextEditingController();
  bool _sending = false;
  bool _done = false;

  @override
  void dispose() {
    for (final c in [_company, _contact, _phone, _email, _trainees, _topic, _details]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _send() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() => _sending = true);
    final state = AppScope.read(context);
    try {
      await state.api.post('/corporate', {
        'company': _company.text.trim(),
        'contactName': _contact.text.trim(),
        'phone': _phone.text.trim(),
        'email': _email.text.trim(),
        'trainees': int.tryParse(_trainees.text.trim()) ?? 1,
        'topic': _topic.text.trim(),
        'details': _details.text.trim(),
        'lang': state.lang,
        'website': '',
      });
      if (mounted) setState(() => _done = true);
    } catch (e) {
      if (mounted) toast(context, errorMessage(context, e), error: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: p.paper,
        surfaceTintColor: Colors.transparent,
        title: Text(context.t('corp.title')),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 450),
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: ScaleTransition(scale: Tween<double>(begin: 0.97, end: 1).animate(anim), child: child),
        ),
        child: _done ? _success(context) : _formView(context),
      ),
    );
  }

  Widget _success(BuildContext context) {
    final p = Palette.of(context);
    return Center(
      key: const ValueKey('done'),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const AnimatedCheck(size: 88),
          const SizedBox(height: 20),
          Reveal(
            delay: const Duration(milliseconds: 350),
            child: Text(context.t('corp.success'), textAlign: TextAlign.center, style: TextStyle(color: p.muted, height: 1.7, fontSize: 15)),
          ),
          const SizedBox(height: 24),
          OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: Text(context.t('success.done'))),
        ]),
      ),
    );
  }

  Widget _formView(BuildContext context) {
    final p = Palette.of(context);
    final points = ['corp.p1', 'corp.p2', 'corp.p3', 'corp.p4'];
    return ListView(key: const ValueKey('form'), padding: const EdgeInsets.fromLTRB(20, 8, 20, 32), children: [
      Reveal(child: Text(context.t('corp.lead'), style: TextStyle(color: p.muted, height: 1.7, fontSize: 15))),
      const SizedBox(height: 16),
      for (var i = 0; i < points.length; i++)
        Reveal(
          delay: Duration(milliseconds: 80 + i * 70),
          offset: 12,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              Icon(Icons.check_circle_rounded, color: p.brass, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(context.t(points[i]), style: const TextStyle(fontWeight: FontWeight.w600))),
            ]),
          ),
        ),
      const SizedBox(height: 14),
      Reveal(
        delay: const Duration(milliseconds: 380),
        child: Panel(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _form,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              TextFormField(
                controller: _company,
                textInputAction: TextInputAction.next,
                decoration: fieldDeco(context, context.t('corp.company')),
                validator: (v) => vRequired(context, v, min: 2),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contact,
                textInputAction: TextInputAction.next,
                decoration: fieldDeco(context, context.t('corp.contact')),
                validator: (v) => vRequired(context, v, min: 2),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                textDirection: TextDirection.ltr,
                textInputAction: TextInputAction.next,
                decoration: fieldDeco(context, context.t('form.phone'), hint: '01xxxxxxxxx'),
                validator: (v) => vPhone(context, v),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textDirection: TextDirection.ltr,
                textInputAction: TextInputAction.next,
                decoration: fieldDeco(context, context.t('form.email')),
                validator: (v) => vEmailOptional(context, v),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _trainees,
                keyboardType: TextInputType.number,
                textDirection: TextDirection.ltr,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: fieldDeco(context, context.t('corp.trainees')),
                validator: (v) {
                  final n = int.tryParse((v ?? '').trim());
                  return n == null || n < 1 ? context.t('errors.required') : null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _topic,
                textInputAction: TextInputAction.next,
                decoration: fieldDeco(context, context.t('corp.topic'), hint: context.t('corp.topicHint')),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _details,
                minLines: 3,
                maxLines: 6,
                maxLength: 2000,
                decoration: fieldDeco(context, context.t('corp.details')),
              ),
              const SizedBox(height: 6),
              FilledButton(
                onPressed: _sending ? null : _send,
                child: _sending
                    ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: p.onBrass))
                    : Text(context.t('corp.submit')),
              ),
              const SizedBox(height: 10),
              Text(context.t('form.privacy'), textAlign: TextAlign.center, style: TextStyle(color: p.muted, fontSize: 12)),
            ]),
          ),
        ),
      ),
    ]);
  }
}
