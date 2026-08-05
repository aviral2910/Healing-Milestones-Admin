import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/users_repository.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_palette.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';

final usersProvider = StreamProvider<List<UserModel>>((ref) {
  return ref.watch(usersRepositoryProvider).getUsers();
});

class UsersScreen extends ConsumerWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersProvider);
    final theme = AppTheme.getThemeData(ThemePalette.goldenDark);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('User Management'),
      ),
      body: usersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err', style: TextStyle(color: Colors.white))),
        data: (users) {
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return _UserListItem(user: user);
            },
          );
        },
      ),
    );
  }
}

class _UserListItem extends ConsumerWidget {
  final UserModel user;

  const _UserListItem({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFF0F0F0F), // Premium charcoal
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: ThemePalette.goldenDark.accentPrimary.withAlpha(50), width: 1.0),
      ),
      child: InkWell(
        onTap: () {
          context.push(AppRoutes.userDetail(user.userId, mode: 'manage'));
        },
        borderRadius: BorderRadius.circular(16),
        hoverColor: ThemePalette.goldenDark.accentPrimary.withAlpha(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: ListTile(
            leading: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: ThemePalette.goldenDark.accentPrimary.withAlpha(40),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 24,
                backgroundImage: user.profilePicture != null && user.profilePicture!.isNotEmpty
                    ? NetworkImage(user.profilePicture!)
                    : null,
                backgroundColor: const Color(0xFF1E1E1E),
                child: user.profilePicture == null || user.profilePicture!.isEmpty 
                    ? Icon(Icons.person, color: ThemePalette.goldenDark.accentPrimary) 
                    : null,
              ),
            ),
            title: Text(user.displayName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (user.username != null) 
                    Text('@${user.username}', style: const TextStyle(color: Colors.orangeAccent, fontSize: 12)),
                  Text(user.email, style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _buildBadge('Role: ${user.role.name}', ThemePalette.goldenDark.accentPrimary),
                      _buildBadge('Status: ${user.status}', user.status == 'active' ? Colors.green : Colors.redAccent),
                    ],
                  ),
                ],
              ),
            ),
            isThreeLine: true,
            trailing: Icon(Icons.arrow_forward_ios, color: ThemePalette.goldenDark.accentPrimary, size: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        border: Border.all(color: color.withAlpha(80)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
