import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_palette.dart';
import '../../../../core/router/app_routes.dart';
import '../../../users/data/users_repository.dart';
import '../../../stories/data/stories_repository.dart';
import '../../../moderation/data/moderation_repository.dart';
import '../../../support_chats/data/support_chats_repository.dart';

final dashboardStatsProvider = StreamProvider.autoDispose<Map<String, int>>((ref) async* {
  final usersStream = ref.watch(usersRepositoryProvider).getUsers();
  
  // Watch so the provider rebuilds
  ref.watch(storiesRepositoryProvider).getPendingStories();
  ref.watch(moderationRepositoryProvider).getPendingReports();

  await for (final users in usersStream) {
    final pendingProfiles = users.where((u) => u.appliedForVerification && !u.isVerified).length;
    
    final storiesResult = await ref.read(storiesRepositoryProvider).getPendingStories().first;
    final reportsResult = await ref.read(moderationRepositoryProvider).getPendingReports().first;
    final chatsResult = await ref.read(supportChatsRepositoryProvider).getSupportChatsStream().first;
    
    final unreadSupportChats = chatsResult.where((c) => (c.unreadCount['admin'] ?? 0) > 0).length;

    yield {
      'totalUsers': users.length,
      'pendingProfiles': pendingProfiles,
      'pendingStories': storiesResult.length,
      'activeReports': reportsResult.length,
      'activeSupportChats': chatsResult.length,
      'unreadSupportChats': unreadSupportChats,
    };
  }
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.getThemeData(ThemePalette.goldenDark);
    final statsAsync = ref.watch(dashboardStatsProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Healing Milestones Admin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.white))),
        data: (stats) {
          return RefreshIndicator(
            onRefresh: () async {
              // ignore: unused_result
              ref.refresh(dashboardStatsProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(24.0),
              children: [
                const Text(
                  'Dashboard',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Select a tool below to begin managing the platform.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[400],
                  ),
                ),
                const SizedBox(height: 32),
                
                // Users Hub
                _DashboardCard(
                  title: 'Manage Users',
                  subtitle: '${stats['totalUsers']} Total Users',
                  icon: Icons.people,
                  color: ThemePalette.goldenDark.accentPrimary, // Golden
                  onTap: () => context.push(AppRoutes.users),
                ),
                const SizedBox(height: 16),
                
                // Verification Hub
                _DashboardCard(
                  title: 'Verification Hub',
                  subtitle: '${stats['pendingProfiles']} Profiles, ${stats['pendingStories']} Stories Pending',
                  icon: Icons.verified,
                  color: ThemePalette.goldenDark.accentPrimary, // Golden
                  isGlowing: true, // Make verification hub glow as primary action
                  onTap: () => context.push(AppRoutes.verification),
                ),
                const SizedBox(height: 16),
                
                // Support Hub
                _DashboardCard(
                  title: 'Support Hub',
                  subtitle: '${stats['activeSupportChats']} Active Chats',
                  icon: Icons.support_agent,
                  color: Colors.blueAccent,
                  hasUnread: (stats['unreadSupportChats'] ?? 0) > 0,
                  onTap: () => context.push(AppRoutes.supportChats),
                ),
                const SizedBox(height: 16),
                
                // Moderation Hub
                _DashboardCard(
                  title: 'Content Moderation',
                  subtitle: '${stats['activeReports']} Active Reports',
                  icon: Icons.gavel,
                  color: Colors.redAccent,
                  onTap: () => context.push(AppRoutes.moderation),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isGlowing;
  final bool hasUnread;

  const _DashboardCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.isGlowing = false,
    this.hasUnread = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: isGlowing
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: color.withAlpha(50),
                  blurRadius: 20,
                  spreadRadius: 2,
                )
              ],
            )
          : null,
      child: Card(
        elevation: isGlowing ? 0 : 12,
        color: const Color(0xFF0F0F0F), // Premium Deep Charcoal
        shadowColor: Colors.black.withAlpha(100),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: color.withAlpha(isGlowing ? 100 : 40), width: isGlowing ? 2.0 : 1.5),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          hoverColor: color.withAlpha(20),
          highlightColor: color.withAlpha(30),
          splashColor: color.withAlpha(40),
          child: Container(
            constraints: const BoxConstraints(minHeight: 140), // Fix RenderFlex Overflow
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withAlpha(20),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, size: 40, color: color),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 22,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              subtitle,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (hasUnread) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: Colors.grey[600]),
              ],
            ),
            ),
          ),
        ),
      ),
    );
  }
}
