import 'dart:convert';
import 'package:http/http.dart' as http;

/// เรียกใช้ API ภายนอก: TheMealDB (https://www.themealdb.com/api.php)
/// เป็น Public API ฟรีเกี่ยวกับอาหารโดยเฉพาะ ใช้สำหรับ:
///  - "สุ่มไอเดียเมนู" ให้ผู้ใช้ตอนสร้างเรซูเม่อาหารใหม่ (ชื่อ, รูป, หมวดหมู่ตัวอย่าง)
///  - ค้นหาข้อมูลเมนูจากชื่อภาษาอังกฤษเพื่อดึงรูปภาพ/หมวดหมู่มาเป็นค่าเริ่มต้น
class MealApiService {
  static const _base = 'https://www.themealdb.com/api/json/v1/1';

  /// สุ่มเมนูอาหารจากฐานข้อมูลโลก ใช้เป็นแรงบันดาลใจตอนเพิ่มเมนูใหม่
  Future<Map<String, dynamic>?> fetchRandomMeal() async {
    final res = await http.get(Uri.parse('$_base/random.php'));
    if (res.statusCode != 200) return null;
    final data = jsonDecode(res.body);
    final meals = data['meals'] as List?;
    if (meals == null || meals.isEmpty) return null;
    final meal = meals.first;
    final ingredients = <String>[];
    for (var i = 1; i <= 20; i++) {
      final ingredient = (meal['strIngredient$i'] ?? '').toString().trim();
      final measure = (meal['strMeasure$i'] ?? '').toString().trim();
      if (ingredient.isNotEmpty) {
        ingredients.add(measure.isEmpty ? ingredient : '$measure $ingredient');
      }
    }
    return {
      'name': meal['strMeal'],
      'category': meal['strCategory'],
      'imageUrl': meal['strMealThumb'],
      'instructions': meal['strInstructions'],
      'ingredients': ingredients,
    };
  }

  /// ค้นหาเมนูจากชื่อ (ภาษาอังกฤษ) เพื่อช่วยเติมข้อมูลอัตโนมัติ
  Future<List<Map<String, dynamic>>> searchMeal(String name) async {
    final res = await http.get(Uri.parse('$_base/search.php?s=$name'));
    if (res.statusCode != 200) return [];
    final data = jsonDecode(res.body);
    final meals = data['meals'] as List?;
    if (meals == null) return [];
    return meals
        .map<Map<String, dynamic>>((m) => {
              'name': m['strMeal'],
              'category': m['strCategory'],
              'imageUrl': m['strMealThumb'],
            })
        .toList();
  }
}
