import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Brand palette — same tokens as the website (navy instrument panel + brass accent).
class Palette {
  const Palette({
    required this.paper,
    required this.surface,
    required this.surface2,
    required this.ink,
    required this.muted,
    required this.line,
    required this.brass,
    required this.brassStrong,
    required this.brassSoft,
    required this.onBrass,
    required this.navy,
    required this.navy2,
    required this.onNavy,
    required this.onNavyMuted,
    required this.ok,
    required this.okSoft,
    required this.bad,
    required this.badSoft,
    required this.info,
  });

  final Color paper;
  final Color surface;
  final Color surface2;
  final Color ink;
  final Color muted;
  final Color line;
  final Color brass;
  final Color brassStrong;
  final Color brassSoft;
  final Color onBrass;
  final Color navy;
  final Color navy2;
  final Color onNavy;
  final Color onNavyMuted;
  final Color ok;
  final Color okSoft;
  final Color bad;
  final Color badSoft;
  final Color info;

  static const light = Palette(
    paper: Color(0xFFF3F5F8),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFEAEEF4),
    ink: Color(0xFF0E1B2D),
    muted: Color(0xFF566479),
    line: Color(0xFFD6DDE7),
    brass: Color(0xFFA8741F),
    brassStrong: Color(0xFF8C5F15),
    brassSoft: Color(0xFFF4EAD9),
    onBrass: Color(0xFFFFFFFF),
    navy: Color(0xFF0D2140),
    navy2: Color(0xFF13305A),
    onNavy: Color(0xFFEEF2F8),
    onNavyMuted: Color(0xFFA9B8CD),
    ok: Color(0xFF18794E),
    okSoft: Color(0xFFE3F4EC),
    bad: Color(0xFFB42318),
    badSoft: Color(0xFFFDE8E6),
    info: Color(0xFF2F6FDB),
  );

  static const dark = Palette(
    paper: Color(0xFF0A111D),
    surface: Color(0xFF101A2B),
    surface2: Color(0xFF16233A),
    ink: Color(0xFFE7EDF5),
    muted: Color(0xFF9BADC3),
    line: Color(0xFF24344D),
    brass: Color(0xFFE2AC53),
    brassStrong: Color(0xFFF0C172),
    brassSoft: Color(0xFF2A2416),
    onBrass: Color(0xFF1A1205),
    navy: Color(0xFF0B182C),
    navy2: Color(0xFF12233F),
    onNavy: Color(0xFFEEF2F8),
    onNavyMuted: Color(0xFF9FB0C8),
    ok: Color(0xFF4CC38A),
    okSoft: Color(0xFF10291F),
    bad: Color(0xFFFF7A6B),
    badSoft: Color(0xFF321613),
    info: Color(0xFF7AA7FF),
  );

  /// Brass that reads well on the navy panels in both themes.
  static const Color brassOnNavy = Color(0xFFE2AC53);

  static Palette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

/// Color with a given opacity (0..1), without relying on APIs that changed between Flutter versions.
Color fade(Color c, double opacity) => c.withAlpha((opacity.clamp(0.0, 1.0) * 255).round());

TextStyle _font(String family, TextStyle base) {
  try {
    return GoogleFonts.getFont(family, textStyle: base);
  } catch (_) {
    return base;
  }
}

/// Display face (headlines).
TextStyle displayStyle(BuildContext context, double size,
    {Color? color, FontWeight weight = FontWeight.w700, double height = 1.3}) {
  return _font('Alexandria', TextStyle(fontSize: size, fontWeight: weight, height: height, color: color ?? Palette.of(context).ink));
}

/// Monospace face (program codes, certificate codes).
TextStyle monoStyle({double size = 13, Color? color, FontWeight weight = FontWeight.w500}) {
  return _font('IBM Plex Mono', TextStyle(fontSize: size, color: color, fontWeight: weight, letterSpacing: 0.4));
}

final Map<Brightness, ThemeData> _cache = {};

ThemeData buildTheme(Brightness brightness) => _cache.putIfAbsent(brightness, () => _build(brightness));

ThemeData _build(Brightness b) {
  final p = b == Brightness.dark ? Palette.dark : Palette.light;
  final scheme = ColorScheme.fromSeed(seedColor: p.brass, brightness: b).copyWith(
    primary: p.brass,
    onPrimary: p.onBrass,
    secondary: p.navy2,
    onSecondary: p.onNavy,
    surface: p.surface,
    onSurface: p.ink,
    error: p.bad,
    outline: p.line,
    outlineVariant: p.line,
  );

  final base = ThemeData(
    useMaterial3: true,
    brightness: b,
    colorScheme: scheme,
    scaffoldBackgroundColor: p.paper,
    splashFactory: InkSparkle.splashFactory,
  );

  var text = base.textTheme.apply(bodyColor: p.ink, displayColor: p.ink);
  try {
    text = GoogleFonts.getTextTheme('IBM Plex Sans Arabic', text);
  } catch (_) {
    // Font unavailable (offline first launch): keep the system font.
  }

  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));
  const pad = EdgeInsets.symmetric(horizontal: 20, vertical: 14);
  final label = text.labelLarge?.copyWith(fontWeight: FontWeight.w700, fontSize: 15);

  return base.copyWith(
    textTheme: text,
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: p.brass,
        foregroundColor: p.onBrass,
        disabledBackgroundColor: fade(p.brass, 0.5),
        disabledForegroundColor: fade(p.onBrass, 0.8),
        shape: shape,
        padding: pad,
        minimumSize: const Size(64, 52),
        textStyle: label,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: p.ink,
        side: BorderSide(color: p.line, width: 1.4),
        shape: shape,
        padding: pad,
        minimumSize: const Size(64, 52),
        textStyle: label,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: p.brass, textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: p.surface,
      indicatorColor: p.brassSoft,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 68,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: p.ink,
      contentTextStyle: text.bodyMedium?.copyWith(color: p.paper),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    dividerTheme: DividerThemeData(color: p.line, thickness: 1, space: 1),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: p.line,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: p.brass),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: p.brass,
      selectionHandleColor: p.brass,
      selectionColor: fade(p.brass, 0.3),
    ),
    iconTheme: IconThemeData(color: p.ink),
  );
}

/// Shared text-field look.
InputDecoration fieldDeco(BuildContext context, String label, {String? hint, Widget? prefixIcon, Widget? suffixIcon}) {
  final p = Palette.of(context);
  OutlineInputBorder border(Color c, [double w = 1.4]) =>
      OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: c, width: w));
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: p.surface,
    labelStyle: TextStyle(color: p.muted),
    floatingLabelStyle: TextStyle(color: p.brass, fontWeight: FontWeight.w600),
    hintStyle: TextStyle(color: fade(p.muted, 0.7)),
    border: border(p.line),
    enabledBorder: border(p.line),
    focusedBorder: border(p.brass, 2),
    errorBorder: border(p.bad),
    focusedErrorBorder: border(p.bad, 2),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  );
}
