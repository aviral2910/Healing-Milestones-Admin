import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'app_routes.dart';

import '../../features/auth/data/auth_providers.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/not_authorized_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/users/presentation/screens/users_screen.dart';
import '../../features/users/presentation/screens/user_detail_screen.dart';
import '../../features/stories/presentation/screens/story_detail_screen.dart';
import '../../features/verification/presentation/screens/verification_screen.dart';
import '../../features/moderation/presentation/screens/moderation_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/settings/presentation/screens/manage_admin_access_screen.dart';
import '../../features/support_chats/presentation/screens/support_chats_list_screen.dart';
import '../../features/support_chats/presentation/screens/support_chat_detail_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final adminClaim = ref.watch(adminClaimProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      if (authState.isLoading || adminClaim.isLoading) return null;

      final user = authState.value;
      final isAdmin = adminClaim.value ?? false;
      final isLoggingIn = state.matchedLocation == AppRoutes.login;
      final isNotAuthorized = state.matchedLocation == AppRoutes.notAuthorized;
      final isSplash = state.matchedLocation == AppRoutes.splash;

      if (user == null) {
        return isLoggingIn || isSplash ? null : AppRoutes.login;
      }

      if (!isAdmin) {
        return isNotAuthorized || isSplash ? null : AppRoutes.notAuthorized;
      }

      if (isLoggingIn || isNotAuthorized) {
        return AppRoutes.dashboard;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.notAuthorized,
        builder: (context, state) => const NotAuthorizedScreen(),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.users,
        builder: (context, state) => const UsersScreen(),
      ),
      GoRoute(
        path: AppRoutes.verification,
        builder: (context, state) => const VerificationScreen(),
      ),
      GoRoute(
        path: AppRoutes.moderation,
        builder: (context, state) => const ModerationScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.manageAdmins,
        builder: (context, state) => const ManageAdminAccessScreen(),
      ),
      GoRoute(
        path: '/user/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final mode = state.uri.queryParameters['mode'] ?? 'manage';
          return UserDetailScreen(userId: id, mode: mode);
        },
      ),
      GoRoute(
        path: '/story/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final mode = state.uri.queryParameters['mode'] ?? 'manage';
          return StoryDetailScreen(storyId: id, mode: mode);
        },
      ),
      GoRoute(
        path: AppRoutes.supportChats,
        builder: (context, state) => const SupportChatsListScreen(),
      ),
      GoRoute(
        path: '/support-chat/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return SupportChatDetailScreen(chatId: id);
        },
      ),
    ],
  );
});
