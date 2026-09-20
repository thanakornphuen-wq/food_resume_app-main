import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../models/food_resume.dart';
import '../services/firestore_service.dart';
import '../theme/app_colors.dart';
import '../widgets/empty_state.dart';
import '../widgets/resume_card.dart';
import '../widgets/section_title.dart';
import 'detail_screen.dart';

/// หน้าโปรไฟล์ผู้ใช้ — แสดงข้อมูลโปรไฟล์และเรซูเม่อาหารที่บันทึกไว้ (Bookmarks)
/// ออกแบบให้สวยงาม อบอุ่น มีสถิติการบันทึก และรองรับ Responsive Max-width
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _firestore = FirestoreService();
  late final _savedIdsStream = _firestore.streamSavedIds();
  late final _resumesStream = _firestore.streamResumes();

  String _formatUid(String uid) {
    if (uid.length <= 10) return uid;
    return '${uid.substring(0, 6)}...${uid.substring(uid.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('โปรไฟล์ของฉัน'),
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: StreamBuilder<List<String>>(
        stream: _savedIdsStream,
        builder: (context, savedSnap) {
          if (savedSnap.hasError) {
            return const Center(child: Text('โหลดเมนูที่บันทึกไว้ไม่สำเร็จ'));
          }
          if (!savedSnap.hasData && savedSnap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final savedIds = savedSnap.data ?? [];

          return StreamBuilder<List<FoodResume>>(
            stream: _resumesStream,
            builder: (context, snap) {
              if (snap.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          size: 48,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'โหลดเมนูที่บันทึกไว้ไม่สำเร็จ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${snap.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (!snap.hasData && snap.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }

              final byId = {for (final resume in snap.data ?? <FoodResume>[]) resume.id: resume};
              final saved = savedIds.map((id) => byId[id]).whereType<FoodResume>().toList();

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: CustomScrollView(
                    slivers: [
                      // Profile Header Card
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: AppColors.borderLight, width: 1),
                              boxShadow: AppColors.cardShadow,
                            ),
                            child: Row(
                              children: [
                                // Profile Avatar with warm accent border
                                Container(
                                  width: 68,
                                  height: 68,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.primary.withValues(alpha: 0.3),
                                      width: 2.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(alpha: 0.2),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.restaurant_rounded,
                                    color: AppColors.primary,
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(width: 16),

                                // Profile Info & UID
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Text(
                                            'นักชิม Foodie 🍽️',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.textPrimary,
                                              letterSpacing: -0.3,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.accentAmberLight,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Text(
                                              'Member',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFFB45309),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'UID: ${_formatUid(_firestore.currentUid)}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.surfaceContainer,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.bookmark_rounded,
                                              size: 14,
                                              color: AppColors.saveActive,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'บันทึกไว้แล้ว ${saved.length} รายการ',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                          ],
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

                      // Section Title
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: SectionTitle(
                            title: 'เมนูโปรดที่บันทึกไว้ 📌',
                            count: '${saved.length} เมนู',
                            subtitle: 'รวมเรซูเม่อาหารที่คุณกดบันทึกเก็บไว้ทำตาม',
                          ),
                        ),
                      ),

                      // Saved Grid or Empty State
                      if (saved.isEmpty)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: EmptyState(
                            icon: Icons.bookmark_border_rounded,
                            title: 'ยังไม่มีเมนูที่บันทึกไว้',
                            message:
                                'เมื่อคุณเจอเมนูหรือเรซูเม่ที่ถูกใจในหน้าแรก\nสามารถแตะไอคอนบุ๊กมาร์กเพื่อบันทึกเก็บไว้ดูที่นี่ได้ตลอดเวลา',
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                          sliver: SliverLayoutBuilder(
                            builder: (context, constraints) {
                              final columns = (constraints.crossAxisExtent ~/ 190).clamp(2, 5);

                              return SliverMasonryGrid.count(
                                crossAxisCount: columns,
                                mainAxisSpacing: 14,
                                crossAxisSpacing: 14,
                                childCount: saved.length,
                                itemBuilder: (context, i) {
                                  final r = saved[i];
                                  return ResumeCard(
                                    resume: r,
                                    currentUid: _firestore.currentUid,
                                    isSaved: true,
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => DetailScreen(resumeId: r.id),
                                      ),
                                    ),
                                    onLike: () => _firestore.toggleLike(r.id),
                                    onSave: () => _firestore.toggleSave(r.id),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
