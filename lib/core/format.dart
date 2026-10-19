import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'i18n.dart';

/// 12345 -> "12,345" (Latin digits, as on the website).
String fmtNum(int n) {
  final s = n.abs().toString();
  final out = StringBuffer(n < 0 ? '-' : '');
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) out.write(',');
    out.write(s[i]);
  }
  return out.toString();
}

const _monthsAr = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
const _monthsEn = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

String fmtDate(DateTime d, String lang) {
  final m = lang == 'en' ? _monthsEn[d.month - 1] : _monthsAr[d.month - 1];
  return lang == 'en' ? '$m ${d.day}, ${d.year}' : '${d.day} $m ${d.year}';
}

String fmtDateTime(DateTime d, String lang) {
  final hh = d.hour.toString().padLeft(2, '0');
  final mm = d.minute.toString().padLeft(2, '0');
  return '${fmtDate(d, lang)} · $hh:$mm';
}

String isoDay(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

// ------------------------------------------------------------- validation

String? vRequired(BuildContext context, String? value, {int min = 1}) {
  final s = (value ?? '').trim();
  if (s.isEmpty) return context.t('errors.required');
  if (s.length < min) return context.t('errors.short');
  return null;
}

final _phoneRe = RegExp(r'^\+?[\d\s\-()٠-٩۰-۹]{7,20}$');
final _digitRe = RegExp(r'[0-9٠-٩۰-۹]');
final _emailRe = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

String? vPhone(BuildContext context, String? value) {
  final s = (value ?? '').trim();
  if (s.isEmpty) return context.t('errors.required');
  if (!_phoneRe.hasMatch(s) || _digitRe.allMatches(s).length < 7) return context.t('errors.phone');
  return null;
}

String? vEmailOptional(BuildContext context, String? value) {
  final s = (value ?? '').trim();
  if (s.isEmpty) return null;
  return _emailRe.hasMatch(s) ? null : context.t('errors.email');
}

String? vEmailRequired(BuildContext context, String? value) {
  final s = (value ?? '').trim();
  if (s.isEmpty) return context.t('errors.required');
  return _emailRe.hasMatch(s) ? null : context.t('errors.email');
}

/// Uppercases text as the user types (certificate and program codes).
final upperCaseFormatter = TextInputFormatter.withFunction(
  (oldValue, newValue) => newValue.copyWith(text: newValue.text.toUpperCase()),
);

// ------------------------------------------------------------- search

/// Arabic-aware normalization so "ايزو", "أيزو" and "ISO" all match.
String normalizeSearch(String input) {
  var s = input.toLowerCase();
  s = s.replaceAll(RegExp('[ً-ْـ]'), '');
  s = s.replaceAll(RegExp('[إأآ]'), 'ا');
  s = s.replaceAll('ى', 'ي').replaceAll('ة', 'ه');
  s = s.replaceAll('ايزو', 'iso').replaceAll('بايثون', 'python').replaceAll('اكسل', 'excel');
  return s;
}

// ------------------------------------------------------------- external apps

Future<void> openExternal(BuildContext context, Uri uri) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final failText = context.t('errors.openApp');
  bool ok = false;
  try {
    ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    ok = false;
  }
  if (!ok) messenger?.showSnackBar(SnackBar(content: Text(failText)));
}

Future<void> callPhone(BuildContext context, String phone) =>
    openExternal(context, Uri(scheme: 'tel', path: phone.replaceAll(RegExp(r'[^\d+]'), '')));

/// WhatsApp needs the international number; Egyptian local numbers start with 0.
String whatsappDigits(String phone) {
  var digits = phone.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('0')) digits = '2$digits';
  return digits;
}

Future<void> openWhatsApp(BuildContext context, String phone) =>
    openExternal(context, Uri.parse('https://wa.me/${whatsappDigits(phone)}'));

Future<void> copyText(BuildContext context, String text, String doneMessage) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  await Clipboard.setData(ClipboardData(text: text));
  messenger?.showSnackBar(SnackBar(content: Text(doneMessage)));
}
