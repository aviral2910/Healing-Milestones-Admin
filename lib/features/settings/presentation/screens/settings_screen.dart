import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_palette.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/presentation/widgets/admin_confirmation_dialog.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.getThemeData(ThemePalette.goldenDark);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Manage Admin Access
          Card(
            elevation: 4,
            color: const Color(0xFF0F0F0F),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: ThemePalette.goldenDark.accentPrimary.withAlpha(50), width: 1.0),
            ),
            child: InkWell(
              onTap: () {
                context.push(AppRoutes.manageAdmins);
              },
              borderRadius: BorderRadius.circular(16),
              hoverColor: ThemePalette.goldenDark.accentPrimary.withAlpha(20),
              child: ListTile(
                leading: Icon(Icons.admin_panel_settings, color: ThemePalette.goldenDark.accentPrimary),
                title: const Text('Manage Admin Access', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: const Text('Approve or reject admin requests', style: TextStyle(color: Colors.grey)),
                trailing: Icon(Icons.arrow_forward_ios, color: ThemePalette.goldenDark.accentPrimary, size: 16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Logout
          Card(
            elevation: 4,
            color: const Color(0xFF0F0F0F),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.redAccent.withAlpha(50), width: 1.0),
            ),
            child: InkWell(
              onTap: () async {
                final confirm = await showAdminConfirmationDialog(
                  context: context,
                  title: 'Logout',
                  content: 'Are you sure you want to logout from the admin panel?',
                  confirmText: 'Logout',
                  isDestructive: true,
                );
                if (confirm != true) return;

                FirebaseAuth.instance.signOut();
                // Optionally pop to login if needed, or handle in auth wrapper
              },
              borderRadius: BorderRadius.circular(16),
              hoverColor: Colors.redAccent.withAlpha(20),
              child: const ListTile(
                leading: Icon(Icons.logout, color: Colors.redAccent),
                title: Text('Logout', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
