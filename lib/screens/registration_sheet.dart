import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/format.dart';
import '../core/i18n.dart';
import '../core/models.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';

Future<void> showRegistrationSheet(BuildContext context, Program program) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => RegistrationSheet(program: program),
  );
}

class RegistrationSheet extends StatefulWidget {
  const RegistrationSheet({super.key, required this.program});
  final Program program;

  @override
  State<RegistrationSheet> createState() => _RegistrationSheetState();
}

class _RegistrationSheetState extends State<RegistrationSheet> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _notes = TextEditingController();
  late String _mode = widget.program.modes.first;
  bool _sending = false;
  String? _reference;
  bool _duplicate = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() => _sending = true);
    final state = AppScope.read(context);
    try {
      final res = await state.api.post('/registrations', {
        'programCode': widget.program.code,
        'fullName': _name.text.trim(),
        'phone': _phone.text.trim(),
        'email': _email.text.trim(),
        'mode': _mode,
        'notes': _notes.text.trim(),
        'lang': state.lang,
        'website': '',
      });
      if (!mounted) return;
      setState(() {
        _reference = res is Map ? (res['reference'] ?? '').toString() : '';
        _duplicate = res is Map && res['duplicate'] == true;
      });
    } catch (e) {
      if (mounted) toast(context, errorMessage(context, e), error: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 420),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: ScaleTransition(scale: Tween<double>(begin: 0.96, end: 1).animate(anim), child: child),
            ),
            child: _reference == null ? _buildForm(context) : _buildSuccess(context),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final p = Palette.of(context);
    final lang = context.lang;
    return Form(
      key: _form,
      child: Column(key: const ValueKey('form'), crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(context.t('program.register'), style: displayStyle(context, 20)),
        const SizedBox(height: 4),
        Row(children: [
          CodeTag(widget.program.code),
          const SizedBox(width: 8),
          Expanded(
            child: Text(widget.program.title.pick(lang),
                maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: p.muted, fontSize: 13)),
          ),
        ]),
        const SizedBox(height: 8),
        Text(context.t('program.registerLead'), style: TextStyle(color: p.muted, height: 1.6, fontSize: 13.5)),
        const SizedBox(height: 18),
        TextFormField(
          controller: _name,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.name],
          decoration: fieldDeco(context, context.t('form.fullName'), hint: context.t('form.fullNameHint')),
          validator: (v) => vRequired(context, v, min: 3),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          textDirection: TextDirection.ltr,
          autofillHints: const [AutofillHints.telephoneNumber],
          decoration: fieldDeco(context, context.t('form.phone'), hint: '01xxxxxxxxx'),
          validator: (v) => vPhone(context, v),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          textDirection: TextDirection.ltr,
          autofillHints: const [AutofillHints.email],
          decoration: fieldDeco(context, context.t('form.email')),
          validator: (v) => vEmailOptional(context, v),
        ),
        const SizedBox(height: 16),
        Text(context.t('form.mode'), style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final m in widget.program.modes)
            Pressable2(
              onTap: () => setState(() => _mode = m),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: _mode == m ? p.brassSoft : p.surface,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: _mode == m ? p.brass : p.line, width: 1.4),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      _mode == m ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                      key: ValueKey(_mode == m),
                      size: 18,
                      color: _mode == m ? p.brass : p.muted,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(context.t('mode.$m'), style: const TextStyle(fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
        ]),
        const SizedBox(height: 16),
        TextFormField(
          controller: _notes,
          maxLines: 3,
          maxLength: 1000,
          decoration: fieldDeco(context, context.t('form.notes'), hint: context.t('form.notesHint')),
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: _sending ? null : _submit,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _sending
                ? SizedBox(
                    key: const ValueKey('spin'),
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4, color: p.onBrass),
                  )
                : Text(context.t('form.submit'), key: const ValueKey('label')),
          ),
        ),
        const SizedBox(height: 10),
        Text(context.t('form.privacy'), textAlign: TextAlign.center, style: TextStyle(color: p.muted, fontSize: 12)),
      ]),
    );
  }

  Widget _buildSuccess(BuildContext context) {
    final p = Palette.of(context);
    return Column(key: const ValueKey('success'), children: [
      const SizedBox(height: 12),
      const AnimatedCheck(),
      const SizedBox(height: 18),
      Reveal(
        delay: const Duration(milliseconds: 350),
        child: Text(context.t('success.title'), style: displayStyle(context, 21)),
      ),
      const SizedBox(height: 8),
      Reveal(
        delay: const Duration(milliseconds: 430),
        child: Text(
          context.t(_duplicate ? 'success.dup' : 'success.body'),
          textAlign: TextAlign.center,
          style: TextStyle(color: p.muted, height: 1.6),
        ),
      ),
      const SizedBox(height: 12),
      Reveal(
        delay: const Duration(milliseconds: 500),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: p.surface2, borderRadius: BorderRadius.circular(10)),
          child: SelectableText(_reference ?? '', style: monoStyle(size: 18, color: p.ink, weight: FontWeight.w600)),
        ),
      ),
      const SizedBox(height: 24),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: Text(context.t('success.done'))),
      ),
    ]);
  }
}
