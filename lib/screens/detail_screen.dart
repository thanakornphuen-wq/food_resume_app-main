import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/food_resume.dart';
import '../services/firestore_service.dart';
import '../theme/app_colors.dart';
import '../widgets/section_title.dart';

/// หน้ารายละเอียดเรซูเม่อาหาร (Detail Screen) สไตล์ Gourmet Modern
/// จัดการสัดส่วน Hero image, ข้อมูลเชฟผู้สร้าง, สถิติ, วัตถุดิบ, วิธีทำแบบ Step-by-Step
/// พร้อมระบบ Like/Save แบบเรียลไทม์ และระบบลบเมนูพร้อมกล่องยืนยัน (Confirmation Dialog)
class DetailScreen extends StatefulWidget {
  final String resumeId;
  const DetailScreen({super.key, required this.resumeId});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  // FirestoreService is created once and held stable — avoids race condition
  // caused by re-creating a new stream on every build() when StatelessWidget.
  late final FirestoreService _firestore;

  @override
  void initState() {
    super.initState();
    _firestore = FirestoreService();
  }

  // ─── helpers (moved to State, previously on StatelessWidget) ───

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

  Future<void> _confirmDelete(
    BuildContext context,
    FirestoreService firestore,
    FoodResume resume,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: AppColors.surface,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: Color(0xFFDC2626),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'ยืนยันการลบเมนู',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          'คุณต้องการลบเรซูเม่เมนู "${resume.menuName}" นี้ใช่หรือไม่?\nการกระทำนี้จะไม่สามารถกู้คืนได้',
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text('ลบเมนู'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await firestore.deleteResume(resume.id);
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ลบเรซูเม่เมนู "${resume.menuName}" เรียบร้อยแล้ว'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<FoodResume?>(
      stream: _firestore.streamResume(widget.resumeId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(title: const Text('เกิดข้อผิดพลาด')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: AppColors.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.error_outline_rounded,
                        size: 48,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'ไม่สามารถโหลดข้อมูลสูตรอาหารได้',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('กลับหน้าหลัก'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting ||
            snapshot.connectionState == ConnectionState.none) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        final resume = snapshot.data;
        if (resume == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(title: const Text('ไม่พบเมนู')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.search_off_rounded, size: 64, color: AppColors.textMuted),
                    const SizedBox(height: 16),
                    const Text(
                      'ไม่พบเมนูอาหารนี้ หรือเมนูอาจถูกลบไปแล้ว',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('กลับหน้าหลัก'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final isOwner = resume.ownerId == _firestore.currentUid;

        return StreamBuilder<List<String>>(
          stream: _firestore.streamSavedIds(),
          builder: (context, savedSnap) {
            final savedIds = savedSnap.data ?? [];
            final isSaved = savedIds.contains(resume.id);
            final isLiked = resume.isLikedBy(_firestore.currentUid);

            return Scaffold(
              backgroundColor: AppColors.background,
              body: CustomScrollView(
                slivers: [
                  // Modern Hero SliverAppBar with Scrim & Rounded Lower Corners
                  SliverAppBar(
                    expandedHeight: 320,
                    pinned: true,
                    backgroundColor: AppColors.background,
                    elevation: 0,
                    leading: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x1A000000),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            color: AppColors.textPrimary,
                            size: 20,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                    actions: isOwner
                        ? [
                            Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  shape: BoxShape.circle,
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x1A000000),
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: Color(0xFFDC2626),
                                    size: 20,
                                  ),
                                  tooltip: 'ลบเมนูนี้',
                                  onPressed: () => _confirmDelete(context, _firestore, resume),
                                ),
                              ),
                            ),
                          ]
                        : null,
                    flexibleSpace: FlexibleSpaceBar(
                      background: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(28),
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Food Hero Image
                            Hero(
                              tag: 'food_img_${resume.id}',
                              child: resume.imageUrl.isNotEmpty
                                  ? Image.network(
                                      resume.imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => _imagePlaceholder(),
                                    )
                                  : _imagePlaceholder(),
                            ),

                            // Top Scrim Overlay (ensures back & delete buttons are always clear)
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              height: 110,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.black.withValues(alpha: 0.55),
                                      Colors.transparent,
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                              ),
                            ),

                            // Bottom Scrim Overlay with floating Category Pill
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              height: 90,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.65),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Align(
                                    alignment: Alignment.bottomLeft,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.95),
                                        borderRadius: BorderRadius.circular(14),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Color(0x24000000),
                                            blurRadius: 10,
                                            offset: Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        _formatCategory(resume.category),
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Recipe Content Body (Centered max-width constraint for wide tablet/web)
                  SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 720),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Food Title
                              Text(
                                resume.menuName,
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.5,
                                  height: 1.25,
                                ),
                              ),

                              const SizedBox(height: 14),

                              // Chef / Creator Profile Card
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: AppColors.borderLight, width: 1),
                                  boxShadow: AppColors.softShadow,
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 22,
                                      backgroundColor: AppColors.primaryLight,
                                      child: Text(
                                        resume.ownerName.isNotEmpty
                                            ? resume.ownerName[0].toUpperCase()
                                            : 'C',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.primaryDark,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  resume.ownerName,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 15,
                                                    color: AppColors.textPrimary,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (isOwner) ...[
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.primaryLight,
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: const Text(
                                                    'คุณ',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w700,
                                                      color: AppColors.primaryDark,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'แชร์เมื่อ ${DateFormat('d MMMM y', 'th_TH').format(resume.createdAt)}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Quick Stats Metric Bar (Likes, Ingredients count, Steps count)
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildMetricCard(
                                      icon: Icons.favorite_rounded,
                                      iconColor: AppColors.likeActive,
                                      value: '${resume.likeCount}',
                                      label: 'คนถูกใจ',
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _buildMetricCard(
                                      icon: Icons.soup_kitchen_rounded,
                                      iconColor: AppColors.accentGreen,
                                      value: '${resume.ingredients.length}',
                                      label: 'วัตถุดิบ',
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _buildMetricCard(
                                      icon: Icons.format_list_numbered_rounded,
                                      iconColor: AppColors.primary,
                                      value: '${resume.instructions.length}',
                                      label: 'ขั้นตอน',
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),

                              // Description / Story Section
                              if (resume.description.isNotEmpty) ...[
                                const SectionTitle(title: 'เรื่องราวของเมนูนี้ 📖'),
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(color: AppColors.borderLight, width: 1),
                                    boxShadow: AppColors.softShadow,
                                  ),
                                  child: Text(
                                    resume.description,
                                    style: const TextStyle(
                                      fontSize: 14.5,
                                      height: 1.6,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],

                              // Highlights Section
                              if (resume.highlights.isNotEmpty) ...[
                                const SectionTitle(title: 'จุดเด่นของเมนู 🌟'),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: resume.highlights.map((h) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.accentAmberLight.withValues(alpha: 0.7),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppColors.accentAmber.withValues(alpha: 0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.local_fire_department_rounded,
                                            size: 16,
                                            color: AppColors.accentAmber,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            h,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF92400E),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 24),
                              ],

                              // Ingredients Section
                              if (resume.ingredients.isNotEmpty) ...[
                                SectionTitle(
                                  title: 'วัตถุดิบที่ต้องใช้ 🥗',
                                  count: '${resume.ingredients.length} รายการ',
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: AppColors.borderLight, width: 1),
                                    boxShadow: AppColors.softShadow,
                                  ),
                                  child: Column(
                                    children: resume.ingredients.asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final item = entry.value;
                                      final isLast = index == resume.ingredients.length - 1;

                                      return Column(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 13,
                                            ),
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              children: [
                                                Container(
                                                  width: 24,
                                                  height: 24,
                                                  decoration: const BoxDecoration(
                                                    color: AppColors.accentGreenLight,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    Icons.check_rounded,
                                                    size: 15,
                                                    color: AppColors.accentGreen,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Text(
                                                    item,
                                                    style: const TextStyle(
                                                      fontSize: 14.5,
                                                      fontWeight: FontWeight.w500,
                                                      color: AppColors.textPrimary,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (!isLast)
                                            const Divider(
                                              height: 1,
                                              color: AppColors.borderLight,
                                            ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],

                              // Cooking Instructions Section (Step-by-step numbered cards)
                              if (resume.instructions.isNotEmpty) ...[
                                SectionTitle(
                                  title: 'ขั้นตอนการทำ 👨‍🍳',
                                  count: '${resume.instructions.length} ขั้นตอน',
                                ),
                                const SizedBox(height: 10),
                                ...resume.instructions.asMap().entries.map((entry) {
                                  final stepIndex = entry.key + 1;
                                  final instruction = entry.value;

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: AppColors.surface,
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(color: AppColors.borderLight, width: 1),
                                        boxShadow: AppColors.softShadow,
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              color: AppColors.primary,
                                              borderRadius: BorderRadius.circular(10),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: AppColors.primary.withValues(alpha: 0.3),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Center(
                                              child: Text(
                                                '$stepIndex',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Text(
                                              instruction,
                                              style: const TextStyle(
                                                fontSize: 14.5,
                                                height: 1.55,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Bottom Action Bar (Fixed at bottom with responsive width constraint)
              bottomNavigationBar: SafeArea(
                child: Center(
                  heightFactor: 1,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: const BoxDecoration(
                        color: AppColors.surface,
                        border: Border(
                          top: BorderSide(color: AppColors.borderLight, width: 1),
                        ),
                        boxShadow: AppColors.floatingShadow,
                      ),
                      child: Row(
                        children: [
                          // Like Button
                          Expanded(
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor:
                                    isLiked ? AppColors.likeActive : AppColors.likeActiveBg,
                                foregroundColor: isLiked ? Colors.white : AppColors.likeActive,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              icon: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                transitionBuilder: (child, anim) =>
                                    ScaleTransition(scale: anim, child: child),
                                child: Icon(
                                  isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                  key: ValueKey(isLiked),
                                  size: 20,
                                ),
                              ),
                              label: Text(
                                isLiked ? 'ถูกใจแล้ว (${resume.likeCount})' : 'ถูกใจ (${resume.likeCount})',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              onPressed: () => _firestore.toggleLike(widget.resumeId),
                            ),
                          ),

                          const SizedBox(width: 12),

                          // Save / Bookmark Button
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                backgroundColor: isSaved
                                    ? AppColors.saveActiveBg
                                    : Colors.transparent,
                                foregroundColor:
                                    isSaved ? AppColors.saveActive : AppColors.textPrimary,
                                side: BorderSide(
                                  color: isSaved ? AppColors.saveActive : AppColors.border,
                                  width: 1.2,
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              icon: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                transitionBuilder: (child, anim) =>
                                    ScaleTransition(scale: anim, child: child),
                                child: Icon(
                                  isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                                  key: ValueKey(isSaved),
                                  size: 20,
                                ),
                              ),
                              label: Text(
                                isSaved ? 'บันทึกแล้ว' : 'บันทึกเมนู',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: isSaved ? AppColors.saveActive : AppColors.textPrimary,
                                ),
                              ),
                              onPressed: () => _firestore.toggleSave(widget.resumeId),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight, width: 1),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() => Container(
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
            size: 64,
            color: Color(0xFFFFB09C),
          ),
        ),
      );
}
