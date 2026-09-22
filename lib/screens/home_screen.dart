import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../models/food_resume.dart';
import '../services/firestore_service.dart';
import '../services/food_resume_filter.dart';
import '../services/local_cache_service.dart';
import '../widgets/resume_card.dart';
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
  final _searchController = TextEditingController();

  String _selectedCategory = 'ทั้งหมด';
  String _search = '';
  Timer? _debounce;
  List<FoodResume> _cachedFallback = [];
  late final Stream<List<FoodResume>> _resumesStream;
  bool _cacheLoaded = false;
  int _navIndex = 0;

  final _categories = [
    'ทั้งหมด',
    ...FoodCategory.values.map((e) => e.label),
  ];

  @override
  void initState() {
    super.initState();
    // Keep the complete feed subscribed while category/search changes locally.
    _resumesStream = _firestore.streamResumes().map((resumes) {
      unawaited(_cache.saveCache(resumes));
      return resumes;
    });
    _cache.loadCache().then((v) {
      if (!mounted) return;
      setState(() {
        _cachedFallback = v;
        _cacheLoaded = true;
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      setState(() => _search = value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildHomeBody(),
      const ProfileScreen(),
    ];
    // Keep a retained tab index valid after the navigation destinations change.
    final selectedIndex = _navIndex.clamp(0, pages.length - 1);

    return Scaffold(
      appBar:
          selectedIndex == 0 ? AppBar(title: const Text('Food Resume 🍽️')) : null,
      body: pages[selectedIndex],
      floatingActionButton: selectedIndex == 0
          ? FloatingActionButton.extended(
              icon: const Icon(Icons.add),
              label: const Text('เพิ่มเมนู'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddMenuScreen()),
              ),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (i) => setState(() => _navIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'หน้าแรก'),
          NavigationDestination(icon: Icon(Icons.person), label: 'โปรไฟล์'),
        ],
      ),
    );
  }

  Widget _buildHomeBody() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'ค้นหาชื่อเมนู...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final cat = _categories[i];
              final selected = cat == _selectedCategory;
              return ChoiceChip(
                label: Text(cat),
                selected: selected,
                onSelected: (_) => setState(() => _selectedCategory = cat),
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: StreamBuilder<List<FoodResume>>(
            stream: _resumesStream,
            builder: (context, snapshot) {
              if (!snapshot.hasData && _cachedFallback.isEmpty) {
                if (snapshot.hasError) {
                  return const Center(child: Text('โหลดเมนูไม่สำเร็จ'));
                }
                if (!_cacheLoaded ||
                    snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
              }

              final resumes = filterFoodResumes(
                snapshot.data ?? _cachedFallback,
                category: _selectedCategory,
                search: _search,
              );

              if (resumes.isEmpty) {
                return const Center(child: Text('ยังไม่มีเมนูในหมวดนี้'));
              }

              return StreamBuilder<List<String>>(
                stream: _firestore.streamSavedIds(),
                builder: (context, savedSnap) {
                  final savedIds = savedSnap.data ?? [];

                  // Responsive: จำนวนคอลัมน์ปรับตามความกว้างหน้าจอ
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = (constraints.maxWidth ~/ 180).clamp(2, 5);
                      return MasonryGridView.count(
                        padding: const EdgeInsets.all(12),
                        crossAxisCount: columns,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        itemCount: resumes.length,
                        itemBuilder: (context, i) {
                          final r = resumes[i];
                          return ResumeCard(
                            resume: r,
                            currentUid: _firestore.currentUid,
                            isSaved: savedIds.contains(r.id),
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
