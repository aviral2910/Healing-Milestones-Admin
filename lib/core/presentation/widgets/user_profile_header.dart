import 'package:flutter/material.dart';
import '../../models/user_model.dart';

class UserProfileHeader extends StatelessWidget {
  final UserModel user;

  const UserProfileHeader({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasAvatar = user.profilePicture != null && user.profilePicture!.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32.0),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F), // True premium charcoal
        border: Border(bottom: BorderSide(color: theme.colorScheme.primary.withAlpha(50), width: 1.5)),
      ),
      child: Column(
        children: [
          // Avatar
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: user.isVerified 
                      ? theme.colorScheme.primary.withAlpha(80) 
                      : Colors.transparent,
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
              border: Border.all(
                color: user.isVerified ? theme.colorScheme.primary : Colors.grey[800]!,
                width: 3,
              ),
            ),
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey[900],
              backgroundImage: hasAvatar ? NetworkImage(user.profilePicture!) : null,
              child: hasAvatar
                  ? null
                  : Text(
                      user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 32, color: Colors.white),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          // Name and Verification Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                user.displayName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (user.isVerified) ...[
                const SizedBox(width: 8),
                Icon(Icons.verified, color: theme.colorScheme.primary, size: 24),
              ],
            ],
          ),
          if (user.username != null) ...[
            const SizedBox(height: 4),
            Text(
              '@${user.username}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.orangeAccent,
              ),
            ),
          ],
          const SizedBox(height: 4),
          // Email
          Text(
            user.email,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 16),
          // Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStat(context, 'Followers', user.followersCount.toString()),
              Container(height: 24, width: 1, color: theme.colorScheme.primary.withAlpha(50), margin: const EdgeInsets.symmetric(horizontal: 16)),
              _buildStat(context, 'Following', user.followingCount.toString()),
              Container(height: 24, width: 1, color: theme.colorScheme.primary.withAlpha(50), margin: const EdgeInsets.symmetric(horizontal: 16)),
              _buildStat(context, 'Stories', user.ownStories.length.toString()),
            ],
          ),
          const SizedBox(height: 24),
          // Bio
          if (user.bio != null && user.bio!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                user.bio!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStat(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[400],
          ),
        ),
      ],
    );
  }
}
