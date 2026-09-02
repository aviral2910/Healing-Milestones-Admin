import 'package:flutter/material.dart';
import '../../models/story_model.dart';

class AdminStoryListTile extends StatelessWidget {
  final StoryModel story;
  final VoidCallback onTap;

  const AdminStoryListTile({
    super.key,
    required this.story,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = story.mainImage.isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0C), // Ultra deep black
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.15), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          highlightColor: theme.colorScheme.primary.withValues(alpha: 0.05),
          splashColor: theme.colorScheme.primary.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cover Image
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2), width: 1),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: hasImage
                        ? Image.network(
                            story.mainImage,
                            fit: BoxFit.cover,
                            
                            errorBuilder: (_, __, ___) => _buildPlaceholder(theme),
                          )
                        : _buildPlaceholder(theme),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        story.heading,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        story.shortDescription.isNotEmpty ? story.shortDescription : 'No description provided.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      
                      // Metrics Row
                      Row(
                        children: [
                          Icon(Icons.favorite_rounded, size: 14, color: theme.colorScheme.primary.withValues(alpha: 0.8)),
                          const SizedBox(width: 4),
                          Text(
                            '${story.likesCount}',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.chat_bubble_rounded, size: 14, color: theme.colorScheme.primary.withValues(alpha: 0.8)),
                          const SizedBox(width: 4),
                          Text(
                            '${story.commentCount}',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          if (story.isVerifiedStory)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text('VERIFIED', style: TextStyle(color: theme.colorScheme.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                            )
                          else if (story.verificationStatus == 'pending')
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('PENDING', style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                            )
                        ],
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

  Widget _buildPlaceholder(ThemeData theme) {
    return Container(
      color: theme.colorScheme.primary.withValues(alpha: 0.05),
      child: Icon(Icons.article_rounded, color: theme.colorScheme.primary.withValues(alpha: 0.5), size: 32),
    );
  }
}
