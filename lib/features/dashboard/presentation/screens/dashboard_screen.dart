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

  final totalUsersCount = await usersRepo.getTotalUsersCount();
  final pendingProfiles = (await usersRepo.getUsers()).where((u) => u.appliedForVerification && !u.isVerified).length;
  
  final storiesResult = await storiesRepo.getPendingStories();
  final reportsResult = await moderationRepo.getPendingReports();
  
  final chatsResult = await supportChatsRepo.getSupportChatsStream().first;
  int unreadSupportChats = 0;
  for (var chat in chatsResult) {
    if ((chat.unreadCount['admin'] ?? 0) > 0) unreadSupportChats++;
  }
  
  return {
    'totalUsers': totalUsersCount,
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
      backgroundColor: Colors.black, // True pitch black for premium feel
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.redAccent))),
        data: (stats) {
          return RefreshIndicator(
            color: Colors.white,
            backgroundColor: const Color(0xFF1C1C1E),
            onRefresh: () async => ref.refresh(dashboardStatsProvider),
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 180,
                  floating: false,
                  pinned: true,
                  backgroundColor: Colors.black,
                  elevation: 0,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.settings, color: Colors.white),
                      onPressed: () => context.push(AppRoutes.settings),
                    ),
                    const SizedBox(width: 16),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    titlePadding: const EdgeInsets.only(left: 24, bottom: 20),
                    title: const Text(
                      'Command Center',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            theme.colorScheme.primary.withAlpha(40),
                            Colors.black,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildHubCard(
                        context,
                        title: 'User Management',
                        subtitle: 'Manage all ${stats['totalUsers']} registered accounts, roles, and profiles.',
                        icon: Icons.people_alt_rounded,
                        gradientColors: [const Color(0xFF2B2B36), const Color(0xFF18181E)],
                        iconColor: const Color(0xFF7A7AFF),
                        onTap: () => context.push(AppRoutes.users),
                      ),
                      const SizedBox(height: 20),
                      _buildHubCard(
                        context,
                        title: 'Verification Queue',
                        subtitle: '${stats['pendingProfiles']! + stats['pendingStories']!} pending requests requiring your approval.',
                        icon: Icons.verified_rounded,
                        gradientColors: [const Color(0xFF362B2B), const Color(0xFF1E1818)],
                        iconColor: const Color(0xFFFF7A7A),
                        onTap: () => context.push(AppRoutes.verification),
                        badgeCount: stats['pendingProfiles']! + stats['pendingStories']!,
                      ),
                      const SizedBox(height: 20),
                      _buildHubCard(
                        context,
                        title: 'Support Inbox',
                        subtitle: '${stats['activeSupportChats']} active conversations with users.',
                        icon: Icons.chat_bubble_rounded,
                        gradientColors: [const Color(0xFF2B3631), const Color(0xFF181E1B)],
                        iconColor: const Color(0xFF7AFFB0),
                        onTap: () => context.push(AppRoutes.supportChats),
                        badgeCount: stats['unreadSupportChats'],
                      ),
                      const SizedBox(height: 20),
                      _buildHubCard(
                        context,
                        title: 'Content Moderation',
                        subtitle: '${stats['activeReports']} user-submitted reports pending review.',
                        icon: Icons.gavel_rounded,
                        gradientColors: [const Color(0xFF36322B), const Color(0xFF1E1C18)],
                        iconColor: const Color(0xFFFFC07A),
                        onTap: () => context.push(AppRoutes.moderation),
                        badgeCount: stats['activeReports'],
                      ),
                      const SizedBox(height: 48), // Bottom padding
                    ]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHubCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
    required Color iconColor,
    required VoidCallback onTap,
    int? badgeCount,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withAlpha(20),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          highlightColor: Colors.white.withAlpha(5),
          splashColor: Colors.white.withAlpha(10),
          child: Ink(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withAlpha(10),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Glowing Icon Container
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: iconColor.withAlpha(20),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: iconColor.withAlpha(30),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(icon, size: 32, color: iconColor),
                ),
                const SizedBox(width: 24),
                // Text Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                          if (badgeCount != null && badgeCount > 0) ...[
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: iconColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$badgeCount',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ]
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withAlpha(150),
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                // Arrow
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white,
                    size: 16,
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
