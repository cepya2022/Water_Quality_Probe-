import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../providers/bluetooth_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/sensa_ui.dart';
import 'chat_screen.dart';
import 'config_screen.dart';
import 'scan_screen.dart';
import 'table_screen.dart';
import 'visualize_screen.dart';

/// Tab indices, so screens can navigate to each other by name.
class ShellTab {
  static const int control = 0;
  static const int devices = 1;
  static const int data = 2;
  static const int charts = 3;
  static const int settings = 4;
}

/// Lets any descendant switch tabs, which the Control screen's quick actions
/// rely on ("Traer datos nuevos" jumps to Datos, "Calibrar sensores" to
/// Configuración).
class ShellScope extends InheritedWidget {
  const ShellScope({
    Key? key,
    required this.goToTab,
    required Widget child,
  }) : super(key: key, child: child);

  final ValueChanged<int> goToTab;

  static ShellScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShellScope>();

  @override
  bool updateShouldNotify(ShellScope oldWidget) => false;
}

/// The single-Scaffold shell from the canvas: a header, the active screen, and
/// a five-item bottom bar. It replaces the old drawer-based navigation.
class AppShell extends StatefulWidget {
  const AppShell({Key? key}) : super(key: key);

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = ShellTab.control;
  bool _autoConnectAttempted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAutoConnect());
  }

  /// Honours the "Conectar automáticamente" preference once settings have been
  /// read back from disk.
  void _maybeAutoConnect() {
    if (!mounted || _autoConnectAttempted) return;

    final SettingsProvider settings =
        Provider.of<SettingsProvider>(context, listen: false);

    if (!settings.isLoaded) {
      void onLoaded() {
        if (settings.isLoaded) {
          settings.removeListener(onLoaded);
          _maybeAutoConnect();
        }
      }

      settings.addListener(onLoaded);
      return;
    }

    _autoConnectAttempted = true;
    if (!settings.autoConnect) return;

    final BluetoothProvider bluetooth =
        Provider.of<BluetoothProvider>(context, listen: false);
    if (!bluetooth.isConnected && !bluetooth.isConnecting) {
      bluetooth.connectToLastDevice();
    }
  }

  void _goToTab(int index) {
    if (index == _index) return;
    setState(() => _index = index);
  }

  String _titleFor(int index, AppStrings s) {
    switch (index) {
      case ShellTab.devices:
        return s.titleDevices;
      case ShellTab.data:
        return s.titleData;
      case ShellTab.charts:
        return s.titleCharts;
      case ShellTab.settings:
        return s.titleSettings;
      case ShellTab.control:
      default:
        return s.titleControl;
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;

    return ShellScope(
      goToTab: _goToTab,
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            children: <Widget>[
              _Header(title: _titleFor(_index, s)),
              Expanded(
                child: IndexedStack(
                  index: _index,
                  children: <Widget>[
                    ChatScreen(),
                    ScanScreen(),
                    TableScreen(),
                    VisualizeScreen(),
                    ConfigScreen(),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _NavBar(
          index: _index,
          onSelect: _goToTab,
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  Widget build(BuildContext context) {
    final SensaColors c = context.colors;
    final AppStrings s = context.s;
    final SettingsProvider settings = context.watch<SettingsProvider>();
    final BluetoothProvider bluetooth = context.watch<BluetoothProvider>();

    final String deviceName = bluetooth.connectedDeviceName ??
        bluetooth.lastKnownDeviceName ??
        s.notConnected;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  s.brand,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.54,
                    color: c.muted,
                  ),
                ),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.22,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ConnectionPill(
            connected: bluetooth.isConnected,
            busy: bluetooth.isConnecting,
            label: bluetooth.isConnected ? deviceName : s.notConnected,
            onTap: () {
              if (bluetooth.isConnected) {
                bluetooth.disconnectDevice();
                showSensaToast(context, s.disconnected);
              } else if (!bluetooth.isConnecting) {
                bluetooth.connectToLastDevice();
              }
            },
          ),
          const SizedBox(width: 12),
          SquareIconButton(
            icon: settings.darkMode ? Icons.light_mode : Icons.dark_mode,
            onTap: () => settings.darkMode = !settings.darkMode,
          ),
        ],
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  const _NavBar({Key? key, required this.index, required this.onSelect})
      : super(key: key);

  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final SensaColors c = context.colors;
    final AppStrings s = context.s;

    final List<_NavItem> items = <_NavItem>[
      _NavItem(s.navControl, Icons.tune),
      _NavItem(s.navDevices, Icons.bluetooth),
      _NavItem(s.navData, Icons.table_rows),
      _NavItem(s.navCharts, Icons.show_chart),
      _NavItem(s.navSettings, Icons.settings),
    ];

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              for (int i = 0; i < items.length; i++)
                _NavButton(
                  item: items[i],
                  selected: i == index,
                  onTap: () => onSelect(i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.label, this.icon);

  final String label;
  final IconData icon;
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    Key? key,
    required this.item,
    required this.selected,
    required this.onTap,
  }) : super(key: key);

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final SensaColors c = context.colors;
    final Color tint = selected ? c.accent : c.muted;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            decoration: BoxDecoration(
              color: selected ? c.accentSoft : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(item.icon, size: 22, color: tint),
                const SizedBox(height: 3),
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: tint,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
