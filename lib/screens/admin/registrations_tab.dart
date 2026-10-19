import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import '../../core/tracks.dart';
import '../../widgets/common.dart';
import '../../widgets/motion.dart';
import 'admin_common.dart';
import 'admin_list.dart';
import 'issue_certificate_dialog.dart';

class RegistrationsTab extends StatelessWidget {
  const RegistrationsTab({super.key, required this.onChanged});
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return AdminList<Registration>(
      endpoint: '/admin/registrations',
      parse: Registration.fromJson,
      statuses: registrationStatuses,
      statusLabel: (c, s) => c.t('rstatus.$s'),
      itemBuilder: (context, r, reload) => _RegistrationCard(
        reg: r,
        onTap: () async {
          await showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            builder: (_) => RegistrationDetailSheet(reg: r),
          );
          await reload();
          onChanged();
        },
      ),
    );
  }
}

class _RegistrationCard extends StatelessWidget {
  const _RegistrationCard({required this.reg, required this.onTap});
  final Registration reg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final lang = context.lang;
    return Pressable(
      child: Panel(
        padding: const EdgeInsets.all(14),
        onTap: onTap,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(reg.fullName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5))),
            StatusPill(label: context.t('rstatus.${reg.status}'), color: statusColor(context, reg.status)),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            CodeTag(reg.programCode),
            const SizedBox(width: 8),
            Expanded(
              child: Text(reg.programTitle.pick(lang),
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: p.muted, fontSize: 13)),
            ),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Icon(Icons.call_outlined, size: 15, color: p.muted),
            const SizedBox(width: 4),
            Text(reg.phone, textDirection: TextDirection.ltr, style: monoStyle(size: 12.5, color: p.ink)),
            const Spacer(),
            Text(fmtDateTime(reg.createdAt, lang), style: TextStyle(color: p.muted, fontSize: 12)),
          ]),
        ]),
      ),
    );
  }
}

class RegistrationDetailSheet extends StatefulWidget {
  const RegistrationDetailSheet({super.key, required this.reg});
  final Registration reg;

  @override
  State<RegistrationDetailSheet> createState() => _RegistrationDetailSheetState();
}

class _RegistrationDetailSheetState extends State<RegistrationDetailSheet> {
  late String _status = widget.reg.status;
  late final TextEditingController _note = TextEditingController(text: widget.reg.adminNote);
  bool _busy = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _patch(Map<String, dynamic> body, String doneKey) async {
    setState(() => _busy = true);
    try {
      await AppScope.read(context).api.patch('/admin/registrations/${widget.reg.id}', body);
      if (!mounted) return;
      if (body['status'] is String) setState(() => _status = body['status'] as String);
      toast(context, context.t(doneKey));
    } catch (e) {
      if (mounted) handleAdminError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final ok = await confirmDialog(context, context.t('msg.confirmDelete'), context.t('act.delete'));
    if (!ok || !mounted) return;
    try {
      await AppScope.read(context).api.delete('/admin/registrations/${widget.reg.id}');
      if (!mounted) return;
      toast(context, context.t('msg.deleted'));
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) handleAdminError(context, e);
    }
  }

  Future<void> _issue() async {
    final code = await showIssueCertificateDialog(
      context,
      holderName: widget.reg.fullName,
      programCode: widget.reg.programCode,
      registrationId: widget.reg.id,
    );
    if (code == null || !mounted) return;
    setState(() => _status = 'completed');
    toast(context, context.t('cert.issued', {'code': code}));
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.reg;
    final p = Palette.of(context);
    final lang = context.lang;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(r.fullName, style: displayStyle(context, 20)),
          const SizedBox(height: 4),
          Text(fmtDateTime(r.createdAt, lang), style: TextStyle(color: p.muted, fontSize: 12.5)),
          const SizedBox(height: 16),
          PhoneActions(onCall: () => callPhone(context, r.phone), onWhatsApp: () => openWhatsApp(context, r.phone)),
          const SizedBox(height: 18),
          Text(context.t('detail.status'), style: TextStyle(color: p.muted, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          StatusPicker(
            statuses: registrationStatuses,
            selected: _status,
            labelPrefix: 'rstatus',
            busy: _busy,
            onChanged: (s) => _patch({'status': s}, 'msg.status'),
          ),
          const SizedBox(height: 20),
          DetailRow(label: context.t('form.phone'), value: r.phone, ltr: true),
          if (r.email.isNotEmpty) DetailRow(label: context.t('form.emailRequired'), value: r.email, ltr: true),
          DetailRow(label: context.t('detail.program'), value: '${r.programCode} · ${r.programTitle.pick(lang)}'),
          DetailRow(label: context.t('detail.mode'), value: context.t('mode.${r.mode}')),
          DetailRow(label: context.t('detail.notes'), value: r.notes),
          const SizedBox(height: 8),
          TextField(
            controller: _note,
            minLines: 2,
            maxLines: 5,
            maxLength: 2000,
            decoration: fieldDeco(context, context.t('detail.adminNote')),
          ),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _busy ? null : () => _patch({'adminNote': _note.text.trim()}, 'msg.saved'),
                icon: const Icon(Icons.save_outlined, size: 18),
                label: Text(context.t('act.save')),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                onPressed: _busy ? null : _issue,
                icon: const Icon(Icons.workspace_premium_outlined, size: 18),
                label: Text(context.t('act.issueCert')),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: _busy ? null : _delete,
            style: TextButton.styleFrom(foregroundColor: p.bad),
            icon: const Icon(Icons.delete_outline_rounded),
            label: Text(context.t('act.delete')),
          ),
        ]),
      ),
    );
  }
}
