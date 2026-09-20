import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/food_resume.dart';
import '../services/firestore_service.dart';
import '../theme/app_colors.dart';
import '../widgets/section_title.dart';

class DetailScreen extends StatefulWidget {
  final String resumeId;
  const DetailScreen({super.key, required this.resumeId});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late final FirestoreService _firestore;
  late final Stream<FoodResume?> _resumeStream;
  bool _deleting = false;
  bool _confirmingDelete = false;

  @override
  void initState() {
    super.initState();
    _firestore = FirestoreService();
    _resumeStream = _firestore.streamResume(widget.resumeId);
  }

  String _formatCategory(String category) => switch (category) {
    'อาหารไทย' => '🍜 อาหารไทย',
    'อาหารญี่ปุ่น' => '🍣 อาหารญี่ปุ่น',
    'ของหวาน' => '🍰 ของหวาน',
    'เครื่องดื่ม' => '🧋 เครื่องดื่ม',
    'เบเกอรี่' => '🥐 เบเกอรี่',
    'สตรีทฟู้ด' => '🍢 สตรีทฟู้ด',
    _ => '🍽️ $category',
  };

  Future<void> _confirmDelete(FoodResume resume) async {
    if (_deleting || _confirmingDelete ||
        FirebaseAuth.instance.currentUser == null) {
      return;
    }
    _confirmingDelete = true;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
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
              child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626), size: 24),
            ),
            const SizedBox(width: 12),
            const Text('ลบเมนู',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          ],
        ),
        content: const Text(
          'คุณต้องการลบเมนูนี้หรือไม่?',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    _confirmingDelete = false;
    if (confirmed != true || !mounted) return;
    setState(() => _deleting = true);
    try {
      await _firestore.deleteResume(resume.id);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).popUntil((route) => route.isFirst);
      messenger.showSnackBar(const SnackBar(
        content: Text('ลบเมนูเรียบร้อยแล้ว'),
        behavior: SnackBarBehavior.floating,
      ));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('ไม่สามารถลบเมนูได้ กรุณาลองใหม่'),
      ));
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_deleting) {
      return const PopScope(
        canPop: false,
        child: Scaffold(
          body: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 16),
              Text('กำลังลบเมนู...'),
            ]),
          ),
        ),
      );
    }
    return StreamBuilder<FoodResume?>(
      stream: _resumeStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(title: const Text('เกิดข้อผิดพลาด')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.primary),
                  const SizedBox(height: 16),
                  Text('ไม่สามารถโหลดข้อมูลสูตรอาหารได้',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text('${snapshot.error}', textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 20),
                  FilledButton(onPressed: () => Navigator.pop(context), child: const Text('กลับหน้าหลัก')),
                ]),
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting ||
            snapshot.connectionState == ConnectionState.none) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }

        final resume = snapshot.data;
        if (resume == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(title: const Text('ไม่พบเมนู')),
            body: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.search_off_rounded, size: 64, color: AppColors.textMuted),
                const SizedBox(height: 16),
                const Text('ไม่พบเมนูอาหารนี้ หรือเมนูอาจถูกลบไปแล้ว',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: 20),
                FilledButton(onPressed: () => Navigator.pop(context), child: const Text('กลับหน้าหลัก')),
              ]),
            ),
          );
        }

        final isLoggedIn = FirebaseAuth.instance.currentUser != null;

        return StreamBuilder<List<String>>(
          stream: _firestore.streamSavedIds(),
          builder: (context, savedSnap) {
            final isSaved = (savedSnap.data ?? []).contains(resume.id);
            final isLiked = resume.isLikedBy(_firestore.currentUid);

            return Scaffold(
              backgroundColor: AppColors.background,
              appBar: AppBar(
                title: Text(resume.menuName, overflow: TextOverflow.ellipsis),
                backgroundColor: AppColors.background,
                elevation: 0,
                scrolledUnderElevation: 0,
                actions: isLoggedIn
                    ? [
                        TextButton.icon(
                          style: TextButton.styleFrom(foregroundColor: const Color(0xFFDC2626)),
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('ลบ'),
                          onPressed: () => _confirmDelete(resume),
                        ),
                      ]
                    : null,
              ),
              body: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
                    children: [
                      if (resume.imageUrl.isNotEmpty) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.network(
                            resume.imageUrl,
                            height: 240,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const SizedBox(
                              height: 160,
                              child: Center(child: Icon(Icons.broken_image_outlined, size: 48)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (resume.description.isNotEmpty) ...[
                        Text(resume.description,
                            style: const TextStyle(color: AppColors.textSecondary, height: 1.5)),
                        const SizedBox(height: 16),
                      ],
                      if (resume.highlights.isNotEmpty) ...[
                        Wrap(
                          spacing: 8,
                          children: resume.highlights.map((text) => Chip(label: Text(text))).toList(),
                        ),
                        const SizedBox(height: 16),
                      ],
                      // Category + Meta
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.borderLight),
                          boxShadow: AppColors.softShadow,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(_formatCategory(resume.category),
                                  style: const TextStyle(
                                      fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primaryDark)),
                            ),
                            const Spacer(),
                            Text(
                              'แชร์เมื่อ ${DateFormat('d MMM y', 'th_TH').format(resume.createdAt)}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Stats Row
                      Row(
                        children: [
                          Expanded(child: _metricCard(Icons.favorite_rounded, AppColors.likeActive, '${resume.likeCount}', 'คนถูกใจ')),
                          const SizedBox(width: 10),
                          Expanded(child: _metricCard(Icons.soup_kitchen_rounded, AppColors.accentGreen, '${resume.ingredients.length}', 'วัตถุดิบ')),
                          const SizedBox(width: 10),
                          Expanded(child: _metricCard(Icons.format_list_numbered_rounded, AppColors.primary, '${resume.instructions.length}', 'ขั้นตอน')),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Ingredients
                      if (resume.ingredients.isNotEmpty) ...[
                        SectionTitle(title: 'วัตถุดิบที่ต้องใช้ 🥗', count: '${resume.ingredients.length} รายการ'),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.borderLight),
                            boxShadow: AppColors.softShadow,
                          ),
                          child: Column(
                            children: resume.ingredients.asMap().entries.map((e) {
                              final isLast = e.key == resume.ingredients.length - 1;
                              return Column(children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                                  child: Row(children: [
                                    Container(
                                      width: 24, height: 24,
                                      decoration: const BoxDecoration(color: AppColors.accentGreenLight, shape: BoxShape.circle),
                                      child: const Icon(Icons.check_rounded, size: 15, color: AppColors.accentGreen),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(child: Text(e.value,
                                        style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500, color: AppColors.textPrimary))),
                                  ]),
                                ),
                                if (!isLast) const Divider(height: 1, color: AppColors.borderLight),
                              ]);
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Instructions
                      if (resume.instructions.isNotEmpty) ...[
                        SectionTitle(title: 'ขั้นตอนการทำ 👨‍🍳', count: '${resume.instructions.length} ขั้นตอน'),
                        const SizedBox(height: 10),
                        ...resume.instructions.asMap().entries.map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: AppColors.borderLight),
                              boxShadow: AppColors.softShadow,
                            ),
                            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Container(
                                width: 32, height: 32,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 2))],
                                ),
                                child: Center(child: Text('${e.key + 1}',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14))),
                              ),
                              const SizedBox(width: 14),
                              Expanded(child: Text(e.value,
                                  style: const TextStyle(fontSize: 14.5, height: 1.55, color: AppColors.textPrimary))),
                            ]),
                          ),
                        )),
                      ],
                    ],
                  ),
                ),
              ),
              bottomNavigationBar: SafeArea(
                child: Center(
                  heightFactor: 1,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: const BoxDecoration(
                        color: AppColors.surface,
                        border: Border(top: BorderSide(color: AppColors.borderLight, width: 1)),
                        boxShadow: AppColors.floatingShadow,
                      ),
                      child: Row(children: [
                        Expanded(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: isLiked ? AppColors.likeActive : AppColors.likeActiveBg,
                              foregroundColor: isLiked ? Colors.white : AppColors.likeActive,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            icon: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                              child: Icon(isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                  key: ValueKey(isLiked), size: 20),
                            ),
                            label: Text(isLiked ? 'ถูกใจแล้ว (${resume.likeCount})' : 'ถูกใจ (${resume.likeCount})',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                            onPressed: () => _firestore.toggleLike(widget.resumeId),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: isSaved ? AppColors.saveActiveBg : Colors.transparent,
                              foregroundColor: isSaved ? AppColors.saveActive : AppColors.textPrimary,
                              side: BorderSide(color: isSaved ? AppColors.saveActive : AppColors.border, width: 1.2),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            icon: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                              child: Icon(isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                                  key: ValueKey(isSaved), size: 20),
                            ),
                            label: Text(isSaved ? 'บันทึกแล้ว' : 'บันทึกเมนู',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14,
                                    color: isSaved ? AppColors.saveActive : AppColors.textPrimary)),
                            onPressed: () => _firestore.toggleSave(widget.resumeId),
                          ),
                        ),
                      ]),
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

  Widget _metricCard(IconData icon, Color color, String value, String label) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.borderLight),
      boxShadow: AppColors.softShadow,
    ),
    child: Column(children: [
      Icon(icon, color: color, size: 22),
      const SizedBox(height: 6),
      Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textMuted)),
    ]),
  );
}
