import 'package:flutter/material.dart';

// Если enabled == true, кнопка станет некликабельной, серой, и потеряет тень
class ActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final String? tooltip;
  final bool enabled;
  final bool showProgress;

  const ActionButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.tooltip,
    this.enabled = true,
    this.showProgress = false,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: enabled ? onPressed : null,
      tooltip: tooltip,
      backgroundColor: enabled ? null : Colors.grey.shade800,
      foregroundColor: enabled ? null : Colors.grey.shade600,
      elevation: enabled ? null : 0,
      disabledElevation: 0,
      child: Stack(alignment: .center, children: [child, if (!enabled && showProgress) CircularProgressIndicator()]),
    );
  }
}
