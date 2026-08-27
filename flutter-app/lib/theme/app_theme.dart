import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens taken verbatim from the ProbeApp canvas (`ProbeApp.dc.html`).
///
/// The canvas drives every colour through CSS custom properties, so the whole
/// palette lives here and both themes expose the same names.
@immutable
class SensaColors {
  const SensaColors({
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.border,
    required this.text,
    required this.muted,
    required this.accent,
    required this.accentInk,
    required this.accentSoft,
  });

  final Color bg;
  final Color surface;
  final Color surface2;
  final Color border;
  final Color text;
  final Color muted;
  final Color accent;

  /// Text/icon colour that sits on top of [accent].
  final Color accentInk;

  /// Translucent accent used for selected chips and the active nav pill.
  final Color accentSoft;

  static const SensaColors dark = SensaColors(
    bg: Color(0xFF14161F),
    surface: Color(0xFF1C1F2C),
    surface2: Color(0xFF252939),
    border: Color(0xFF2E3446),
    text: Color(0xFFEEF1F6),
    muted: Color(0xFF98A1B8),
    accent: Color(0xFF46CFC5),
    accentInk: Color(0xFF06231F),
    accentSoft: Color(0x2446CFC5), // rgba(70,207,197,.14)
  );

  static const SensaColors light = SensaColors(
    bg: Color(0xFFEDF1F4),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFF2F5F8),
    border: Color(0xFFD6DDE5),
    text: Color(0xFF0E141C),
    muted: Color(0xFF5C6675),
    accent: Color(0xFF0E8F86),
    accentInk: Color(0xFFFFFFFF),
    accentSoft: Color(0x1A0E8F86), // rgba(14,143,134,.10)
  );
}

/// Makes [SensaColors] reachable from any widget without threading it through
/// constructors, mirroring how the canvas inherits its CSS variables.
class SensaTheme extends InheritedWidget {
  const SensaTheme({
    Key? key,
    required this.colors,
    required this.isDark,
    required Widget child,
  }) : super(key: key, child: child);

  final SensaColors colors;
  final bool isDark;

  static SensaTheme _of(BuildContext context) {
    final theme = context.dependOnInheritedWidgetOfExactType<SensaTheme>();
    assert(theme != null, 'No SensaTheme found in context');
    return theme!;
  }

  static SensaColors colorsOf(BuildContext context) => _of(context).colors;

  static bool isDarkOf(BuildContext context) => _of(context).isDark;

  @override
  bool updateShouldNotify(SensaTheme oldWidget) => oldWidget.isDark != isDark;
}

extension SensaThemeX on BuildContext {
  /// Shorthand for the active palette: `context.colors.accent`.
  SensaColors get colors => SensaTheme.colorsOf(this);
}

/// Tabular figures used for every reading, timestamp and axis label, matching
/// the canvas' JetBrains Mono runs.
TextStyle monoStyle({
  double fontSize = 13,
  FontWeight fontWeight = FontWeight.w500,
  Color? color,
  double? letterSpacing,
  double? height,
}) {
  return GoogleFonts.jetBrainsMono(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    letterSpacing: letterSpacing,
    height: height,
  );
}

/// Small uppercase section label ("MEDICIÓN", "ACCIONES", ...).
TextStyle eyebrowStyle(Color color) => TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.66,
      color: color,
    );

ThemeData buildSensaThemeData(SensaColors c, bool isDark) {
  final base = isDark ? ThemeData.dark() : ThemeData.light();
  return base.copyWith(
    scaffoldBackgroundColor: c.bg,
    canvasColor: c.surface,
    dividerColor: c.border,
    splashColor: c.accentSoft,
    highlightColor: c.accentSoft,
    colorScheme: base.colorScheme.copyWith(
      brightness: isDark ? Brightness.dark : Brightness.light,
      primary: c.accent,
      onPrimary: c.accentInk,
      secondary: c.accent,
      onSecondary: c.accentInk,
      surface: c.surface,
      onSurface: c.text,
      error: const Color(0xFFF44336),
    ),
    textTheme: GoogleFonts.poppinsTextTheme(base.textTheme)
        .apply(bodyColor: c.text, displayColor: c.text),
    iconTheme: IconThemeData(color: c.muted),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: c.accent,
      selectionColor: c.accentSoft,
      selectionHandleColor: c.accent,
    ),
  );
}
