import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_resume_app/models/food_resume.dart';
import 'package:food_resume_app/services/food_resume_filter.dart';
import 'package:food_resume_app/services/local_cache_service.dart';
import 'package:food_resume_app/widgets/resume_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Test double for decoding existing Firestore records without a live backend.
// ignore: subtype_of_sealed_class
class _Document implements DocumentSnapshot<Map<String, dynamic>> {
  _Document(this.values);
  final Map<String, dynamic> values;

  @override
  String get id => 'legacy';

  @override
  Map<String, dynamic> data() => values;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

FoodResume _menu(String category, {String? name}) => FoodResume(
      id: category,
      menuName: name ?? 'Menu $category',
      category: category,
      description: '',
      highlights: [],
      ownerId: 'owner',
      ownerName: 'Owner',
      likeCount: 0,
      likedBy: [],
      createdAt: DateTime(2026),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final menus = FoodCategory.values
      .map((category) => _menu(' \u200B${category.label}\uFEFF\n'))
      .toList();

  for (final category in FoodCategory.values) {
    test('${category.label}: filters existing documents and newly added menus',
        () {
      final legacy = FoodResume.fromDoc(_Document({
        'menuName': 'Legacy',
        'category': ' ${category.label} ',
        'categoryName': 'Ignored alternate field',
      }));
      final added = _menu(category.label, name: 'New menu');
      final result = filterFoodResumes(
        [...menus, legacy, added],
        category: '\n${category.label} ',
      );
      expect(result, hasLength(3));
      expect(result.every((r) => r.category == category.label), isTrue);
      expect(result, containsAll([legacy, added]));
      expect(added.toMap()['category'], category.label);
      expect(FoodCategory.fromLabel(' ${category.label} '), category);
    });
  }

  test('All includes every category and preserves feed order', () {
    final all = [...menus, _menu('Unknown legacy category')];
    for (final selection in [null, '', 'ทั้งหมด', ' ทั้งหมด ']) {
      expect(filterFoodResumes(all, category: selection), all);
    }
  });

  test('Switching filters reuses the full feed, including returning to All',
      () {
    for (final category in FoodCategory.values.reversed) {
      expect(filterFoodResumes(menus, category: category.label), hasLength(1));
    }
    expect(filterFoodResumes(menus, category: 'ทั้งหมด'), menus);
    expect(filterFoodResumes([menus.first], category: 'เบเกอรี่'), isEmpty);
  });

  test(
      'Bakery matches category rather than name; search combines with category',
      () {
    final bakery = _menu(' เบเกอรี่ ', name: 'Norwegian Krumkake');
    final otherBakery = _menu('เบเกอรี่', name: 'New bread');
    final drink = _menu('เครื่องดื่ม', name: 'Norwegian Krumkake');
    final feed = [bakery, otherBakery, drink];
    expect(
        filterFoodResumes(feed, category: 'เบเกอรี่'), [bakery, otherBakery]);
    expect(filterFoodResumes(feed, category: 'เบเกอรี่', search: ' KRUMKAKE '),
        [bakery]);
  });

  test('Cache roundtrip retains all categories and uses the same filter',
      () async {
    SharedPreferences.setMockInitialValues({});
    final cache = LocalCacheService();
    await cache.saveCache(menus);
    final restored = await cache.loadCache();
    for (final category in FoodCategory.values) {
      expect(
          filterFoodResumes(restored, category: category.label).single.category,
          category.label);
    }
    expect(filterFoodResumes(restored, category: 'ทั้งหมด'), hasLength(7));
  });

  test('Old cache normalizes category; missing category defaults to Other',
      () async {
    final data = _menu('เบเกอรี่').toMap();
    data['id'] = 'cached';
    data['createdAt'] = DateTime(2026).toIso8601String();
    data['category'] = ' \u200Bเบเกอรี่ ';
    SharedPreferences.setMockInitialValues({
      'cached_resumes': jsonEncode([
        data,
        {...data}..remove('category')
      ]),
    });
    final restored = await LocalCacheService().loadCache();
    expect(filterFoodResumes(restored, category: 'เบเกอรี่'), hasLength(1));
    expect(filterFoodResumes(restored, category: 'อื่นๆ'), hasLength(1));
  });

  testWidgets('Card category text is exactly the category used by the filter',
      (tester) async {
    final menu = FoodResume.fromDoc(_Document({
      'menuName': 'Norwegian Krumkake',
      'category': ' เบเกอรี่ ',
      'categoryName': 'เครื่องดื่ม',
    }));
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 200,
          child: ResumeCard(
            resume: menu,
            currentUid: 'viewer',
            isSaved: false,
            onTap: () {},
            onLike: () {},
            onSave: () {},
          ),
        ),
      ),
    ));
    expect(find.text('เบเกอรี่'), findsOneWidget);
    expect(filterFoodResumes([menu], category: 'เบเกอรี่'), [menu]);
    expect(filterFoodResumes([menu], category: 'เครื่องดื่ม'), isEmpty);
  });
}
