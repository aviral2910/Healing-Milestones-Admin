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

final dashboardStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
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
    // REAL DATA
    'totalUsers': totalUsersCount,
    'pendingProfiles': pendingProfiles,
    'pendingStories': storiesResult.length,
    'activeReports': reportsResult.length,
    'activeSupportChats': chatsResult.length,
    'unreadSupportChats': unreadSupportChats,
    
    // MOCK DATA FOR UI PREVIEW (To be connected to Redis later)
    'dau': 1245,
    'mau': 14890,
    'totalStories': 8432,
    'totalMilestones': 42100,
    'reactionsToday': 850,
    'trendingStories': [
      {'title': 'Finding light after 10 years of addiction...', 'author': 'Sarah J.', 'reactions': 342},
      {'title': 'My first steps without crutches!', 'author': 'Mike T.', 'reactions': 289},
    ]
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
                  expandedHeight: 120,
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
                    titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
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
                            theme.colorScheme.primary.withAlpha(30),
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
                      
                      // --- PLATFORM ANALYTICS SECTION ---
                      const Text(
                        'Platform Growth',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.5,
                        children: [
                          _buildStatCard('Active Users Today', '${stats['dau']}', Icons.local_fire_department, Colors.orangeAccent),
                          _buildStatCard('Total Users', '${stats['totalUsers']}', Icons.people, Colors.blueAccent),
                          _buildStatCard('Stories Published', '${stats['totalStories']}', Icons.auto_stories, Colors.purpleAccent),
                          _buildStatCard('Milestones Reached', '${stats['totalMilestones']}', Icons.flag, Colors.greenAccent),
                        ],
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // --- ACTION HUBS SECTION ---
                      const Text(
                        'Action Hubs',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      _buildHubCard(
                        context,
                        title: 'Verification Queue',
                        subtitle: '${stats['pendingProfiles']! + stats['pendingStories']!} pending requests requiring approval.',
                        icon: Icons.verified_rounded,
                        gradientColors: [const Color(0xFF362B2B), const Color(0xFF1E1818)],
                        iconColor: const Color(0xFFFF7A7A),
                        onTap: () => context.push(AppRoutes.verification),
                        badgeCount: stats['pendingProfiles']! + stats['pendingStories']!,
                      ),
                      const SizedBox(height: 16),
                      _buildHubCard(
                        context,
                        title: 'Support Inbox',
                        subtitle: '${stats['activeSupportChats']} active conversations with users.',
                        icon: Icons.chat_bubble_rounded,
                        gradientColors: [const Color(0xFF2B3631), const Color(0xFF1E1818)],
                        iconColor: const Color(0xFF7AFFB0),
                        onTap: () => context.push(AppRoutes.supportChats),
                        badgeCount: stats['unreadSupportChats'],
                      ),
                      const SizedBox(height: 16),
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
                      const SizedBox(height: 16),
                      _buildHubCard(
                        context,
                        title: 'User Directory',
                        subtitle: 'Manage all accounts, roles, and profiles.',
                        icon: Icons.manage_accounts,
                        gradientColors: [const Color(0xFF2B2B36), const Color(0xFF18181E)],
                        iconColor: const Color(0xFF7A7AFF),
                        onTap: () => context.push(AppRoutes.users),
                      ),

                      const SizedBox(height: 40),
                      
                      // --- COMMUNITY PULSE SECTION ---
                      const Text(
                        'Community Pulse',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      _buildPulseSection(stats),

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

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF121214),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(10), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 28),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withAlpha(120),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildPulseSection(Map<String, dynamic> stats) {
    final trending = stats['trendingStories'] as List;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF121214),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withAlpha(10), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.favorite, color: Colors.pinkAccent, size: 20),
              const SizedBox(width: 12),
              Text(
                '${stats['reactionsToday']} Hugs Given Today',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(color: Colors.white10, height: 1),
          ),
          const Text(
            '🔥 Trending Stories this Week',
            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...trending.map((story) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.local_fire_department, color: Colors.orangeAccent, size: 16),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        story['title'],
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'By ${story['author']} • ${story['reactions']} reactions',
                        style: TextStyle(color: Colors.white.withAlpha(120), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
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
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withAlpha(10),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          highlightColor: Colors.white.withAlpha(5),
          splashColor: Colors.white.withAlpha(10),
          child: Ink(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withAlpha(10), width: 1),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: iconColor.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 28, color: iconColor),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (badgeCount != null && badgeCount > 0) ...[
                            const SizedBox(width: 8),
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
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withAlpha(150),
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(Icons.arrow_forward_ios_rounded, color: Colors.white.withAlpha(50), size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
