import 'package:flutter/material.dart';
import '../models/food_resume.dart';
import '../theme/app_colors.dart';

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

  String _formatCategory(String c) => switch (c) {
    'อาหารไทย' => '🍜 อาหารไทย',
    'อาหารญี่ปุ่น' => '🍣 อาหารญี่ปุ่น',
    'ของหวาน' => '🍰 ของหวาน',
    'เครื่องดื่ม' => '🧋 เครื่องดื่ม',
    'เบเกอรี่' => '🥐 เบเกอรี่',
    'สตรีทฟู้ด' => '🍢 สตรีทฟู้ด',
    _ => '🍽️ $c',
  };

  @override
  Widget build(BuildContext context) {
    final liked = resume.isLikedBy(currentUid);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppColors.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: AppColors.primaryLight.withValues(alpha: 0.4),
          highlightColor: AppColors.primaryLight.withValues(alpha: 0.2),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _formatCategory(resume.category),
                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.primaryDark),
                  ),
                ),
                const SizedBox(height: 8),

                // Menu Name fixed 2 lines
                SizedBox(
                  height: 40,
                  child: Text(
                    resume.menuName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5,
                        color: AppColors.textPrimary, letterSpacing: -0.2, height: 1.35),
                  ),
                ),
                const SizedBox(height: 6),

                // Stats
                Row(children: [
                  const Icon(Icons.soup_kitchen_rounded, size: 13, color: AppColors.textMuted),
                  const SizedBox(width: 3),
                  Text('${resume.ingredients.length} วัตถุดิบ',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  const SizedBox(width: 10),
                  const Icon(Icons.format_list_numbered_rounded, size: 13, color: AppColors.textMuted),
                  const SizedBox(width: 3),
                  Text('${resume.instructions.length} ขั้นตอน',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ]),
                const SizedBox(height: 8),
                const Divider(height: 1, color: AppColors.borderLight),
                const SizedBox(height: 6),

                // Like + Save
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: onLike,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        child: Row(children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                            child: Icon(liked ? Icons.favorite : Icons.favorite_border_rounded,
                                key: ValueKey(liked), size: 18,
                                color: liked ? AppColors.likeActive : AppColors.textMuted),
                          ),
                          const SizedBox(width: 4),
                          Text('${resume.likeCount}', style: TextStyle(
                            fontSize: 12,
                            fontWeight: liked ? FontWeight.w700 : FontWeight.w500,
                            color: liked ? AppColors.likeActive : AppColors.textSecondary,
                          )),
                        ]),
                      ),
                    ),
                    InkWell(
                      onTap: onSave,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                          child: Icon(
                            isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                            key: ValueKey(isSaved), size: 19,
                            color: isSaved ? AppColors.saveActive : AppColors.textMuted),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}