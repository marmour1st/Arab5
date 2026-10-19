import 'package:flutter/material.dart';

import '../../core/api.dart';
import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';
import '../../widgets/motion.dart';
import 'admin_login_screen.dart';

/// Shows the right message for an admin request error. A 401 means the session
/// ended, so the user is taken back to the sign-in screen.
void handleAdminError(BuildContext context, Object error) {
  if (error is ApiException && error.status == 401) {
    toast(context, context.t('admin.session'), error: true);
    Navigator.of(context).pushAndRemoveUntil(fadeThrough(const AdminLoginScreen()), (route) => route.isFirst);
    return;
  }
  toast(context, errorMessage(context, error), error: true);
}

/// Label/value row used in admin detail sheets.
class DetailRow extends StatelessWidget {
  const DetailRow({super.key, required this.label, required this.value, this.ltr = false});
  final String label;
  final String value;
  final bool ltr;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 118, child: Text(label, style: TextStyle(color: p.muted, fontSize: 13))),
        Expanded(
          child: SelectableText(
            value.isEmpty ? '—' : value,
            textDirection: ltr ? TextDirection.ltr : null,
            style: const TextStyle(fontWeight: FontWeight.w600, height: 1.5),
          ),
        ),
      ]),
    );
  }
}

/// Row of call / WhatsApp actions for a phone number.
class PhoneActions extends StatelessWidget {
  const PhoneActions({super.key, required this.onCall, required this.onWhatsApp});
  final VoidCallback onCall;
  final VoidCallback onWhatsApp;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: OutlinedButton.icon(
          onPressed: onCall,
          icon: const Icon(Icons.call_rounded, size: 18),
          label: Text(context.t('act.call')),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: FilledButton.icon(
          onPressed: onWhatsApp,
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1FA855), foregroundColor: Colors.white),
          icon: const Icon(Icons.chat_rounded, size: 18),
          label: Text(context.t('act.whatsapp')),
        ),
      ),
    ]);
  }
}

/// Tappable status options; the selected one is filled.
class StatusPicker extends StatelessWidget {
  const StatusPicker({super.key, required this.statuses, required this.selected, required this.labelPrefix, required this.onChanged, this.busy = false});
  final List<String> statuses;
  final String selected;
  final String labelPrefix;
  final ValueChanged<String> onChanged;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Wrap(spacing: 8, runSpacing: 8, children: [
      for (final s in statuses)
        Pressable2(
          onTap: () {
            if (!busy && s != selected) onChanged(s);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: s == selected ? statusColor(context, s) : p.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: s == selected ? statusColor(context, s) : p.line, width: 1.4),
            ),
            child: Text(
              context.t('$labelPrefix.$s'),
              style: TextStyle(
                color: s == selected
                    ? (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF0A111D) : Colors.white)
                    : p.ink,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
    ]);
  }
}
