import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/config.dart';
import '../core/format.dart';
import '../core/i18n.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _message = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() => _sending = true);
    final state = AppScope.read(context);
    try {
      await state.api.post('/messages', {
        'name': _name.text.trim(),
        'phone': _phone.text.trim(),
        'email': _email.text.trim(),
        'message': _message.text.trim(),
        'lang': state.lang,
        'website': '',
      });
      if (!mounted) return;
      _form.currentState?.reset();
      _name.clear();
      _phone.clear();
      _email.clear();
      _message.clear();
      toast(context, context.t('contact.success'));
    } catch (e) {
      if (mounted) toast(context, errorMessage(context, e), error: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final p = Palette.of(context);
    final top = MediaQuery.of(context).padding.top;

    return ListView(padding: EdgeInsets.fromLTRB(20, top + 20, 20, 32), children: [
      Reveal(child: Text(context.t('contact.title'), style: displayStyle(context, 26))),
      const SizedBox(height: 6),
      Reveal(
        delay: const Duration(milliseconds: 70),
        child: Text(context.t('contact.lead'), style: TextStyle(color: p.muted, height: 1.6)),
      ),
      const SizedBox(height: 20),

      Reveal(
        delay: const Duration(milliseconds: 140),
        child: Panel(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              _IconBubble(icon: Icons.call_rounded),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(context.t('contact.phone'), style: TextStyle(color: p.muted, fontSize: 12.5)),
                  Text(state.phone, textDirection: TextDirection.ltr, style: monoStyle(size: 19, color: p.ink, weight: FontWeight.w600)),
                ]),
              ),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => callPhone(context, state.phone),
                  icon: const Icon(Icons.call_rounded, size: 18),
                  label: Text(context.t('contact.call')),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => openWhatsApp(context, state.whatsapp),
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1FA855), foregroundColor: Colors.white),
                  icon: const Icon(Icons.chat_rounded, size: 18),
                  label: Text(context.t('contact.whatsapp')),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.outlined(
                tooltip: context.t('contact.copy'),
                onPressed: () => copyText(context, state.phone, context.t('contact.copied')),
                icon: const Icon(Icons.content_copy_rounded, size: 18),
              ),
            ]),
          ]),
        ),
      ),
      const SizedBox(height: 12),
      Reveal(
        delay: const Duration(milliseconds: 210),
        child: Panel(
          onTap: () => openExternal(context, Uri.parse(AppConfig.mapsUrl)),
          child: Row(children: [
            _IconBubble(icon: Icons.location_on_outlined),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(context.t('contact.location'), style: TextStyle(color: p.muted, fontSize: 12.5)),
                Text(context.t('contact.locationValue'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ]),
            ),
            Text(context.t('contact.map'), style: TextStyle(color: p.brass, fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(width: 4),
            Icon(Icons.open_in_new_rounded, size: 16, color: p.brass),
          ]),
        ),
      ),
      const SizedBox(height: 12),
      Reveal(
        delay: const Duration(milliseconds: 280),
        child: Panel(
          onTap: () => openExternal(context, Uri.parse(AppConfig.facebookUrl)),
          child: Row(children: [
            _IconBubble(icon: Icons.facebook),
            const SizedBox(width: 12),
            Expanded(child: Text(context.t('contact.facebook'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15))),
            Icon(Icons.open_in_new_rounded, size: 16, color: p.brass),
          ]),
        ),
      ),
      const SizedBox(height: 28),

      Reveal(
        delay: const Duration(milliseconds: 340),
        child: Panel(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _form,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(context.t('contact.formTitle'), style: displayStyle(context, 18)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                textInputAction: TextInputAction.next,
                decoration: fieldDeco(context, context.t('form.name')),
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
                controller: _message,
                minLines: 4,
                maxLines: 8,
                maxLength: 2000,
                decoration: fieldDeco(context, context.t('contact.message'), hint: context.t('contact.messageHint')),
                validator: (v) => vRequired(context, v, min: 5),
              ),
              const SizedBox(height: 6),
              FilledButton(
                onPressed: _sending ? null : _send,
                child: _sending
                    ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: p.onBrass))
                    : Text(context.t('contact.submit')),
              ),
            ]),
          ),
        ),
      ),
    ]);
  }
}

class _IconBubble extends StatelessWidget {
  const _IconBubble({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(color: p.brassSoft, borderRadius: BorderRadius.circular(14)),
      child: Icon(icon, color: p.brass),
    );
  }
}
