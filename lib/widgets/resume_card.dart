import 'package:flutter/material.dart';
import '../models/food_resume.dart';

/// การ์ดแสดงเรซูเม่อาหารหนึ่งใบ ใช้ในหน้า Home (Staggered Grid)
class ResumeCard extends StatelessWidget {
  final FoodResume resume;
  final String currentUid;
  final bool isSaved;
  final VoidCallback onTap;
  final VoidCallback onLike;
  final VoidCallback onSave;

  const ResumeCard({
    super.key,
    required this.resume,
    required this.currentUid,
    required this.isSaved,
    required this.onTap,
    required this.onLike,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final liked = resume.isLikedBy(currentUid);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: resume.imageUrl.isNotEmpty
                  ? Image.network(
                      resume.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholderImage(),
                    )
                  : _placeholderImage(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
              child: Text(
                resume.menuName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                resume.category,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          transitionBuilder: (child, anim) =>
                              ScaleTransition(scale: anim, child: child),
                          child: Icon(
                            liked ? Icons.favorite : Icons.favorite_border,
                            key: ValueKey(liked),
                            color: liked ? Colors.redAccent : Colors.grey,
                          ),
                        ),
                        onPressed: onLike,
                      ),
                      Text('${resume.likeCount}'),
                    ],
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      isSaved ? Icons.bookmark : Icons.bookmark_border,
                      color: isSaved ? Theme.of(context).colorScheme.primary : Colors.grey,
                    ),
                    onPressed: onSave,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderImage() => Container(
        color: Colors.orange[50],
        child: const Center(
          child: Icon(Icons.restaurant, size: 48, color: Colors.orangeAccent),
        ),
      );
}
