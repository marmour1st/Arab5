import 'dart:async';

import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/format.dart';
import '../core/i18n.dart';
import '../core/models.dart';
import '../core/theme.dart';
import '../core/tracks.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';
import '../widgets/program_card.dart';

/// Catalog filters, shared with the home screen so the dial can pre-select a track.
class CatalogFilter extends ChangeNotifier {
  String query = '';
  String? track;
  String? level;

  /// Bumped on every change so the list re-runs its entrance animation.
  int version = 0;

  void setTrack(String? value) {
    track = value;
    version++;
    notifyListeners();
  }

  void setQuery(String value) {
    if (value == query) return;
    query = value;
    version++;
    notifyListeners();
  }

  void setLevel(String? value) {
    level = value;
    version++;
    notifyListeners();
  }

  void clear() {
    query = '';
    track = null;
    level = null;
    version++;
    notifyListeners();
  }

  List<Program> apply(List<Program> all) {
    final words = normalizeSearch(query.trim()).split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    return all.where((p) {
      if (track != null && p.track != track) return false;
      if (level != null && p.level != level) return false;
      if (words.isEmpty) return true;
      final t = trackOf(p.track);
      final hay = normalizeSearch([p.code, p.title.ar, p.title.en, p.summary.ar, p.summary.en, t.ar, t.en].join(' '));
      return words.every(hay.contains);
    }).toList();
  }
}

class ProgramsScreen extends StatefulWidget {
  const ProgramsScreen({super.key, required this.filter});
  final CatalogFilter filter;

  @override
  State<ProgramsScreen> createState() => _ProgramsScreenState();
}

class _ProgramsScreenState extends State<ProgramsScreen> {
  final TextEditingController _search = TextEditingController();
  final ScrollController _scroll = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    widget.filter.addListener(_onFilter);
  }

  void _onFilter() {
    if (_search.text != widget.filter.query) _search.text = widget.filter.query;
    if (_scroll.hasClients && _scroll.offset > 0) {
      _scroll.animateTo(0, duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic);
    }
    setState(() {});
  }

  @override
  void dispose() {
    widget.filter.removeListener(_onFilter);
    _debounce?.cancel();
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final p = Palette.of(context);
    final f = widget.filter;
    final list = f.apply(state.programs);
    final counts = state.trackCounts;
    final lang = state.lang;

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: p.brass,
        onRefresh: state.loadCatalog,
        child: CustomScrollView(controller: _scroll, physics: const AlwaysScrollableScrollPhysics(), slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(context.t('catalog.title'), style: displayStyle(context, 26)),
                const SizedBox(height: 14),
                TextField(
                  controller: _search,
                  textInputAction: TextInputAction.search,
                  onChanged: (v) {
                    _debounce?.cancel();
                    _debounce = Timer(const Duration(milliseconds: 220), () => f.setQuery(v));
                  },
                  decoration: fieldDeco(
                    context,
                    context.t('list.search'),
                    hint: context.t('catalog.search'),
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _search.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () {
                              _search.clear();
                              f.setQuery('');
                            },
                          ),
                  ).copyWith(floatingLabelBehavior: FloatingLabelBehavior.never),
                ),
              ]),
            ),
          ),
          SliverToBoxAdapter(
            child: ChoiceChips(
              selected: f.track ?? '',
              onSelected: (v) => f.setTrack(v.isEmpty ? null : v),
              dots: {for (final t in tracks) t.id: t.color},
              options: [
                MapEntry('', '${context.t('catalog.allTracks')}  ${state.programs.length}'),
                for (final t in tracks) MapEntry(t.id, '${t.name(lang)}  ${counts[t.id] ?? 0}'),
              ],
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 10)),
          SliverToBoxAdapter(
            child: ChoiceChips(
              selected: f.level ?? '',
              onSelected: (v) => f.setLevel(v.isEmpty ? null : v),
              options: [
                MapEntry('', context.t('catalog.allLevels')),
                for (final l in levels) MapEntry(l, context.t('level.$l')),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(
                  context.t('catalog.results', {'n': fmtNum(list.length)}),
                  key: ValueKey(list.length),
                  style: TextStyle(color: p.muted, fontSize: 13),
                ),
              ),
            ),
          ),
          if (state.loadingCatalog && state.programs.isEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList.separated(
                itemCount: 4,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, __) => const Skeleton(height: 170),
              ),
            )
          else if (list.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: Icons.search_off_rounded,
                text: context.t('catalog.empty'),
                actionLabel: context.t('catalog.clear'),
                onAction: () {
                  _search.clear();
                  f.clear();
                },
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              sliver: SliverList.separated(
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) => Reveal(
                  key: ValueKey('${f.version}-${list[i].code}'),
                  delay: Duration(milliseconds: (i % 8) * 45),
                  offset: 16,
                  child: ProgramCard(program: list[i], heroPrefix: 'list'),
                ),
              ),
            ),
        ]),
      ),
    );
  }
}
