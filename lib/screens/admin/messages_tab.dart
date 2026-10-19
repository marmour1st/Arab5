import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';
import 'admin_common.dart';
import 'admin_list.dart';

class MessagesTab extends StatelessWidget {
  const MessagesTab({super.key, required this.onChanged});
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return AdminList<ContactMessage>(
      endpoint: '/admin/messages',
      parse: ContactMessage.fromJson,
      statuses: const ['unread', 'read'],
      statusLabel: (c, s) => c.t('list.$s'),
      itemBuilder: (context, m, reload) => _MessageCard(
        message: m,
        onChanged: () async {
          await reload();
          onChanged();
        },
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.message, required this.onChanged});
  final ContactMessage message;
  final Future<void> Function() onChanged;

  Future<void> _toggleRead(BuildContext context) async {
    try {
      await AppScope.read(context).api.patch('/admin/messages/${message.id}', {'read': !message.read});
      await onChanged();
    } catch (e) {
      if (context.mounted) handleAdminError(context, e);
    }
  }

  Future<void> _delete(BuildContext context) async {
    final ok = await confirmDialog(context, context.t('msg.confirmDelete'), context.t('act.delete'));
    if (!ok || !context.mounted) return;
    try {
      await AppScope.read(context).api.delete('/admin/messages/${message.id}');
      if (context.mounted) toast(context, context.t('msg.deleted'));
      await onChanged();
    } catch (e) {
      if (context.mounted) handleAdminError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final m = message;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: m.read ? p.line : fade(p.brass, 0.6), width: m.read ? 1 : 1.6),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          if (!m.read) ...[
            Container(width: 8, height: 8, decoration: BoxDecoration(color: p.brass, shape: BoxShape.circle)),
            const SizedBox(width: 8),
          ],
          Expanded(child: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15))),
          Text(fmtDateTime(m.createdAt, context.lang), style: TextStyle(color: p.muted, fontSize: 12)),
          const SizedBox(width: 8),
        ]),
        const SizedBox(height: 2),
        Text(
          m.email.isEmpty ? m.phone : '${m.phone} · ${m.email}',
          textDirection: TextDirection.ltr,
          style: TextStyle(color: p.muted, fontSize: 12.5),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsetsDirectional.only(end: 8),
          child: SelectableText(m.message, style: const TextStyle(height: 1.6)),
        ),
        const SizedBox(height: 4),
        Row(children: [
          IconButton(
            tooltip: context.t('act.whatsapp'),
            onPressed: () => openWhatsApp(context, m.phone),
            icon: const Icon(Icons.chat_rounded, color: Color(0xFF1FA855)),
          ),
          IconButton(
            tooltip: context.t('act.call'),
            onPressed: () => callPhone(context, m.phone),
            icon: Icon(Icons.call_outlined, color: p.ink),
          ),
          const Spacer(),
          IconButton(
            tooltip: context.t(m.read ? 'act.markUnread' : 'act.markRead'),
            onPressed: () => _toggleRead(context),
            icon: Icon(m.read ? Icons.mark_email_unread_outlined : Icons.mark_email_read_outlined, color: p.brass),
          ),
          IconButton(
            tooltip: context.t('act.delete'),
            onPressed: () => _delete(context),
            icon: Icon(Icons.delete_outline_rounded, color: p.bad),
          ),
        ]),
      ]),
    );
  }
}
