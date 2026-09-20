import 'package:cloud_firestore/cloud_firestore.dart';

/// หมวดหมู่เมนูอาหาร ใช้สำหรับระบบกรอง (Filter)
enum FoodCategory {
  thai('อาหารไทย'),
  japanese('อาหารญี่ปุ่น'),
  dessert('ของหวาน'),
  drink('เครื่องดื่ม'),
  bakery('เบเกอรี่'),
  streetFood('สตรีทฟู้ด'),
  other('อื่นๆ');

  final String label;
  const FoodCategory(this.label);

  static FoodCategory fromLabel(String label) {
    return FoodCategory.values.firstWhere(
      (e) => e.label == label,
      orElse: () => FoodCategory.other,
    );
  }
}

/// โมเดลข้อมูล "เรซูเม่อาหาร" หนึ่งใบ
/// เก็บเหมือนเรซูเม่ของเมนู: ชื่อ, รูป, จุดเด่น, วัตถุดิบ, ระดับความเผ็ด ฯลฯ
class FoodResume {
  final String id;
  final String menuName;
  final String category;
  final String description;
  final String imageUrl;
  final List<String> highlights; // จุดเด่นของเมนู เช่น "รสจัดจ้าน", "เผ็ดระดับ 5"
  final List<String> ingredients;
  final List<String> instructions;
  final String ownerId;
  final String ownerName;
  final int likeCount;
  final List<String> likedBy; // uid ของคนที่กด like ไว้แล้ว (กันกดซ้ำ)
  final DateTime createdAt;

  FoodResume({
    required this.id,
    required this.menuName,
    required this.category,
    this.description = '',
    this.imageUrl = '',
    this.highlights = const [],
    this.ingredients = const [],
    this.instructions = const [],
    required this.ownerId,
    this.ownerName = 'ไม่ระบุชื่อ',
    required this.likeCount,
    required this.likedBy,
    required this.createdAt,
  });

  factory FoodResume.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return FoodResume(
      id: doc.id,
      menuName: data['menuName'] ?? '',
      category: data['category'] ?? FoodCategory.other.label,
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      highlights: List<String>.from(data['highlights'] ?? []),
      ingredients: List<String>.from(data['ingredients'] ?? []),
      instructions: List<String>.from(data['instructions'] ?? []),
      ownerId: data['ownerId'] ?? '',
      ownerName: data['ownerName'] ?? 'ไม่ระบุชื่อ',
      likeCount: data['likeCount'] ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'menuName': menuName,
      'category': category,
      'description': description,
      'imageUrl': imageUrl,
      'highlights': highlights,
      'ingredients': ingredients,
      'instructions': instructions,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'likeCount': likeCount,
      'likedBy': likedBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  bool isLikedBy(String uid) => likedBy.contains(uid);

  /// New votes override legacy likedBy without migrating existing menus.
  FoodResume withLikes(Map<String, bool> votes) {
    final users = likedBy.toSet();
    for (final vote in votes.entries) {
      if (vote.value) {
        users.add(vote.key);
      } else {
        users.remove(vote.key);
      }
    }
    return FoodResume(
      id: id,
      menuName: menuName,
      category: category,
      description: description,
      imageUrl: imageUrl,
      highlights: highlights,
      ingredients: ingredients,
      instructions: instructions,
      ownerId: ownerId,
      ownerName: ownerName,
      likeCount: (likeCount + users.length - likedBy.toSet().length).clamp(0, 1 << 30),
      likedBy: users.toList(),
      createdAt: createdAt,
    );
  }
}
