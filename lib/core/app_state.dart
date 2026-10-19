import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api.dart';
import 'config.dart';
import 'models.dart';
import 'tracks.dart';

/// App-wide state: language, theme, program catalog and the admin session.
class AppState extends ChangeNotifier {
  AppState(this._prefs)
      : lang = _prefs.getString('lang') ?? 'ar',
        themeMode = _themeFrom(_prefs.getString('theme')),
        adminToken = _prefs.getString('admin_token') {
    api = ApiClient(this);
  }

  final SharedPreferences _prefs;
  late final ApiClient api;

  String lang;
  ThemeMode themeMode;

  List<Program> programs = const [];
  bool loadingCatalog = true;
  bool catalogLive = false;
  int trainees = 5000;
  int years = 15;
  String phone = AppConfig.phone;
  String whatsapp = AppConfig.whatsapp;

  String? adminToken;
  AdminUser? admin;

  bool get isAdmin => adminToken != null && adminToken!.isNotEmpty;

  static ThemeMode _themeFrom(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  void setLang(String value) {
    if (value == lang) return;
    lang = value;
    _prefs.setString('lang', value);
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    if (mode == themeMode) return;
    themeMode = mode;
    _prefs.setString('theme', mode.name);
    notifyListeners();
  }

  Map<String, int> get trackCounts {
    final counts = <String, int>{for (final t in tracks) t.id: 0};
    for (final p in programs) {
      counts[p.track] = (counts[p.track] ?? 0) + 1;
    }
    return counts;
  }

  Program? programByCode(String code) {
    for (final p in programs) {
      if (p.code == code) return p;
    }
    return null;
  }

  List<Program> _parsePrograms(dynamic list) {
    final items = list is List ? list : const [];
    final parsed = items.whereType<Map>().map((e) => Program.fromJson(Map<String, dynamic>.from(e))).toList();
    parsed.sort((a, b) {
      final byTrack = trackIndex(a.track).compareTo(trackIndex(b.track));
      if (byTrack != 0) return byTrack;
      final byOrder = a.order.compareTo(b.order);
      return byOrder != 0 ? byOrder : a.code.compareTo(b.code);
    });
    return parsed;
  }

  /// Shows the bundled catalog instantly, then refreshes it from the server.
  Future<void> loadCatalog() async {
    if (programs.isEmpty) {
      try {
        final raw = await rootBundle.loadString('assets/data/programs.json');
        final json = jsonDecode(raw);
        if (json is Map) programs = _parsePrograms(json['programs']);
      } catch (_) {
        // Bundled file missing or invalid: wait for the server.
      }
    }
    loadingCatalog = programs.isEmpty;
    notifyListeners();

    try {
      final data = await api.get('/programs');
      final live = _parsePrograms(data is Map ? data['programs'] : null);
      if (live.isNotEmpty) programs = live;
      catalogLive = true;
      try {
        final stats = await api.get('/stats');
        if (stats is Map) {
          trainees = (stats['trainees'] as num?)?.toInt() ?? trainees;
          years = (stats['years'] as num?)?.toInt() ?? years;
          final contact = stats['contact'];
          if (contact is Map) {
            phone = (contact['phone'] ?? phone).toString();
            whatsapp = (contact['whatsapp'] ?? whatsapp).toString();
          }
        }
      } catch (_) {
        // Stats are optional.
      }
    } catch (_) {
      catalogLive = false;
    }
    loadingCatalog = false;
    notifyListeners();
  }

  // ---------------------------------------------------------------- admin

  void storeToken(String? token) {
    final value = (token == null || token.isEmpty) ? null : token;
    if (value == adminToken) return;
    adminToken = value;
    if (value == null) {
      admin = null;
      _prefs.remove('admin_token');
    } else {
      _prefs.setString('admin_token', value);
    }
    notifyListeners();
  }

  void handleUnauthorized() => storeToken(null);

  Future<void> adminLogin(String email, String password) async {
    final data = await api.post('/auth/login', {'email': email, 'password': password});
    if (!isAdmin) throw ApiException(0, 'no_session');
    if (data is Map && data['admin'] is Map) {
      admin = AdminUser.fromJson(Map<String, dynamic>.from(data['admin'] as Map));
    }
    notifyListeners();
  }

  /// Checks a saved session. Returns false if the user must sign in again.
  Future<bool> restoreAdmin() async {
    if (!isAdmin) return false;
    try {
      final data = await api.get('/auth/me');
      if (data is Map && data['admin'] is Map) {
        admin = AdminUser.fromJson(Map<String, dynamic>.from(data['admin'] as Map));
        notifyListeners();
      }
      return true;
    } on ApiException catch (e) {
      if (e.status == 401) storeToken(null);
      // Network problems: keep the saved session and let screens retry.
      return e.status != 401;
    }
  }

  Future<void> adminLogout() async {
    try {
      await api.post('/auth/logout');
    } catch (_) {
      // Signing out locally is enough if the server is unreachable.
    }
    storeToken(null);
  }
}

/// Makes [AppState] available to the whole widget tree.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required super.notifier, required super.child});

  /// Read the state and rebuild when it changes.
  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  /// Read the state without subscribing (for callbacks).
  static AppState read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
