import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';
import 'admin_common.dart';
import 'admin_list.dart';
import 'issue_certificate_dialog.dart';

class CertificatesTab extends StatefulWidget {
  const CertificatesTab({super.key, required this.onChanged});
  final VoidCallback onChanged;

  @override
  State<CertificatesTab> createState() => _CertificatesTabState();
}

class _CertificatesTabState extends State<CertificatesTab> {
  final _listKey = GlobalKey<AdminListState<Certificate>>();

  Future<void> _issue() async {
    final code = await showIssueCertificateDialog(context);
    if (code == null || !mounted) return;
    toast(context, context.t('cert.issued', {'code': code}));
    await _listKey.currentState?.reload();
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return AdminList<Certificate>(
      key: _listKey,
      endpoint: '/admin/certificates',
      parse: Certificate.fromJson,
      header: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _issue,
            icon: const Icon(Icons.add_rounded),
            label: Text(context.t('cert.issue')),
          ),
        ),
      ),
      itemBuilder: (context, c, reload) => _CertificateCard(
        cert: c,
        onChanged: () async {
          await reload();
          widget.onChanged();
        },
      ),
    );
  }
}

class _CertificateCard extends StatelessWidget {
  const _CertificateCard({required this.cert, required this.onChanged});
  final Certificate cert;
  final Future<void> Function() onChanged;

  Future<void> _toggle(BuildContext context) async {
    if (!cert.revoked) {
      final ok = await confirmDialog(context, context.t('cert.confirmRevoke'), context.t('act.revoke'));
      if (!ok || !context.mounted) return;
    }
    try {
      await AppScope.read(context).api.patch('/admin/certificates/${cert.id}', {'revoked': !cert.revoked});
      if (context.mounted) toast(context, context.t('msg.saved'));
      await onChanged();
    } catch (e) {
      if (context.mounted) handleAdminError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final lang = context.lang;
    final color = cert.revoked ? p.bad : p.ok;
    return Panel(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: CodeTag(cert.code, size: 14.5)),
          IconButton(
            tooltip: context.t('act.copy'),
            visualDensity: VisualDensity.compact,
            onPressed: () => copyText(context, cert.code, context.t('msg.copied')),
            icon: Icon(Icons.content_copy_rounded, size: 18, color: p.muted),
          ),
          StatusPill(label: context.t(cert.revoked ? 'cert.revoked' : 'cert.valid'), color: color),
          const SizedBox(width: 8),
        ]),
        Text(cert.holderName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5)),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsetsDirectional.only(end: 8),
          child: Text(
            '${cert.programCode} · ${cert.programTitle.pick(lang)}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: p.muted, fontSize: 13),
          ),
        ),
        Row(children: [
          Icon(Icons.calendar_today_outlined, size: 14, color: p.muted),
          const SizedBox(width: 4),
          Text(fmtDate(cert.issuedAt, lang), style: TextStyle(color: p.muted, fontSize: 12.5)),
          const Spacer(),
          TextButton(
            onPressed: () => _toggle(context),
            style: TextButton.styleFrom(foregroundColor: cert.revoked ? p.ok : p.bad),
            child: Text(context.t(cert.revoked ? 'act.restore' : 'act.revoke')),
          ),
        ]),
      ]),
    );
  }
}
