import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:healing_milestones_admin/core/router/app_routes.dart';
import '../../data/dashboard_providers.dart';

class ActionHubScreen extends ConsumerWidget {
  const ActionHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(actionHubStatsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        actions: [
          IconButton(
            icon: Icon(Icons.settings_rounded, color: theme.colorScheme.onSurface),
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
        title: const Text(
          'Action Hub',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: statsAsync.when(
        loading: () => Center(child: CircularProgressIndicator(color: theme.colorScheme.primary)),
        error: (e, st) => Center(
          child: Text('Error: $e', style: const TextStyle(color: Colors.red)),
        ),
        data: (stats) {
          final queues = stats['queues'] ?? {};
          final totals = stats['totals'] ?? {};
          
          final pendingProfiles = queues['pending_profiles'] ?? 0;
          final pendingStories = queues['pending_stories'] ?? 0;
          final pendingReports = queues['pending_reports'] ?? 0;
          final pendingWeb = queues['pending_web'] ?? 0;
          
          final totalVerifications = pendingProfiles + pendingStories;
          
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            children: [
              _buildHubCard(
                context,
                title: 'Verification Panel',
                subtitle: '$totalVerifications pending requests for Users & Stories.',
                icon: Icons.verified_rounded,
                theme: theme,
                onTap: () => context.push(AppRoutes.verification),
                badgeCount: totalVerifications,
              ),
              const SizedBox(height: 20),
              
              _buildHubCard(
                context,
                title: 'Content Moderation',
                subtitle: '$pendingReports user-submitted reports for Stories & Journeys.',
                icon: Icons.gavel_rounded,
                theme: theme,
                onTap: () => context.push(AppRoutes.moderation),
                badgeCount: pendingReports,
              ),
              const SizedBox(height: 20),
              
              _buildHubCard(
                context,
                title: 'Web Submissions',
                subtitle: 'Review $pendingWeb submissions from the website.',
                icon: Icons.web_rounded,
                theme: theme,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Web Submissions Route Coming Soon')));
                },
                badgeCount: pendingWeb,
              ),
              const SizedBox(height: 20),
              
              _buildHubCard(
                context,
                title: 'Manage Users',
                subtitle: 'Ban, Unban, and manage ${totals['users'] ?? 0} total accounts.',
                icon: Icons.manage_accounts_rounded,
                theme: theme,
                onTap: () => context.push(AppRoutes.users),
              ),
              const SizedBox(height: 40),
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
    required ThemeData theme,
    required VoidCallback onTap,
    int? badgeCount,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0C),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.05),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            highlightColor: theme.colorScheme.primary.withValues(alpha: 0.05),
            splashColor: theme.colorScheme.primary.withValues(alpha: 0.1),
            child: Stack(
              children: [
                // Huge Watermark Icon bleeding off the right edge
                Positioned(
                  right: -20,
                  bottom: -20,
                  child: Icon(
                    icon,
                    size: 140,
                    color: theme.colorScheme.primary.withValues(alpha: 0.04),
                  ),
                ),
                
                // Content
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2), width: 1),
                            ),
                            child: Icon(icon, color: theme.colorScheme.primary, size: 26),
                          ),
                          if (badgeCount != null && badgeCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.colorScheme.primary.withValues(alpha: 0.4),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ]
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    badgeCount.toString(),
                                    style: TextStyle(
                                      color: theme.colorScheme.onPrimary,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(Icons.notifications_active_rounded, color: theme.colorScheme.onPrimary, size: 14),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 15,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
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
