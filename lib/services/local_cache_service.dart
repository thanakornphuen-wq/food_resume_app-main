import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/food_resume.dart';

/// เทคนิคใหม่ที่ไม่ได้สอนในห้องเรียน: การทำ Offline-first caching
/// เก็บรายการเรซูเม่อาหารล่าสุดไว้ในเครื่อง (SharedPreferences)
/// เพื่อให้เปิดแอปแล้วเห็นข้อมูลได้ทันทีแม้เน็ตช้า/หลุดชั่วคราว
/// แล้วค่อยอัปเดตเป็นข้อมูลสดจาก Firestore เมื่อเชื่อมต่อได้
class LocalCacheService {
  static const _key = 'cached_resumes';

  Future<void> saveCache(List<FoodResume> resumes) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = resumes
        .map((r) => {
              'id': r.id,
              'menuName': r.menuName,
              'category': r.category,
              'description': r.description,
              'imageUrl': r.imageUrl,
              'highlights': r.highlights,
              'ownerId': r.ownerId,
              'ownerName': r.ownerName,
              'likeCount': r.likeCount,
              'likedBy': r.likedBy,
              'createdAt': r.createdAt.toIso8601String(),
            })
        .toList();
    await prefs.setString(_key, jsonEncode(jsonList));
  }

  Future<List<FoodResume>> loadCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final List decoded = jsonDecode(raw);
    return decoded
        .map((m) => FoodResume(
              id: m['id'],
              menuName: m['menuName'],
              category: m['category'] ?? FoodCategory.other.label,
              description: m['description'],
              imageUrl: m['imageUrl'] ?? '',
              highlights: List<String>.from(m['highlights'] ?? []),
              ownerId: m['ownerId'],
              ownerName: m['ownerName'],
              likeCount: m['likeCount'],
              likedBy: List<String>.from(m['likedBy'] ?? []),
              createdAt: DateTime.parse(m['createdAt']),
            ))
        .toList();
  }
}
