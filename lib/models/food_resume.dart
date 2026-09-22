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

  static String normalize(String label) =>
      label.replaceAll(RegExp(r'[\u200B\uFEFF]'), '').trim();

  static FoodCategory fromLabel(String label) {
    return FoodCategory.values.firstWhere(
      (e) => e.label == normalize(label),
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
  final List<String>
      highlights; // จุดเด่นของเมนู เช่น "รสจัดจ้าน", "เผ็ดระดับ 5"
  final String ownerId;
  final String ownerName;
  final int likeCount;
  final List<String> likedBy; // uid ของคนที่กด like ไว้แล้ว (กันกดซ้ำ)
  final DateTime createdAt;

  FoodResume({
    required this.id,
    required this.menuName,
    required String category,
    required this.description,
    this.imageUrl = '',
    this.highlights = const [],
    required this.ownerId,
    required this.ownerName,
    required this.likeCount,
    required this.likedBy,
    required this.createdAt,
  }) : category = FoodCategory.normalize(category);

  factory FoodResume.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return FoodResume(
      id: doc.id,
      menuName: data['menuName'] ?? '',
      category: data['category'] ?? FoodCategory.other.label,
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      highlights: List<String>.from(data['highlights'] ?? []),
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
      if (highlights.isNotEmpty) 'highlights': highlights,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'likeCount': likeCount,
      'likedBy': likedBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  bool isLikedBy(String uid) => likedBy.contains(uid);
}
