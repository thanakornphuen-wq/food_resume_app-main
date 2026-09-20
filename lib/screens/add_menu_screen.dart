import 'package:flutter/material.dart';
import '../models/food_resume.dart';
import '../services/firestore_service.dart';
import '../services/meal_api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/section_title.dart';

class AddMenuScreen extends StatefulWidget {
  const AddMenuScreen({super.key});

  @override
  State<AddMenuScreen> createState() => _AddMenuScreenState();
}

class _AddMenuScreenState extends State<AddMenuScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _ingredientsCtrl = TextEditingController();
  final _instructionsCtrl = TextEditingController();

  final _firestore = FirestoreService();
  final _mealApi = MealApiService();

  FoodCategory _category = FoodCategory.thai;
  bool _saving = false;
  bool _loadingIdea = false;

  String _formatCategory(FoodCategory cat) => switch (cat) {
    FoodCategory.thai => '🍜 อาหารไทย',
    FoodCategory.japanese => '🍣 อาหารญี่ปุ่น',
    FoodCategory.dessert => '🍰 ของหวาน',
    FoodCategory.drink => '🧋 เครื่องดื่ม',
    FoodCategory.bakery => '🥐 เบเกอรี่',
    FoodCategory.streetFood => '🍢 สตรีทฟู้ด',
    FoodCategory.other => '🍽️ อื่นๆ',
  };

  Future<void> _getRandomIdea() async {
    setState(() => _loadingIdea = true);
    try {
      final meal = await _mealApi.fetchRandomMeal();
      if (!mounted) return;
      if (meal == null) {
        _showSnack('ยังโหลดไอเดียเมนูไม่ได้ กรุณาลองใหม่อีกครั้ง');
        return;
      }
      setState(() {
        _nameCtrl.text = meal['name'] ?? '';
        _ingredientsCtrl.text = (meal['ingredients'] as List? ?? []).join('\n');
        _instructionsCtrl.text = (meal['instructions'] ?? '')
            .toString()
            .split(RegExp(r'\r?\n'))
            .where((l) => l.trim().isNotEmpty)
            .join('\n');
      });
      _showSnack('สุ่มไอเดียสำเร็จ! 🎲✨');
    } catch (e) {
      if (mounted) _showSnack('เชื่อมต่อ TheMealDB ไม่สำเร็จ: $e');
    } finally {
      if (mounted) setState(() => _loadingIdea = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      _showSnack('กรุณากรอกข้อมูลที่จำเป็น (*) ให้ครบถ้วน');
      return;
    }
    setState(() => _saving = true);
    try {
      final resume = FoodResume(
        id: '',
        menuName: _nameCtrl.text.trim(),
        category: _category.label,
        ingredients: _linesFrom(_ingredientsCtrl.text),
        instructions: _linesFrom(_instructionsCtrl.text),
        ownerId: _firestore.currentUid,
        likeCount: 0,
        likedBy: const [],
        createdAt: DateTime.now(),
      );
      await _firestore.addResume(resume);
      if (mounted) {
        _showSnack('บันทึกเมนู "${resume.menuName}" สำเร็จ! 🎉');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) _showSnack('เกิดข้อผิดพลาด: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  List<String> _linesFrom(String v) =>
      v.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

  void _showSnack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
      );

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ingredientsCtrl.dispose();
    _instructionsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('สร้างเรซูเม่อาหารใหม่'),
        elevation: 0,
        backgroundColor: AppColors.background,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                children: [
                  // Inspiration Banner
                  _buildInspirationCard(),
                  const SizedBox(height: 16),

                  // Section 1: ข้อมูลทั่วไป
                  _buildSectionCard(
                    title: 'ข้อมูลทั่วไปของเมนู 📋',
                    children: [
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'ชื่อเมนูอาหาร *',
                          hintText: 'เช่น ต้มยำกุ้งน้ำข้น',
                          prefixIcon: Icon(Icons.restaurant_rounded, color: AppColors.primary),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'กรุณากรอกชื่อเมนูอาหาร' : null,
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<FoodCategory>(
                        initialValue: _category,
                        decoration: const InputDecoration(
                          labelText: 'หมวดหมู่อาหาร *',
                          prefixIcon: Icon(Icons.category_rounded, color: AppColors.primary),
                        ),
                        dropdownColor: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        items: FoodCategory.values
                            .map((c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(_formatCategory(c)),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _category = v!),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Section 2: วัตถุดิบ
                  _buildSectionCard(
                    title: 'วัตถุดิบที่ต้องใช้ 🥗',
                    subtitle: 'พิมพ์ 1 รายการต่อ 1 บรรทัด',
                    children: [
                      TextFormField(
                        controller: _ingredientsCtrl,
                        minLines: 4,
                        maxLines: 8,
                        decoration: const InputDecoration(
                          hintText: 'อกไก่ 300 กรัม\nกระเทียมสับ 2 ช้อนโต๊ะ',
                          alignLabelWithHint: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Section 3: ขั้นตอนการทำ
                  _buildSectionCard(
                    title: 'ขั้นตอนการทำ 👨‍🍳',
                    subtitle: 'พิมพ์ 1 ขั้นตอนต่อ 1 บรรทัด',
                    children: [
                      TextFormField(
                        controller: _instructionsCtrl,
                        minLines: 4,
                        maxLines: 10,
                        decoration: const InputDecoration(
                          hintText: '1. หั่นเนื้อไก่เป็นชิ้นพอดีคำ\n2. เจียวกระเทียมจนหอม\n3. ผัดจนสุก เสิร์ฟพร้อมข้าว',
                          alignLabelWithHint: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Submit Button
                  FilledButton.icon(
                    onPressed: _saving ? null : _submit,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    icon: _saving
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                          )
                        : const Icon(Icons.restaurant_rounded, size: 22),
                    label: Text(
                      _saving ? 'กำลังบันทึก...' : 'บันทึกเรซูเม่อาหาร',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInspirationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('หมดมุกคิดเมนู? สุ่มไอเดียด้วย API 🎲',
                    style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.primaryDark)),
                SizedBox(height: 2),
                Text('ดึงสูตรอาหารและวัตถุดิบจาก TheMealDB',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.tonal(
            onPressed: _loadingIdea ? null : _getRandomIdea,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: _loadingIdea
                ? const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  )
                : const Text('สุ่มเลย', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, String? subtitle, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(title: title, subtitle: subtitle),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}