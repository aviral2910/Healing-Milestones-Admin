import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:healing_milestones_admin/core/router/app_routes.dart';
import 'dashboard_screen.dart'; // To reuse the provider and _buildHubCard if needed

class ActionHubScreen extends ConsumerWidget {
  const ActionHubScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded, color: Colors.white),
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
        title: const Text(
          'Action Hub',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: statsAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: Colors.white)),
        error: (e, st) => Center(
          child: Text('Error: $e', style: const TextStyle(color: Colors.red)),
        ),
        data: (stats) {
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _buildHubCard(
                context,
                title: 'Verification Panel',
                subtitle:
                    '${stats['pendingProfiles']! + stats['pendingStories']!} pending requests for Users & Stories.',
                icon: Icons.verified_rounded,
                gradientColors: [
                  const Color(0xFF362B2B),
                  const Color(0xFF1E1818),
                ],
                iconColor: const Color(0xFFFF7A7A),
                onTap: () => context.push(AppRoutes.verification),
                badgeCount:
                    stats['pendingProfiles']! + stats['pendingStories']!,
              ),
              const SizedBox(height: 16),
              _buildHubCard(
                context,
                title: 'Content Moderation',
                subtitle:
                    '${stats['activeReports']} user-submitted reports for Stories & Journeys.',
                icon: Icons.gavel_rounded,
                gradientColors: [
                  const Color(0xFF36322B),
                  const Color(0xFF1E1C18),
                ],
                iconColor: const Color(0xFFFFD17A),
                onTap: () => context.push(AppRoutes.moderation),
                badgeCount: stats['activeReports'],
              ),
              const SizedBox(height: 16),
              _buildHubCard(
                context,
                title: 'Manage Users',
                subtitle:
                    'Ban, Unban, and manage ${stats['totalUsers']} total accounts.',
                icon: Icons.manage_accounts,
                gradientColors: [
                  const Color(0xFF2B2B36),
                  const Color(0xFF18181E),
                ],
                iconColor: const Color(0xFF7A7AFF),
                onTap: () => context.push(AppRoutes.users),
              ),
            ],
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
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          highlightColor: Colors.white.withValues(alpha: 0.05),
          splashColor: Colors.white.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: iconColor, size: 32),
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
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (badgeCount != null && badgeCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: iconColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: iconColor.withValues(alpha: 0.5),
                                ),
                              ),
                              child: Text(
                                badgeCount.toString(),
                                style: TextStyle(
                                  color: iconColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white.withValues(alpha: 0.3),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
