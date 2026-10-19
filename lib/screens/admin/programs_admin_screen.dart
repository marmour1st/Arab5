import 'package:flutter/material.dart';

import '../../core/api.dart';
import '../../core/app_state.dart';
import '../../core/i18n.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';
import '../../widgets/motion.dart';
import 'admin_common.dart';

/// Publish or hide programs. Full editing stays on the website's admin panel.
class ProgramsAdminScreen extends StatefulWidget {
  const ProgramsAdminScreen({super.key});

  @override
  State<ProgramsAdminScreen> createState() => _ProgramsAdminScreenState();
}

class _ProgramsAdminScreenState extends State<ProgramsAdminScreen> {
  List<Program> _items = const [];
  bool _loading = true;
  Object? _error;
  final Set<String> _busy = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await AppScope.read(context).api.get('/admin/programs');
      if (!mounted) return;
      final items = data is Map && data['items'] is List ? data['items'] as List : const [];
      setState(() => _items = items.whereType<Map>().map((e) => Program.fromJson(Map<String, dynamic>.from(e))).toList());
    } catch (e) {
      if (!mounted) return;
      if (e is ApiException && e.status == 401) {
        handleAdminError(context, e);
        return;
      }
      setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggle(Program program, bool active) async {
    setState(() => _busy.add(program.id));
    try {
      await AppScope.read(context).api.patch('/admin/programs/${program.id}/active', {'active': active});
      if (!mounted) return;
      setState(() => _items = [for (final x in _items) x.id == program.id ? x.copyWith(active: active) : x]);
      toast(context, context.t('msg.saved'));
      AppScope.read(context).loadCatalog();
    } catch (e) {
      if (mounted) handleAdminError(context, e);
    } finally {
      if (mounted) setState(() => _busy.remove(program.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final lang = context.lang;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: p.navy,
        foregroundColor: Palette.light.onNavy,
        surfaceTintColor: Colors.transparent,
        title: Text(context.t('admin.programs')),
      ),
      body: _loading && _items.isEmpty
          ? ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: 6,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, __) => const Skeleton(height: 72),
            )
          : _error != null && _items.isEmpty
              ? EmptyState(icon: Icons.cloud_off_rounded, text: errorMessage(context, _error!), actionLabel: context.t('act.retry'), onAction: _load)
              : RefreshIndicator(
                  color: p.brass,
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    itemCount: _items.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      if (i == 0) {
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: p.brassSoft, borderRadius: BorderRadius.circular(14)),
                          child: Row(children: [
                            Icon(Icons.info_outline_rounded, color: p.brass),
                            const SizedBox(width: 10),
                            Expanded(child: Text(context.t('prog.editOnWeb'), style: const TextStyle(height: 1.5))),
                          ]),
                        );
                      }
                      final pr = _items[i - 1];
                      return Reveal(
                        delay: Duration(milliseconds: ((i - 1) % 10) * 35),
                        offset: 12,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 250),
                          opacity: pr.active ? 1 : 0.6,
                          child: Panel(
                            padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
                            child: Row(children: [
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Row(children: [
                                    CodeTag(pr.code),
                                    const SizedBox(width: 10),
                                    Flexible(child: TrackTag(pr.track, short: true)),
                                  ]),
                                  const SizedBox(height: 4),
                                  Text(pr.title.pick(lang), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                                ]),
                              ),
                              Switch(
                                value: pr.active,
                                activeTrackColor: p.ok,
                                onChanged: _busy.contains(pr.id) ? null : (v) => _toggle(pr, v),
                              ),
                            ]),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
