import '../models/food_resume.dart';

/// Filter the same category field that ResumeCard displays, for live and cached data.
List<FoodResume> filterFoodResumes(
  Iterable<FoodResume> resumes, {
  String? category,
  String? search,
}) {
  final selected = FoodCategory.normalize(category ?? '');
  final query = (search ?? '').trim().toLowerCase();
  return resumes.where((resume) {
    final matchesCategory = selected.isEmpty ||
        selected == 'ทั้งหมด' ||
        FoodCategory.normalize(resume.category) == selected;
    return matchesCategory && resume.menuName.toLowerCase().contains(query);
  }).toList();
}
