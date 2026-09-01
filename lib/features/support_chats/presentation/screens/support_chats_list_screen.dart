import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_palette.dart';
import '../../../../core/router/app_routes.dart';
import '../../../users/data/users_repository.dart';
import '../providers/support_chats_providers.dart';

// Provider to fetch a user stream for the chat list item
final chatUserProvider = FutureProvider.autoDispose.family<dynamic, String>((ref, userId) {
  return ref.watch(usersRepositoryProvider).getUser(userId);
});

class SupportChatsListScreen extends ConsumerWidget {
  const SupportChatsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.getThemeData(ThemePalette.goldenDark);
    final chatsAsync = ref.watch(supportChatsListProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Support Hub'),
      ),
      body: chatsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.white))),
        data: (chats) {
          if (chats.isEmpty) {
            return const Center(
              child: Text(
                'No active support chats.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              // The user ID is the one that is not 'admin'
              final userId = chat.participants.firstWhere((id) => id != 'admin', orElse: () => 'Unknown');
              
              return _ChatListItem(
                chatId: chat.id,
                userId: userId,
                lastMessage: chat.lastMessage,
                lastUpdated: chat.lastUpdated,
                unreadCount: chat.unreadCount['admin'] ?? 0,
              );
            },
          );
        },
      ),
    );
  }
}

class _ChatListItem extends ConsumerWidget {
  final String chatId;
  final String userId;
  final String lastMessage;
  final DateTime lastUpdated;
  final int unreadCount;

  const _ChatListItem({
    required this.chatId,
    required this.userId,
    required this.lastMessage,
    required this.lastUpdated,
    required this.unreadCount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(chatUserProvider(userId));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFF1E1E1E),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: ThemePalette.goldenDark.accentPrimary.withAlpha(50),
          child: userAsync.when(
            data: (user) {
              if (user != null && user.profilePicture != null) {
                return ClipOval(
                  child: Image.network(
                    user.profilePicture!,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                  ),
                );
              }
              return const Icon(Icons.person, color: Colors.white);
            },
            loading: () => const CircularProgressIndicator(strokeWidth: 2),
            error: (_, __) => const Icon(Icons.person, color: Colors.white),
          ),
        ),
        title: userAsync.when(
          data: (user) => Text(
            user?.displayName ?? 'Unknown User',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          loading: () => const Text('Loading...', style: TextStyle(color: Colors.grey)),
          error: (_, __) => const Text('Unknown User', style: TextStyle(color: Colors.white)),
        ),
        subtitle: Text(
          lastMessage.isEmpty ? 'No messages yet' : lastMessage,
          style: TextStyle(
            color: unreadCount > 0 ? Colors.white : Colors.grey,
            fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              DateFormat.jm().format(lastUpdated),
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
            if (unreadCount > 0) ...[
              const SizedBox(height: 4),
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
        onTap: () {
          context.push(AppRoutes.supportChatDetail.replaceAll(':id', chatId));
        },
      ),
    );
  }
}
