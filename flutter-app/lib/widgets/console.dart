import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// One line of probe traffic, rendered as a chat bubble: sent commands are
/// accent-filled and right aligned, replies sit on the raised surface.
class ConsoleBubble extends StatelessWidget {
  const ConsoleBubble({
    Key? key,
    required this.message,
    required this.isSentByMe,
  }) : super(key: key);

  final String message;
  final bool isSentByMe;

  @override
  Widget build(BuildContext context) {
    final SensaColors c = context.colors;

    return Align(
      alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
      child: FractionallySizedBox(
        alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
        widthFactor: 0.76,
        child: Align(
          alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
            decoration: BoxDecoration(
              color: isSentByMe ? c.accent : c.surface2,
              borderRadius: BorderRadius.circular(13),
            ),
            child: SelectableText(
              message,
              style: monoStyle(
                fontSize: 11.5,
                height: 1.45,
                color: isSentByMe ? c.accentInk : c.text,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Scrollable transcript of the session.
class ConsoleLog extends StatelessWidget {
  const ConsoleLog({
    Key? key,
    required this.messages,
    required this.controller,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    this.shrinkWrap = false,
    this.emptyLabel,
  }) : super(key: key);

  final List<Map<String, dynamic>> messages;
  final ScrollController controller;
  final EdgeInsetsGeometry padding;
  final bool shrinkWrap;
  final String? emptyLabel;

  @override
  Widget build(BuildContext context) {
    final SensaColors c = context.colors;

    if (messages.isEmpty && emptyLabel != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            emptyLabel!,
            style: TextStyle(fontSize: 12, color: c.muted),
          ),
        ),
      );
    }

    return ListView.separated(
      controller: controller,
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      itemCount: messages.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (BuildContext context, int index) {
        final Map<String, dynamic> message = messages[index];
        return ConsoleBubble(
          message: (message['message'] ?? '').toString(),
          isSentByMe: message['isSentByMe'] == true,
        );
      },
    );
  }
}

/// The "Comando manual…" field with its accent send button.
class ConsoleInput extends StatelessWidget {
  const ConsoleInput({
    Key? key,
    required this.controller,
    required this.hintText,
    required this.onSend,
    this.enabled = true,
    this.height = 48,
    this.radius = 16,
  }) : super(key: key);

  final TextEditingController controller;
  final String hintText;
  final VoidCallback onSend;
  final bool enabled;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final SensaColors c = context.colors;

    return Row(
      children: <Widget>[
        Expanded(
          child: Container(
            height: height,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: c.border),
            ),
            alignment: Alignment.center,
            child: TextField(
              controller: controller,
              enabled: enabled,
              onSubmitted: (_) => onSend(),
              textInputAction: TextInputAction.send,
              style: monoStyle(fontSize: 13, color: c.text),
              cursorColor: c.accent,
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: hintText,
                hintStyle: monoStyle(
                  fontSize: 13,
                  color: c.muted,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Material(
          color: enabled ? c.accent : c.border,
          borderRadius: BorderRadius.circular(radius),
          child: InkWell(
            onTap: enabled ? onSend : null,
            borderRadius: BorderRadius.circular(radius),
            child: SizedBox(
              width: height,
              height: height,
              child: Icon(
                Icons.send,
                size: 20,
                color: enabled ? c.accentInk : c.muted,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
