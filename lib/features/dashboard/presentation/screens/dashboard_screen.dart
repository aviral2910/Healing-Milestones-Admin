import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_palette.dart';
import '../../../users/data/users_repository.dart';
import '../../../stories/data/stories_repository.dart';
import '../../../moderation/data/moderation_repository.dart';
import '../../../support_chats/data/support_chats_repository.dart';

final dashboardStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final usersRepo = ref.watch(usersRepositoryProvider);
  final storiesRepo = ref.watch(storiesRepositoryProvider);
  final moderationRepo = ref.watch(moderationRepositoryProvider);
  final supportChatsRepo = ref.watch(supportChatsRepositoryProvider);

  final users = await usersRepo.getUsers(role: 'all');
  
  // Pending User Verifications
  final pendingProfiles = users.where((u) => u.appliedForVerification && !u.isVerified).length;
  
  // Pending Story Verifications
  final storiesResult = await storiesRepo.getPendingStories();
  
  // Active Reports
  final reportsResult = await moderationRepo.getPendingReports();
  
  // Active Support Chats
  final chatsResult = await supportChatsRepo.getActiveChats();
  int unreadSupportChats = 0;
  for (var chat in chatsResult) {
    if (chat.adminUnreadCount > 0) unreadSupportChats++;
  }
  
  return {
    'totalUsers': users.length,
    'pendingProfiles': pendingProfiles,
    'pendingStories': storiesResult.length,
    'activeReports': reportsResult.length,
    'activeSupportChats': chatsResult.length,
    'unreadSupportChats': unreadSupportChats,
  };
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.getThemeData(ThemePalette.goldenDark);
    final statsAsync = ref.watch(dashboardStatsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A), // Premium black background
      appBar: AppBar(
        title: const Text('Healing Milestones Admin', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => context.push(AppRoutes.settings),
          ),
          const SizedBox(width: 8),
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth > 800;
                
                return ListView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 48.0 : 24.0, 
                    vertical: 32.0
                  ),
                  children: [
                    // Header Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Overview',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Platform metrics and active tasks',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 48),
                    
                    // Quick Stats Section (Grid)
                    const Text(
                      'AT A GLANCE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    if (isDesktop)
                      Row(
                        children: [
                          Expanded(child: _StatCard(title: 'Total Users', value: '${stats['totalUsers']}', icon: Icons.people_outline, color: theme.colorScheme.primary)),
                          const SizedBox(width: 24),
                          Expanded(child: _StatCard(title: 'Pending Verifications', value: '${stats['pendingProfiles']! + stats['pendingStories']!}', icon: Icons.verified_outlined, color: Colors.orangeAccent)),
                          const SizedBox(width: 24),
                          Expanded(child: _StatCard(title: 'Active Reports', value: '${stats['activeReports']}', icon: Icons.gavel_outlined, color: Colors.redAccent)),
                          const SizedBox(width: 24),
                          Expanded(child: _StatCard(title: 'Active Chats', value: '${stats['activeSupportChats']}', icon: Icons.support_agent_outlined, color: Colors.blueAccent)),
                        ],
                      )
                    else
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.5,
                        children: [
                          _StatCard(title: 'Total Users', value: '${stats['totalUsers']}', icon: Icons.people_outline, color: theme.colorScheme.primary),
                          _StatCard(title: 'Verifications', value: '${stats['pendingProfiles']! + stats['pendingStories']!}', icon: Icons.verified_outlined, color: Colors.orangeAccent),
                          _StatCard(title: 'Reports', value: '${stats['activeReports']}', icon: Icons.gavel_outlined, color: Colors.redAccent),
                          _StatCard(title: 'Active Chats', value: '${stats['activeSupportChats']}', icon: Icons.support_agent_outlined, color: Colors.blueAccent),
                        ],
                      ),

                    const SizedBox(height: 48),
                    
                    const Text(
                      'MANAGEMENT HUBS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Main Management Hubs
                    if (isDesktop)
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 24,
                        mainAxisSpacing: 24,
                        childAspectRatio: 3.0,
                        children: [
                          _ActionCard(
                            title: 'User Management',
                            subtitle: 'View and manage all platform users.',
                            icon: Icons.manage_accounts_outlined,
                            onTap: () => context.push(AppRoutes.users),
                          ),
                          _ActionCard(
                            title: 'Verification Hub',
                            subtitle: '${stats['pendingProfiles']} Profiles, ${stats['pendingStories']} Stories Pending',
                            icon: Icons.verified_user_outlined,
                            onTap: () => context.push(AppRoutes.verification),
                            highlight: (stats['pendingProfiles']! + stats['pendingStories']!) > 0,
                          ),
                          _ActionCard(
                            title: 'Support Hub',
                            subtitle: '${stats['activeSupportChats']} Active Chats',
                            icon: Icons.headset_mic_outlined,
                            onTap: () => context.push(AppRoutes.supportChats),
                            badgeCount: stats['unreadSupportChats'],
                          ),
                          _ActionCard(
                            title: 'Content Moderation',
                            subtitle: '${stats['activeReports']} Active Reports',
                            icon: Icons.gavel_outlined,
                            onTap: () => context.push(AppRoutes.moderation),
                            highlightColor: Colors.redAccent,
                            highlight: stats['activeReports']! > 0,
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          _ActionCard(
                            title: 'User Management',
                            subtitle: 'View and manage all platform users.',
                            icon: Icons.manage_accounts_outlined,
                            onTap: () => context.push(AppRoutes.users),
                          ),
                          const SizedBox(height: 16),
                          _ActionCard(
                            title: 'Verification Hub',
                            subtitle: '${stats['pendingProfiles']} Profiles, ${stats['pendingStories']} Stories Pending',
                            icon: Icons.verified_user_outlined,
                            onTap: () => context.push(AppRoutes.verification),
                            highlight: (stats['pendingProfiles']! + stats['pendingStories']!) > 0,
                          ),
                          const SizedBox(height: 16),
                          _ActionCard(
                            title: 'Support Hub',
                            subtitle: '${stats['activeSupportChats']} Active Chats',
                            icon: Icons.headset_mic_outlined,
                            onTap: () => context.push(AppRoutes.supportChats),
                            badgeCount: stats['unreadSupportChats'],
                          ),
                          const SizedBox(height: 16),
                          _ActionCard(
                            title: 'Content Moderation',
                            subtitle: '${stats['activeReports']} Active Reports',
                            icon: Icons.gavel_outlined,
                            onTap: () => context.push(AppRoutes.moderation),
                            highlightColor: Colors.redAccent,
                            highlight: stats['activeReports']! > 0,
                          ),
                        ],
                      ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF141414), // Solid dark
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[850]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: -1,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool highlight;
  final Color? highlightColor;
  final int? badgeCount;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.highlight = false,
    this.highlightColor,
    this.badgeCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = highlightColor ?? theme.colorScheme.primary;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        hoverColor: Colors.white.withAlpha(5),
        splashColor: Colors.white.withAlpha(10),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF141414), // Solid dark
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: highlight ? accent.withAlpha(150) : Colors.grey[850]!,
              width: highlight ? 1.5 : 1.0,
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: highlight ? accent.withAlpha(20) : Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: highlight ? accent : Colors.grey[300],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              if (badgeCount != null && badgeCount! > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$badgeCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else
                Icon(Icons.chevron_right, color: Colors.grey[600]),
            ],
          ),
        ),
      ),
    );
  }
}
