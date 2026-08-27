import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'l10n/strings.dart';
import 'providers/bluetooth_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/app_shell.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(
    MultiProvider(
      providers: <ChangeNotifierProvider<ChangeNotifier>>[
        ChangeNotifierProvider<BluetoothProvider>(
          create: (BuildContext context) => BluetoothProvider(),
        ),
        ChangeNotifierProvider<SettingsProvider>(
          create: (BuildContext context) => SettingsProvider(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final SettingsProvider settings = context.watch<SettingsProvider>();
    final bool isDark = settings.darkMode;
    final SensaColors colors = isDark ? SensaColors.dark : SensaColors.light;

    // SensaTheme sits above MaterialApp so pushed routes (the fullscreen
    // chart, sheets and dialogs) inherit the palette too.
    return SensaTheme(
      colors: colors,
      isDark: isDark,
      child: AppStringsScope(
        strings: settings.strings,
        child: MaterialApp(
          title: 'SENSA · Water Quality Probe',
          theme: buildSensaThemeData(colors, isDark),
          home: const AppShell(),
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}
