import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Small uppercase heading that introduces a group ("ACCIONES", "SENSORES").
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {Key? key, this.padding}) : super(key: key);

  final String text;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.fromLTRB(2, 2, 2, 8),
      child:
          Text(text.toUpperCase(), style: eyebrowStyle(context.colors.muted)),
    );
  }
}

/// The rounded surface panel every screen is built from.
class SensaCard extends StatelessWidget {
  const SensaCard({
    Key? key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 20,
    this.onTap,
    this.clip = false,
    this.borderColor,
    this.color,
  }) : super(key: key);

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final bool clip;
  final Color? borderColor;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final SensaColors c = context.colors;
    final BorderRadius shape = BorderRadius.circular(radius);

    final Widget body = Container(
      decoration: BoxDecoration(
        color: color ?? c.surface,
        borderRadius: shape,
        border: Border.all(color: borderColor ?? c.border),
      ),
      clipBehavior: clip ? Clip.antiAlias : Clip.none,
      child: Padding(padding: padding, child: child),
    );

    if (onTap == null) return body;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: shape,
        child: body,
      ),
    );
  }
}

/// Pill-shaped selector used for intervals, ranges, parameters and decimals.
class SensaChip extends StatelessWidget {
  const SensaChip({
    Key? key,
    required this.label,
    required this.selected,
    this.onTap,
    this.dotColor,
    this.height = 34,
    this.fontSize = 12,
    this.horizontalPadding = 14,
  }) : super(key: key);

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final Color? dotColor;
  final double height;
  final double fontSize;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final SensaColors c = context.colors;
    final Color foreground = selected ? c.accent : c.muted;

    return Material(
      color: selected ? c.accentSoft : c.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: height,
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? c.accent : c.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (dotColor != null) ...<Widget>[
                ColorDot(color: dotColor!),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w500,
                  color: foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The 8px series dot that precedes parameter names.
class ColorDot extends StatelessWidget {
  const ColorDot({Key? key, required this.color, this.size = 8})
      : super(key: key);

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

/// 48x28 track with a 22px knob, matching the canvas' toggles.
class SensaSwitch extends StatelessWidget {
  const SensaSwitch({Key? key, required this.value, this.onChanged})
      : super(key: key);

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final SensaColors c = context.colors;

    return GestureDetector(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: 48,
        height: 28,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: value ? c.accent : c.border,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: value ? c.accentInk : c.surface,
            borderRadius: BorderRadius.circular(11),
          ),
        ),
      ),
    );
  }
}

/// Square icon button used for the theme toggle and the chart tools.
class SquareIconButton extends StatelessWidget {
  const SquareIconButton({
    Key? key,
    required this.icon,
    this.onTap,
    this.size = 40,
    this.radius = 14,
    this.iconSize = 20,
    this.filled = false,
    this.tooltip,
  }) : super(key: key);

  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final double radius;
  final double iconSize;
  final bool filled;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final SensaColors c = context.colors;

    Widget button = Material(
      color: filled ? c.accent : c.surface,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: filled ? null : Border.all(color: c.border),
          ),
          child: Icon(
            icon,
            size: iconSize,
            color: filled ? c.accentInk : c.muted,
          ),
        ),
      ),
    );

    if (tooltip != null) {
      button = Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}

/// Connection status pill in the header: a dot, the device name, and a tap
/// target that connects or disconnects.
class ConnectionPill extends StatelessWidget {
  const ConnectionPill({
    Key? key,
    required this.connected,
    required this.label,
    required this.onTap,
    this.busy = false,
  }) : super(key: key);

  final bool connected;
  final String label;
  final VoidCallback onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final SensaColors c = context.colors;
    final Color tint = connected ? c.accent : c.muted;

    return Material(
      color: connected ? c.accentSoft : Colors.transparent,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          constraints: const BoxConstraints(maxWidth: 150),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: connected ? c.accent : c.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (busy)
                SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.6,
                    valueColor: AlwaysStoppedAnimation<Color>(tint),
                  ),
                )
              else
                ColorDot(color: connected ? c.accent : const Color(0xFFF44336)),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: tint,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A tappable row with a leading accent icon, title, subtitle and chevron.
class ActionRow extends StatelessWidget {
  const ActionRow({
    Key? key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.sub,
  }) : super(key: key);

  final IconData icon;
  final String label;
  final String? sub;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final SensaColors c = context.colors;

    return SensaCard(
      radius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      onTap: onTap,
      child: SizedBox(
        height: 56,
        child: Row(
          children: <Widget>[
            Icon(icon, size: 20, color: c.accent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (sub != null)
                    Text(
                      sub!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: c.muted),
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: c.muted),
          ],
        ),
      ),
    );
  }
}

/// Placeholder shown wherever the canvas assumes seeded data but the app has
/// none yet.
class EmptyState extends StatelessWidget {
  const EmptyState({
    Key? key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  }) : super(key: key);

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final SensaColors c = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 40, color: c.muted.withAlpha(153)),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
          if (message != null) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: c.muted, height: 1.5),
            ),
          ],
          if (action != null) ...<Widget>[
            const SizedBox(height: 18),
            action!,
          ],
        ],
      ),
    );
  }
}

/// Horizontally scrolling strip of chips without a visible scrollbar.
class ChipStrip extends StatelessWidget {
  const ChipStrip({Key? key, required this.children, this.spacing = 7})
      : super(key: key);

  final List<Widget> children;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const ClampingScrollPhysics(),
      child: Row(
        children: <Widget>[
          for (int i = 0; i < children.length; i++) ...<Widget>[
            if (i > 0) SizedBox(width: spacing),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// The canvas' toast: inverted surface, floating just above the nav bar.
void showSensaToast(BuildContext context, String message) {
  final SensaColors c = context.colors;
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: c.bg,
        ),
      ),
      backgroundColor: c.text,
      behavior: SnackBarBehavior.floating,
      elevation: 6,
      duration: const Duration(milliseconds: 1800),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
  );
}

/// Two-or-more option switch rendered as an inset segmented control, used for
/// Lecturas/Terminal and Tarjetas/Tabla.
class SegmentedToggle extends StatelessWidget {
  const SegmentedToggle({
    Key? key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelect,
    this.height = 28,
    this.fontSize = 11,
  }) : super(key: key);

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final double height;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final SensaColors c = context.colors;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (int i = 0; i < labels.length; i++)
            Padding(
              padding: EdgeInsets.only(left: i == 0 ? 0 : 4),
              child: Material(
                color: i == selectedIndex ? c.accent : Colors.transparent,
                borderRadius: BorderRadius.circular(9),
                child: InkWell(
                  onTap: () => onSelect(i),
                  borderRadius: BorderRadius.circular(9),
                  child: Container(
                    height: height,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.center,
                    child: Text(
                      labels[i],
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w500,
                        color: i == selectedIndex ? c.accentInk : c.muted,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
