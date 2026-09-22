import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_resume_app/models/food_resume.dart';

// Test-only snapshot for checking legacy Firestore data without a live backend.
// ignore: subtype_of_sealed_class
class _Document implements DocumentSnapshot<Map<String, dynamic>> {
  _Document(this.values);
  final Map<String, dynamic> values;

  @override
  String get id => 'menu';

  @override
  Map<String, dynamic> data() => values;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('New menu can be saved without highlights or an image', () {
    final menu = FoodResume(
      id: '',
      menuName: 'Soup',
      category: FoodCategory.thai.label,
      description: '',
      ownerId: 'owner',
      ownerName: '',
      likeCount: 0,
      likedBy: const [],
      createdAt: DateTime(2026),
    );
    expect(menu.highlights, isEmpty);
    expect(menu.toMap().containsKey('highlights'), isFalse);
    expect(menu.toMap()['imageUrl'], '');
    expect(menu.toMap()['createdAt'], isA<Timestamp>());
  });

  test('Legacy highlights remain readable and survive serialization', () {
    final menu = FoodResume.fromDoc(_Document({
      'highlights': ['Spicy', 'Homemade'],
      'description': 'Family recipe',
      'ownerName': 'Chef',
    }));
    expect(menu.highlights, ['Spicy', 'Homemade']);
    expect(menu.toMap()['highlights'], ['Spicy', 'Homemade']);
    expect(menu.description, 'Family recipe');
    expect(menu.ownerName, 'Chef');
  });

  test('Missing or null optional fields decode to safe values', () {
    for (final data in <Map<String, dynamic>>[
      {},
      {'highlights': null, 'description': null, 'ownerName': null},
    ]) {
      final menu = FoodResume.fromDoc(_Document(data));
      expect(menu.highlights, isEmpty);
      expect(menu.description, '');
      expect(menu.ownerName, 'ไม่ระบุชื่อ');
    }
  });
}
