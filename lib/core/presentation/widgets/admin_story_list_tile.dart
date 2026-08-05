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

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFF0F0F0F), // Premium charcoal
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.primary.withAlpha(50), width: 1.0),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        hoverColor: theme.colorScheme.primary.withAlpha(20),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover Image or Placeholder
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: hasImage
                    ? Image.network(
                        story.mainImage,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholder(),
                      )
                    : _buildPlaceholder(),
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
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      story.shortDescription,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[400],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.thumb_up, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          '${story.likesCount}',
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.comment, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          '${story.commentCount}',
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        ),
                        const Spacer(),
                        if (story.isVerifiedStory)
                          Icon(Icons.verified, size: 16, color: theme.colorScheme.primary)
                        else if (story.verificationStatus == 'pending')
                          const Icon(Icons.pending, size: 16, color: Colors.orange)
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 80,
      height: 80,
      color: Colors.grey[800],
      child: const Icon(Icons.article, color: Colors.grey, size: 32),
    );
  }
}
