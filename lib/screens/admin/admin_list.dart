import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/api.dart';
import '../../core/app_state.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';
import '../../widgets/motion.dart';
import 'admin_common.dart';

typedef AdminItemBuilder<T> = Widget Function(BuildContext context, T item, Future<void> Function() reload);

/// Searchable, filterable, paginated list backed by an admin endpoint
/// that returns `{items, total, page, pages}`.
class AdminList<T> extends StatefulWidget {
  const AdminList({
    super.key,
    required this.endpoint,
    required this.parse,
    required this.itemBuilder,
    this.statuses = const [],
    this.statusLabel,
    this.header,
  });

  final String endpoint;
  final T Function(Map<String, dynamic> json) parse;
  final AdminItemBuilder<T> itemBuilder;
  final List<String> statuses;
  final String Function(BuildContext context, String status)? statusLabel;
  final Widget? header;

  @override
  State<AdminList<T>> createState() => AdminListState<T>();
}

class AdminListState<T> extends State<AdminList<T>> with AutomaticKeepAliveClientMixin {
  final List<T> _items = [];
  final ScrollController _scroll = ScrollController();
  final TextEditingController _search = TextEditingController();
  Timer? _debounce;
  int _page = 1;
  int _pages = 1;
  int _total = 0;
  int _version = 0;
  bool _loading = true;
  bool _loadingMore = false;
  Object? _error;
  String _status = '';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) reload();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final pos = _scroll.position;
    if (pos.pixels > pos.maxScrollExtent - 300 && !_loading && !_loadingMore && _page < _pages) {
      _loadMore();
    }
  }

  String _url(int page) {
    final query = Uri(queryParameters: {
      'q': _search.text.trim(),
      'status': _status,
      'page': '$page',
      'limit': '25',
    }).query;
    return '${widget.endpoint}?$query';
  }

  List<T> _parse(dynamic data) {
    final items = data is Map ? data['items'] : null;
    if (items is! List) return <T>[];
    return items.whereType<Map>().map((e) => widget.parse(Map<String, dynamic>.from(e))).toList();
  }

  int _num(dynamic data, String key, int fallback) {
    if (data is Map && data[key] is num) return (data[key] as num).toInt();
    return fallback;
  }

  Future<void> reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await AppScope.read(context).api.get(_url(1));
      if (!mounted) return;
      final list = _parse(data);
      setState(() {
        _items
          ..clear()
          ..addAll(list);
        _page = _num(data, 'page', 1);
        _pages = _num(data, 'pages', 1);
        _total = _num(data, 'total', list.length);
        _version++;
      });
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

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    try {
      final data = await AppScope.read(context).api.get(_url(_page + 1));
      if (!mounted) return;
      final list = _parse(data);
      setState(() {
        _items.addAll(list);
        _page = _num(data, 'page', _page + 1);
        _pages = _num(data, 'pages', _pages);
      });
    } catch (e) {
      if (mounted) handleAdminError(context, e);
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final p = Palette.of(context);
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: TextField(
          controller: _search,
          textInputAction: TextInputAction.search,
          onChanged: (_) {
            _debounce?.cancel();
            _debounce = Timer(const Duration(milliseconds: 350), reload);
          },
          decoration: fieldDeco(context, context.t('list.search'), prefixIcon: const Icon(Icons.search_rounded))
              .copyWith(floatingLabelBehavior: FloatingLabelBehavior.never, isDense: true),
        ),
      ),
      if (widget.statuses.isNotEmpty) ...[
        ChoiceChips(
          selected: _status,
          onSelected: (v) {
            _status = v;
            reload();
          },
          options: [
            MapEntry('', context.t('list.all')),
            for (final s in widget.statuses) MapEntry(s, widget.statusLabel?.call(context, s) ?? s),
          ],
        ),
        const SizedBox(height: 6),
      ],
      if (widget.header != null) widget.header!,
      Expanded(
        child: RefreshIndicator(
          color: p.brass,
          onRefresh: reload,
          child: _body(context),
        ),
      ),
    ]);
  }

  Widget _body(BuildContext context) {
    final p = Palette.of(context);
    const physics = AlwaysScrollableScrollPhysics();
    if (_loading && _items.isEmpty) {
      return ListView.separated(
        physics: physics,
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, __) => const Skeleton(height: 96),
      );
    }
    if (_error != null && _items.isEmpty) {
      return ListView(physics: physics, children: [
        EmptyState(
          icon: Icons.cloud_off_rounded,
          text: errorMessage(context, _error!),
          actionLabel: context.t('act.retry'),
          onAction: reload,
        ),
      ]);
    }
    if (_items.isEmpty) {
      return ListView(physics: physics, children: [EmptyState(icon: Icons.inbox_outlined, text: context.t('list.empty'))]);
    }
    return ListView.separated(
      controller: _scroll,
      physics: physics,
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 96),
      itemCount: _items.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        if (i == _items.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: _loadingMore
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.4))
                  : Text(context.t('list.total', {'n': fmtNum(_total)}), style: TextStyle(color: p.muted, fontSize: 12.5)),
            ),
          );
        }
        return Reveal(
          key: ValueKey('$_version-$i'),
          delay: Duration(milliseconds: (i % 10) * 35),
          offset: 12,
          child: widget.itemBuilder(context, _items[i], reload),
        );
      },
    );
  }
}
