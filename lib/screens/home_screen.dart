import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../models/food_resume.dart';
import '../services/firestore_service.dart';
import '../services/local_cache_service.dart';
import '../theme/app_colors.dart';
import '../widgets/empty_state.dart';
import '../widgets/resume_card.dart';
import '../widgets/section_title.dart';
import 'add_menu_screen.dart';
import 'detail_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _firestore = FirestoreService();
  final _cache = LocalCacheService();
  final _searchCtrl = TextEditingController();

  String _selectedCategory = 'ทั้งหมด';
  String _search = '';
  Timer? _debounce;
  List<FoodResume> _cachedFallback = [];
  int _navIndex = 0;

  static const _categories = [
    (key: 'ทั้งหมด', label: 'ทั้งหมด', emoji: '🍽️'),
    (key: 'อาหารไทย', label: 'อาหารไทย', emoji: '🍜'),
    (key: 'อาหารญี่ปุ่น', label: 'อาหารญี่ปุ่น', emoji: '🍣'),
    (key: 'ของหวาน', label: 'ของหวาน', emoji: '🍰'),
    (key: 'เครื่องดื่ม', label: 'เครื่องดื่ม', emoji: '🧋'),
    (key: 'เบเกอรี่', label: 'เบเกอรี่', emoji: '🥐'),
    (key: 'สตรีทฟู้ด', label: 'สตรีทฟู้ด', emoji: '🍢'),
    (key: 'อื่นๆ', label: 'อื่นๆ', emoji: '✨'),
  ];

  @override
  void initState() {
    super.initState();
    _cache.loadCache().then((v) { if (mounted) setState(() => _cachedFallback = v); });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _search = v);
    });
  }

  List<FoodResume> _filteredFallback() {
    var list = List<FoodResume>.from(_cachedFallback);
    if (_selectedCategory != 'ทั้งหมด') list = list.where((r) => r.category == _selectedCategory).toList();
    final q = _search.trim().toLowerCase();
    if (q.isNotEmpty) list = list.where((r) => r.menuName.toLowerCase().contains(q)).toList();
    list.sort((a, b) => b.likeCount.compareTo(a.likeCount));
    return list;
  }

  void _goAdd() => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddMenuScreen()));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _navIndex == 0 ? AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 16,
        title: Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 3))],
            ),
            child: const Icon(Icons.restaurant_menu_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Food Resume', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.3)),
            Text('รวมสูตรเด็ดและเรซูเม่อาหาร',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSecondary.withValues(alpha: 0.8))),
          ]),
        ]),
        actions: [
          IconButton(
            tooltip: 'เพิ่มเมนูใหม่',
            icon: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.add_rounded, color: AppColors.primary, size: 20),
            ),
            onPressed: _goAdd,
          ),
          const SizedBox(width: 10),
        ],
      ) : null,
      body: [_buildHomeBody(), const ProfileScreen()][_navIndex],
      floatingActionButton: _navIndex == 0
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 4,
              icon: const Icon(Icons.add_rounded),
              label: const Text('สร้างเรซูเม่', style: TextStyle(fontWeight: FontWeight.w700)),
              onPressed: _goAdd,
            )
          : null,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.borderLight, width: 1))),
        child: NavigationBar(
          selectedIndex: _navIndex,
          onDestinationSelected: (i) => setState(() => _navIndex = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore_rounded), label: 'ค้นพบ'),
            NavigationDestination(icon: Icon(Icons.bookmark_border_rounded), selectedIcon: Icon(Icons.bookmark_rounded), label: 'บันทึกไว้'),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderLight),
              boxShadow: AppColors.softShadow,
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              style: const TextStyle(fontSize: 14.5, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'ค้นหาชื่อเมนู เช่น ต้มยำกุ้ง, ราเมง...',
                hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 22),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 18),
                        onPressed: () { _searchCtrl.clear(); setState(() => _search = ''); },
                      )
                    : null,
                filled: true,
                fillColor: Colors.transparent,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
        ),

        // Category Chips
        SizedBox(
          height: 44,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final cat = _categories[i];
              final selected = cat.key == _selectedCategory;
              return InkWell(
                onTap: () => setState(() => _selectedCategory = cat.key),
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: selected ? AppColors.primary : AppColors.borderLight),
                    boxShadow: selected
                        ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))]
                        : AppColors.softShadow,
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(cat.emoji, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(cat.label, style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? Colors.white : AppColors.textPrimary,
                    )),
                  ]),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 10),

        // Grid Stream
        Expanded(
          child: StreamBuilder<List<FoodResume>>(
            stream: _firestore.streamResumes(category: _selectedCategory, search: _search),
            builder: (context, snapshot) {
              if (snapshot.hasData && _selectedCategory == 'ทั้งหมด' && _search.trim().isEmpty) {
                _cachedFallback = snapshot.data!;
                _cache.saveCache(snapshot.data!);
              }

              final resumes = snapshot.data ??
                  (snapshot.connectionState == ConnectionState.waiting ? _filteredFallback() : []);

              if (resumes.isEmpty) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }
                return EmptyState(
                  icon: _search.isNotEmpty ? Icons.search_off_rounded : Icons.ramen_dining_outlined,
                  title: _search.isNotEmpty ? 'ไม่พบเมนูที่ค้นหา' : 'ยังไม่มีเมนูในหมวดนี้',
                  message: _search.isNotEmpty
                      ? 'ลองตรวจสอบตัวสะกด หรือค้นหาด้วยชื่อเมนูอื่นๆ ดูนะ'
                      : 'มาร่วมแชร์ความอร่อย และเป็นคนแรกที่สร้างเรซูเม่ในหมวดนี้กันเถอะ!',
                  actionLabel: (_search.isNotEmpty || _selectedCategory != 'ทั้งหมด') ? 'ดูเมนูทั้งหมด' : null,
                  onAction: () => setState(() { _selectedCategory = 'ทั้งหมด'; _searchCtrl.clear(); _search = ''; }),
                );
              }

              return StreamBuilder<List<String>>(
                stream: _firestore.streamSavedIds(),
                builder: (context, savedSnap) {
                  final savedIds = savedSnap.data ?? [];
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = (constraints.maxWidth ~/ 180).clamp(2, 5);
                      return CustomScrollView(slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: SectionTitle(
                              title: _selectedCategory == 'ทั้งหมด' ? 'เมนูยอดนิยม 🔥' : 'เมนู$_selectedCategory',
                              count: '${resumes.length} รายการ',
                              subtitle: _search.isNotEmpty ? 'ผลการค้นหา "$_search"' : 'เรียงตามยอดถูกใจจากชุมชนอาหาร',
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                          sliver: SliverMasonryGrid.count(
                            crossAxisCount: columns,
                            mainAxisSpacing: 14,
                            crossAxisSpacing: 14,
                            childCount: resumes.length,
                            itemBuilder: (context, i) {
                              final r = resumes[i];
                              return ResumeCard(
                                resume: r,
                                currentUid: _firestore.currentUid,
                                isSaved: savedIds.contains(r.id),
                                onTap: () => Navigator.push(context,
                                    MaterialPageRoute(builder: (_) => DetailScreen(resumeId: r.id))),
                                onLike: () => _firestore.toggleLike(r.id),
                                onSave: () => _firestore.toggleSave(r.id),
                              );
                            },
                          ),
                        ),
                      ]);
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
