import 'dart:convert';
import 'package:http/http.dart' as http;

/// เรียกใช้ API ภายนอก: TheMealDB (https://www.themealdb.com/api.php)
/// เป็น Public API ฟรีเกี่ยวกับอาหารโดยเฉพาะ ใช้สำหรับ:
///  - ค้นหาข้อมูลเมนูจากชื่อภาษาอังกฤษเพื่อดึงรูปภาพ/หมวดหมู่มาเป็นค่าเริ่มต้น
class MealApiService {
  static const _base = 'https://www.themealdb.com/api/json/v1/1';

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
