import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/theme.dart';
import 'admin_common.dart';

/// Issues a certificate and returns its verification code (or null if cancelled).
Future<String?> showIssueCertificateDialog(
  BuildContext context, {
  String holderName = '',
  String? programCode,
  String? registrationId,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _IssueDialog(holderName: holderName, programCode: programCode, registrationId: registrationId),
  );
}

class _IssueDialog extends StatefulWidget {
  const _IssueDialog({required this.holderName, this.programCode, this.registrationId});
  final String holderName;
  final String? programCode;
  final String? registrationId;

  @override
  State<_IssueDialog> createState() => _IssueDialogState();
}

class _IssueDialogState extends State<_IssueDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name = TextEditingController(text: widget.holderName);
  String? _code;
  DateTime _date = DateTime.now();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _code = widget.programCode;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2010),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false) || _code == null) return;
    setState(() => _busy = true);
    try {
      final body = <String, dynamic>{
        'holderName': _name.text.trim(),
        'programCode': _code,
        'issuedAt': isoDay(_date),
      };
      final rid = widget.registrationId;
      if (rid != null && RegExp(r'^[a-f0-9]{24}$').hasMatch(rid)) body['registrationId'] = rid;
      final res = await AppScope.read(context).api.post('/admin/certificates', body);
      if (!mounted) return;
      final item = res is Map ? res['item'] : null;
      Navigator.of(context).pop(item is Map ? (item['code'] ?? '').toString() : '');
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        handleAdminError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final state = AppScope.of(context);
    final lang = state.lang;
    final programs = state.programs;
    if (_code != null && !programs.any((x) => x.code == _code)) _code = null;
    _code ??= programs.isNotEmpty ? programs.first.code : null;

    return AlertDialog(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      title: Row(children: [
        Icon(Icons.workspace_premium_outlined, color: p.brass),
        const SizedBox(width: 10),
        Expanded(child: Text(context.t('cert.issue'))),
      ]),
      content: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            TextFormField(
              controller: _name,
              decoration: fieldDeco(context, context.t('cert.holder'), hint: context.t('cert.holderHint')),
              validator: (v) => vRequired(context, v, min: 3),
            ),
            const SizedBox(height: 12),
            InputDecorator(
              decoration: fieldDeco(context, context.t('cert.program')),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _code,
                  isExpanded: true,
                  isDense: true,
                  dropdownColor: p.surface,
                  items: [
                    for (final pr in programs)
                      DropdownMenuItem<String>(
                        value: pr.code,
                        child: Text('${pr.code} · ${pr.title.pick(lang)}', overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (v) => setState(() => _code = v),
                ),
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _pickDate,
              child: InputDecorator(
                decoration: fieldDeco(context, context.t('cert.issuedAt'), suffixIcon: const Icon(Icons.calendar_today_outlined)),
                child: Text(fmtDate(_date, lang)),
              ),
            ),
          ]),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(foregroundColor: p.muted),
          child: Text(context.t('act.cancel')),
        ),
        FilledButton(
          onPressed: _busy ? null : _submit,
          style: FilledButton.styleFrom(minimumSize: const Size(64, 44)),
          child: _busy
              ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.2, color: p.onBrass))
              : Text(context.t('cert.issue')),
        ),
      ],
    );
  }
}
