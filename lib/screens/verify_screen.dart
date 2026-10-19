import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/app_state.dart';
import '../core/format.dart';
import '../core/i18n.dart';
import '../core/models.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';

class VerifyScreen extends StatefulWidget {
  const VerifyScreen({super.key});

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

enum _Outcome { none, valid, revoked, notFound, badFormat }

class _VerifyScreenState extends State<VerifyScreen> with SingleTickerProviderStateMixin {
  final _code = TextEditingController();
  late final AnimationController _shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
  bool _busy = false;
  _Outcome _outcome = _Outcome.none;
  Certificate? _cert;
  int _attempt = 0;

  static final _re = RegExp(r'^AA-\d{4}-[2-9A-Z]{6}$');

  @override
  void dispose() {
    _code.dispose();
    _shake.dispose();
    super.dispose();
  }

  void _fail(_Outcome outcome) {
    setState(() {
      _outcome = outcome;
      _cert = null;
      _attempt++;
    });
    if (!reduceMotion(context)) _shake.forward(from: 0);
  }

  Future<void> _verify() async {
    final code = _code.text.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '');
    _code.text = code;
    FocusScope.of(context).unfocus();
    if (!_re.hasMatch(code)) {
      _fail(_Outcome.badFormat);
      return;
    }
    setState(() => _busy = true);
    try {
      final data = await AppScope.read(context).api.get('/certificates/${Uri.encodeComponent(code)}');
      if (!mounted) return;
      final cert = Certificate.fromJson(Map<String, dynamic>.from(data as Map));
      setState(() {
        _cert = cert;
        _outcome = cert.revoked ? _Outcome.revoked : _Outcome.valid;
        _attempt++;
      });
      if (cert.revoked && !reduceMotion(context)) _shake.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      if (e is ApiException && e.status == 404) {
        _fail(_Outcome.notFound);
      } else {
        toast(context, errorMessage(context, e), error: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final onNavy = Palette.light.onNavy;
    return ListView(padding: EdgeInsets.zero, children: [
      NavyHeader(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Reveal(child: Eyebrow(context.t('verify.eyebrow'), color: Palette.brassOnNavy)),
          const SizedBox(height: 12),
          Reveal(
            delay: const Duration(milliseconds: 80),
            child: Text(context.t('verify.title'), style: displayStyle(context, 24, color: onNavy)),
          ),
          const SizedBox(height: 8),
          Reveal(
            delay: const Duration(milliseconds: 160),
            child: Text(context.t('verify.lead'), style: TextStyle(color: Palette.light.onNavyMuted, height: 1.6)),
          ),
          const SizedBox(height: 22),
          Reveal(
            delay: const Duration(milliseconds: 240),
            child: AnimatedBuilder(
              animation: _shake,
              builder: (context, child) {
                final t = _shake.value;
                final dx = t == 0 || t == 1 ? 0.0 : 8 * (1 - t) * (t * 20).floor().isEven.toSign();
                return Transform.translate(offset: Offset(dx, 0), child: child);
              },
              child: TextField(
                controller: _code,
                textDirection: TextDirection.ltr,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [upperCaseFormatter],
                autocorrect: false,
                enableSuggestions: false,
                maxLength: 20,
                onSubmitted: (_) => _verify(),
                style: monoStyle(size: 17, color: onNavy, weight: FontWeight.w600),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: 'AA-2026-XXXXXX',
                  hintTextDirection: TextDirection.ltr,
                  hintStyle: monoStyle(size: 17, color: fade(onNavy, 0.35)),
                  filled: true,
                  fillColor: fade(onNavy, 0.06),
                  prefixIcon: Icon(Icons.qr_code_2_rounded, color: fade(onNavy, 0.6)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: fade(onNavy, 0.25), width: 1.4),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Palette.brassOnNavy, width: 2),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Reveal(
            delay: const Duration(milliseconds: 300),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _busy ? null : _verify,
                style: FilledButton.styleFrom(backgroundColor: Palette.brassOnNavy, foregroundColor: const Color(0xFF1A1205)),
                icon: _busy
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2, color: Color(0xFF1A1205)))
                    : const Icon(Icons.verified_user_outlined),
                label: Text(context.t('verify.button')),
              ),
            ),
          ),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 450),
          switchInCurve: Curves.easeOutCubic,
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, -0.06), end: Offset.zero).animate(anim),
              child: child,
            ),
          ),
          child: _result(context),
        ),
      ),
    ]);
  }

  Widget _result(BuildContext context) {
    final p = Palette.of(context);
    final lang = context.lang;
    switch (_outcome) {
      case _Outcome.none:
        return const SizedBox.shrink(key: ValueKey('none'));
      case _Outcome.badFormat:
      case _Outcome.notFound:
        return _ResultCard(
          key: ValueKey('bad-$_attempt'),
          ok: false,
          title: context.t(_outcome == _Outcome.badFormat ? 'verify.format' : 'verify.notFound'),
        );
      case _Outcome.valid:
      case _Outcome.revoked:
        final c = _cert!;
        return _ResultCard(
          key: ValueKey('cert-$_attempt'),
          ok: _outcome == _Outcome.valid,
          title: context.t(_outcome == _Outcome.valid ? 'verify.valid' : 'verify.revoked'),
          rows: [
            MapEntry(context.t('verify.holder'), c.holderName),
            MapEntry(context.t('verify.program'), '${c.programTitle.pick(lang)} (${c.programCode})'),
            if (c.hours > 0) MapEntry(context.t('verify.hours'), fmtNum(c.hours)),
            MapEntry(context.t('verify.issued'), fmtDate(c.issuedAt, lang)),
          ],
          codeColor: p.muted,
        );
    }
    // ignore: dead_code
    return const SizedBox.shrink();
  }
}

extension on bool {
  double toSign() => this ? 1.0 : -1.0;
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({super.key, required this.ok, required this.title, this.rows = const [], this.codeColor});
  final bool ok;
  final String title;
  final List<MapEntry<String, String>> rows;
  final Color? codeColor;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final color = ok ? p.ok : p.bad;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ok ? p.okSoft : p.badSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: fade(color, 0.5), width: 1.4),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: reduceMotion(context) ? Duration.zero : const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            builder: (context, v, child) => Transform.scale(scale: v, child: child),
            child: Icon(ok ? Icons.verified_rounded : Icons.error_outline_rounded, color: color, size: 26),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 15.5, height: 1.4))),
        ]),
        if (rows.isNotEmpty) ...[
          const SizedBox(height: 14),
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(width: 110, child: Text(r.key, style: TextStyle(color: p.muted, fontSize: 13))),
                Expanded(child: Text(r.value, style: const TextStyle(fontWeight: FontWeight.w600, height: 1.45))),
              ]),
            ),
        ],
      ]),
    );
  }
}
