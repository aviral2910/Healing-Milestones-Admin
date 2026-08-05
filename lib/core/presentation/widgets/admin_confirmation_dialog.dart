import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_palette.dart';

Future<bool?> showAdminConfirmationDialog({
  required BuildContext context,
  required String title,
  required String content,
  String confirmText = 'Confirm',
  String cancelText = 'Cancel',
  bool isDestructive = false,
}) {
  return showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      final theme = AppTheme.getThemeData(ThemePalette.goldenDark);
      final accentColor = isDestructive ? Colors.redAccent : theme.colorScheme.primary;

      return AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E), // Premium charcoal dialog
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: accentColor.withAlpha(50), width: 1.5),
        ),
        title: Row(
          children: [
            Icon(isDestructive ? Icons.warning_amber_rounded : Icons.info_outline, color: accentColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          content,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText, style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDestructive ? Colors.redAccent : theme.colorScheme.primary,
              foregroundColor: isDestructive ? Colors.white : Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmText, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      );
    },
  );
}
