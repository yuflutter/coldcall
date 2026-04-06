import 'package:flutter/material.dart';

/// Замена стандартного и ужасного SnackBar
void showToastification(BuildContext context, String message) {
  // Получаем текущий Overlay
  final overlay = Overlay.of(context);
  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (context) => Positioned(
      // Учитываем челку (SafeArea) + небольшой отступ
      top: MediaQuery.of(context).padding.top + 20,
      right: 10,
      // Ограничиваем ширину, чтобы не вылезало за экран
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        // Material нужен, чтобы работали жесты и шрифты внутри Overlay
        child: Material(
          color: Colors.transparent,
          child: Dismissible(
            key: UniqueKey(),
            direction: DismissDirection.vertical,
            onDismissed: (_) => entry.remove(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.info_outline, color: Colors.yellow, size: 20),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(message, style: const TextStyle(color: Colors.yellow, fontSize: 14)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  overlay.insert(entry);

  // Авто-удаление, если пользователь не смахнул сам
  Future.delayed(const Duration(seconds: 3), () {
    if (entry.mounted) {
      entry.remove();
    }
  });
}
