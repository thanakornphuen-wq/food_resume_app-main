import 'package:flutter/material.dart';
import '../models/food_resume.dart';
import '../theme/app_colors.dart';

/// การ์ดเรซูเม่อาหารระดับพรีเมียม สไตล์ Pinterest / Modern Food Social
/// จัดวางสัดส่วนสวยงาม มี Category Pill ลอยบนภาพ, Hero transition,
/// จุดเด่นของเมนู, ข้อมูลเชฟผู้สร้าง และปุ่ม Like / Save ที่กดแล้วตอบสนองอย่างเป็นธรรมชาติ
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

  String _formatCategory(String category) {
    return switch (category) {
      'อาหารไทย' => '🍜 อาหารไทย',
      'อาหารญี่ปุ่น' => '🍣 อาหารญี่ปุ่น',
      'ของหวาน' => '🍰 ของหวาน',
      'เครื่องดื่ม' => '🧋 เครื่องดื่ม',
      'เบเกอรี่' => '🥐 เบเกอรี่',
      'สตรีทฟู้ด' => '🍢 สตรีทฟู้ด',
      _ => '🍽️ $category',
    };
  }

  @override
  Widget build(BuildContext context) {
    final liked = resume.isLikedBy(currentUid);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight, width: 1),
        boxShadow: AppColors.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: AppColors.primaryLight.withValues(alpha: 0.4),
          highlightColor: AppColors.primaryLight.withValues(alpha: 0.2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Cover Image with Hero transition and Floating Category Badge
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 1.15,
                    child: Hero(
                      tag: 'food_img_${resume.id}',
                      child: resume.imageUrl.isNotEmpty
                          ? Image.network(
                              resume.imageUrl,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return _loadingPlaceholder();
                              },
                              errorBuilder: (_, __, ___) => _errorPlaceholder(),
                            )
                          : _errorPlaceholder(),
                    ),
                  ),

                  // Category badge overlay
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x14000000),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        _formatCategory(resume.category),
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Card Content
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Food Menu Name
                    Text(
                      resume.menuName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),

                    const SizedBox(height: 4),

                    // First highlight pill or short description
                    if (resume.highlights.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accentAmberLight.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.local_fire_department,
                                size: 12,
                                color: AppColors.accentAmber,
                              ),
                              const SizedBox(width: 2),
                              Flexible(
                                child: Text(
                                  resume.highlights.first,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFB45309),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (resume.description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          resume.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11.5,
                          ),
                        ),
                      ),

                    // Chef / Creator row
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 8,
                          backgroundColor: AppColors.surfaceContainer,
                          child: Text(
                            resume.ownerName.isNotEmpty
                                ? resume.ownerName[0].toUpperCase()
                                : 'C',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            resume.ownerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),
                    const Divider(height: 1, color: AppColors.borderLight),
                    const SizedBox(height: 2),

                    // Social Action Row: Like and Save
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Like Button with Count
                        InkWell(
                          onTap: onLike,
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                            child: Row(
                              children: [
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  transitionBuilder: (child, anim) =>
                                      ScaleTransition(scale: anim, child: child),
                                  child: Icon(
                                    liked ? Icons.favorite : Icons.favorite_border_rounded,
                                    key: ValueKey(liked),
                                    size: 18,
                                    color: liked ? AppColors.likeActive : AppColors.textMuted,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${resume.likeCount}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: liked ? FontWeight.w700 : FontWeight.w500,
                                    color: liked ? AppColors.likeActive : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Bookmark Button
                        InkWell(
                          onTap: onSave,
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              transitionBuilder: (child, anim) =>
                                  ScaleTransition(scale: anim, child: child),
                              child: Icon(
                                isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                                key: ValueKey(isSaved),
                                size: 19,
                                color: isSaved ? AppColors.saveActive : AppColors.textMuted,
                              ),
                            ),
                          ),
                        ),
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

  Widget _loadingPlaceholder() => Container(
        color: AppColors.surfaceContainer,
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
        ),
      );

  Widget _errorPlaceholder() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFF2EC), Color(0xFFFDE8DE)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.restaurant_rounded,
            size: 40,
            color: Color(0xFFFFB09C),
          ),
        ),
      );
}
