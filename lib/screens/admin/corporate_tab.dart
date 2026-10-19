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

class CorporateTab extends StatelessWidget {
  const CorporateTab({super.key, required this.onChanged});
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return AdminList<CorporateRequest>(
      endpoint: '/admin/corporate',
      parse: CorporateRequest.fromJson,
      statuses: corporateStatuses,
      statusLabel: (c, s) => c.t('cstatus.$s'),
      itemBuilder: (context, r, reload) => _CorporateCard(
        req: r,
        onTap: () async {
          await showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            builder: (_) => _CorporateSheet(req: r),
          );
          await reload();
          onChanged();
        },
      ),
    );
  }
}

class _CorporateCard extends StatelessWidget {
  const _CorporateCard({required this.req, required this.onTap});
  final CorporateRequest req;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Pressable(
      child: Panel(
        padding: const EdgeInsets.all(14),
        onTap: onTap,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(req.company, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5))),
            StatusPill(label: context.t('cstatus.${req.status}'), color: statusColor(context, req.status)),
          ]),
          const SizedBox(height: 4),
          Text(req.contactName, style: TextStyle(color: p.muted, fontSize: 13)),
          const SizedBox(height: 8),
          Row(children: [
            Icon(Icons.groups_outlined, size: 16, color: p.muted),
            const SizedBox(width: 4),
            Text(fmtNum(req.trainees), style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(req.topic.isEmpty ? '—' : req.topic,
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: p.muted, fontSize: 13)),
            ),
            Text(fmtDate(req.createdAt, context.lang), style: TextStyle(color: p.muted, fontSize: 12)),
          ]),
        ]),
      ),
    );
  }
}

class _CorporateSheet extends StatefulWidget {
  const _CorporateSheet({required this.req});
  final CorporateRequest req;

  @override
  State<_CorporateSheet> createState() => _CorporateSheetState();
}

class _CorporateSheetState extends State<_CorporateSheet> {
  late String _status = widget.req.status;
  late final TextEditingController _note = TextEditingController(text: widget.req.adminNote);
  bool _busy = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _patch(Map<String, dynamic> body, String doneKey) async {
    setState(() => _busy = true);
    try {
      await AppScope.read(context).api.patch('/admin/corporate/${widget.req.id}', body);
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
      await AppScope.read(context).api.delete('/admin/corporate/${widget.req.id}');
      if (!mounted) return;
      toast(context, context.t('msg.deleted'));
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) handleAdminError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.req;
    final p = Palette.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(r.company, style: displayStyle(context, 20)),
          const SizedBox(height: 4),
          Text('${r.contactName} · ${fmtDateTime(r.createdAt, context.lang)}', style: TextStyle(color: p.muted, fontSize: 12.5)),
          const SizedBox(height: 16),
          PhoneActions(onCall: () => callPhone(context, r.phone), onWhatsApp: () => openWhatsApp(context, r.phone)),
          const SizedBox(height: 18),
          Text(context.t('detail.status'), style: TextStyle(color: p.muted, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          StatusPicker(
            statuses: corporateStatuses,
            selected: _status,
            labelPrefix: 'cstatus',
            busy: _busy,
            onChanged: (s) => _patch({'status': s}, 'msg.status'),
          ),
          const SizedBox(height: 20),
          DetailRow(label: context.t('form.phone'), value: r.phone, ltr: true),
          if (r.email.isNotEmpty) DetailRow(label: context.t('form.emailRequired'), value: r.email, ltr: true),
          DetailRow(label: context.t('detail.trainees'), value: fmtNum(r.trainees)),
          DetailRow(label: context.t('detail.topic'), value: r.topic),
          DetailRow(label: context.t('detail.details'), value: r.details),
          const SizedBox(height: 8),
          TextField(
            controller: _note,
            minLines: 2,
            maxLines: 5,
            maxLength: 2000,
            decoration: fieldDeco(context, context.t('detail.adminNote')),
          ),
          OutlinedButton.icon(
            onPressed: _busy ? null : () => _patch({'adminNote': _note.text.trim()}, 'msg.saved'),
            icon: const Icon(Icons.save_outlined, size: 18),
            label: Text(context.t('act.save')),
          ),
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
