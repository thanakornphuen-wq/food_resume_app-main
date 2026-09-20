import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/food_resume.dart';
import '../services/firestore_service.dart';
import '../services/meal_api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/section_title.dart';

/// หน้าจอเพิ่มเรซูเม่อาหารใหม่ (Add Menu Screen)
/// ออกแบบเป็นสไตล์ Gourmet Form แบ่ง Section ชัดเจน
/// รองรับการเลือกรูปภาพจากเครื่อง, การสุ่มไอเดียจาก TheMealDB API
/// และรองรับ Responsive Max-width สำหรับหน้าจอใหญ่
class AddMenuScreen extends StatefulWidget {
  const AddMenuScreen({super.key});

  @override
  State<AddMenuScreen> createState() => _AddMenuScreenState();
}

class _AddMenuScreenState extends State<AddMenuScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _highlightCtrl = TextEditingController();
  final _ownerCtrl = TextEditingController();
  final _ingredientsCtrl = TextEditingController();
  final _instructionsCtrl = TextEditingController();

  final _firestore = FirestoreService();
  final _mealApi = MealApiService();

  FoodCategory _category = FoodCategory.thai;
  Uint8List? _pickedImageBytes;
  String? _pickedImageName;
  String? _networkImageUrl; // จาก TheMealDB
  final List<String> _highlights = [];
  bool _saving = false;
  bool _loadingIdea = false;

  final List<String> _suggestedHighlights = [
    '🌶️ เผ็ดจัดจ้าน',
    '⭐ สูตรเด็ดโบราณ',
    '🧀 หอมชีสเน้นๆ',
    '🥗 เพื่อสุขภาพ',
    '⏱️ ทำง่ายใน 15 นาที',
    '🥩 เนื้อนุ่มละมุนลิ้น',
  ];

  String _formatCategory(FoodCategory cat) {
    return switch (cat) {
      FoodCategory.thai => '🍜 อาหารไทย',
      FoodCategory.japanese => '🍣 อาหารญี่ปุ่น',
      FoodCategory.dessert => '🍰 ของหวาน',
      FoodCategory.drink => '🧋 เครื่องดื่ม',
      FoodCategory.bakery => '🥐 เบเกอรี่',
      FoodCategory.streetFood => '🍢 สตรีทฟู้ด',
      FoodCategory.other => '🍽️ อื่นๆ',
    };
  }

  Future<void> _pickImage() async {
    try {
      final picked = await ImagePicker()
          .pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        if (!mounted) return;
        setState(() {
          _pickedImageBytes = bytes;
          _pickedImageName = picked.name;
          _networkImageUrl = null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เลือกรูปภาพไม่สำเร็จ: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// เรียก API ภายนอก (TheMealDB) เพื่อสุ่มไอเดียเมนูมาช่วยกรอกฟอร์ม
  Future<void> _getRandomIdea() async {
    setState(() => _loadingIdea = true);
    try {
      final meal = await _mealApi.fetchRandomMeal();
      if (!mounted) return;
      if (meal == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ยังโหลดไอเดียเมนูไม่ได้ กรุณาลองใหม่อีกครั้ง'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      setState(() {
        _nameCtrl.text = meal['name'] ?? '';
        _networkImageUrl = meal['imageUrl'];
        _pickedImageBytes = null;
        _pickedImageName = null;
        _ingredientsCtrl.text =
            (meal['ingredients'] as List? ?? []).join('\n');
        _instructionsCtrl.text = (meal['instructions'] ?? '')
            .toString()
            .split(RegExp(r'\r?\n'))
            .where((line) => line.trim().isNotEmpty)
            .join('\n');
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('สุ่มไอเดียและสูตรอาหารจาก TheMealDB สำเร็จ! 🎲✨'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เชื่อมต่อ TheMealDB ไม่สำเร็จ: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _loadingIdea = false);
    }
  }

  void _addHighlight([String? predefinedText]) {
    final text = (predefinedText ?? _highlightCtrl.text).trim();
    if (text.isEmpty || _highlights.contains(text)) return;
    setState(() {
      _highlights.add(text);
      if (predefinedText == null) {
        _highlightCtrl.clear();
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณากรอกข้อมูลที่จำเป็น (*) ให้ครบถ้วน'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      String imageUrl = _networkImageUrl ?? '';
      if (_pickedImageBytes != null) {
        final originalName = _pickedImageName ?? 'image.jpg';
        final extension = originalName.contains('.')
            ? originalName.substring(originalName.lastIndexOf('.'))
            : '.jpg';
        final fileName = '${DateTime.now().millisecondsSinceEpoch}$extension';
        imageUrl = await _firestore.uploadImageBytes(_pickedImageBytes!, fileName);
      }

      final resume = FoodResume(
        id: '',
        menuName: _nameCtrl.text.trim(),
        category: _category.label,
        description: _descCtrl.text.trim(),
        imageUrl: imageUrl,
        highlights: _highlights,
        ingredients: _linesFrom(_ingredientsCtrl.text),
        instructions: _linesFrom(_instructionsCtrl.text),
        ownerId: _firestore.currentUid,
        ownerName: _ownerCtrl.text.trim().isEmpty ? 'ไม่ระบุชื่อ' : _ownerCtrl.text.trim(),
        likeCount: 0,
        likedBy: const [],
        createdAt: DateTime.now(),
      );

      await _firestore.addResume(resume);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('บันทึกเรซูเม่เมนู "${resume.menuName}" สำเร็จ! 🎉'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการบันทึก: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  List<String> _linesFrom(String value) => value
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _highlightCtrl.dispose();
    _ownerCtrl.dispose();
    _ingredientsCtrl.dispose();
    _instructionsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = _pickedImageBytes != null || _networkImageUrl != null;

    final previewImage = _pickedImageBytes != null
        ? Image.memory(
            _pickedImageBytes!,
            fit: BoxFit.cover,
            width: double.infinity,
            errorBuilder: (_, __, ___) => _imageErrorWidget(),
          )
        : (_networkImageUrl != null
            ? Image.network(
                _networkImageUrl!,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (_, __, ___) => _imageErrorWidget(),
              )
            : null);

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
                  // Inspiration Banner (TheMealDB API)
                  _buildInspirationCard(),

                  const SizedBox(height: 16),

                  // Image Upload Hero Area
                  _buildImagePickerCard(hasImage, previewImage),

                  const SizedBox(height: 20),

                  // Section 1: ข้อมูลทั่วไปของเมนู
                  _buildSectionCard(
                    title: 'ข้อมูลทั่วไปของเมนู 📋',
                    children: [
                      // Menu Name
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'ชื่อเมนูอาหาร *',
                          hintText: 'เช่น ต้มยำกุ้งน้ำข้น, พาสต้าทรัฟเฟิล',
                          prefixIcon: Icon(Icons.restaurant_rounded, color: AppColors.primary),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'กรุณากรอกชื่อเมนูอาหาร' : null,
                      ),
                      const SizedBox(height: 14),

                      // Category Selector
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
                      const SizedBox(height: 14),

                      // Description
                      TextFormField(
                        controller: _descCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'เรื่องราว / คำอธิบายของเมนูนี้',
                          hintText: 'เล่าที่มา รสชาติ จุดเด่น หรือความประทับใจของเมนูนี้...',
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Creator / Owner Name
                      TextFormField(
                        controller: _ownerCtrl,
                        decoration: const InputDecoration(
                          labelText: 'ชื่อเชฟผู้สร้างเมนู (แสดงบนการ์ด)',
                          hintText: 'เช่น เชฟมิ้นท์, ครัวคุณแม่ (หากไม่ระบุจะขึ้น "ไม่ระบุชื่อ")',
                          prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Section 2: วัตถุดิบ
                  _buildSectionCard(
                    title: 'วัตถุดิบที่ต้องใช้ 🥗',
                    subtitle: 'พิมพ์ 1 รายการต่อ 1 บรรทัด (เช่น หมูสับ 200 กรัม)',
                    children: [
                      TextFormField(
                        controller: _ingredientsCtrl,
                        minLines: 4,
                        maxLines: 8,
                        decoration: const InputDecoration(
                          hintText: "อกไก่ 300 กรัม\nกระเทียมสับ 2 ช้อนโต๊ะ\nพริกไทยดำ 1 ช้อนชา\nน้ำมันหอย 1 ช้อนโต๊ะ",
                          alignLabelWithHint: true,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Section 3: ขั้นตอนการทำ
                  _buildSectionCard(
                    title: 'ขั้นตอนการทำ 👨‍🍳',
                    subtitle: 'พิมพ์ 1 ขั้นตอนต่อ 1 บรรทัด เพื่อจัดเป็น Step-by-Step สวยงาม',
                    children: [
                      TextFormField(
                        controller: _instructionsCtrl,
                        minLines: 4,
                        maxLines: 10,
                        decoration: const InputDecoration(
                          hintText: "1. หั่นเนื้อไก่เป็นชิ้นพอดีคำ แล้วหมักด้วยเครื่องปรุง 15 นาที\n2. ตั้งกระทะใส่น้ำมัน ใช้ไฟปานกลาง เจียวกระเทียมจนหอม\n3. ใส่ไก่ลงไปผัดจนสุกเหลือง ตักเสิร์ฟพร้อมข้าวสวยร้อนๆ",
                          alignLabelWithHint: true,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Section 4: จุดเด่นของเมนู
                  _buildSectionCard(
                    title: 'จุดเด่นของเมนู (Highlights) 🌟',
                    subtitle: 'ติดป้ายแท็กเพื่อความน่าสนใจของเรซูเม่อาหาร',
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _highlightCtrl,
                              decoration: const InputDecoration(
                                labelText: 'พิมพ์จุดเด่น เช่น เผ็ดระดับ 5',
                                prefixIcon: Icon(
                                  Icons.local_fire_department_rounded,
                                  color: AppColors.accentAmber,
                                ),
                              ),
                              onSubmitted: (_) => _addHighlight(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.tonal(
                            onPressed: () => _addHighlight(),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primaryLight,
                              foregroundColor: AppColors.primaryDark,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Icon(Icons.add_rounded),
                          ),
                        ],
                      ),

                      // Quick suggestion chips
                      const SizedBox(height: 12),
                      const Text(
                        'แท็กแนะนำยอดนิยม (แตะเพื่อเพิ่ม):',
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _suggestedHighlights.map((suggestion) {
                          final alreadyAdded = _highlights.contains(suggestion);
                          return ActionChip(
                            label: Text(
                              suggestion,
                              style: TextStyle(
                                fontSize: 12,
                                color: alreadyAdded ? AppColors.textMuted : AppColors.textPrimary,
                              ),
                            ),
                            backgroundColor:
                                alreadyAdded ? AppColors.borderLight : AppColors.surfaceContainer,
                            onPressed: alreadyAdded ? null : () => _addHighlight(suggestion),
                          );
                        }).toList(),
                      ),

                      // Added highlights
                      if (_highlights.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        const Divider(height: 1, color: AppColors.borderLight),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _highlights
                              .map((h) => Chip(
                                    avatar: const Icon(
                                      Icons.check_circle_rounded,
                                      size: 16,
                                      color: AppColors.accentAmber,
                                    ),
                                    label: Text(
                                      h,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF92400E),
                                      ),
                                    ),
                                    backgroundColor:
                                        AppColors.accentAmberLight.withValues(alpha: 0.8),
                                    deleteIcon: const Icon(Icons.close_rounded, size: 16),
                                    onDeleted: () => setState(() => _highlights.remove(h)),
                                  ))
                              .toList(),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Primary Submit Button
                  FilledButton.icon(
                    onPressed: _saving ? null : _submit,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    icon: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.restaurant_rounded, size: 22),
                    label: Text(
                      _saving ? 'กำลังอัปโหลดและบันทึกข้อมูล...' : 'บันทึกเรซูเม่อาหาร',
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
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'หมดมุกคิดเมนู? สุ่มไอเดียด้วย API 🎲',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'ดึงสูตรอาหาร รูปภาพ และวัตถุดิบอัตโนมัติจาก TheMealDB',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _loadingIdea
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  )
                : const Text(
                    'สุ่มเลย',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePickerCard(bool hasImage, Widget? previewImage) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: hasImage ? AppColors.borderLight : AppColors.primary.withValues(alpha: 0.3),
          width: 1.2,
        ),
        boxShadow: AppColors.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          if (hasImage && previewImage != null)
            Stack(
              children: [
                SizedBox(
                  height: 220,
                  width: double.infinity,
                  child: previewImage,
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Change image button
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(color: Color(0x1A000000), blurRadius: 6),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.edit_rounded, color: AppColors.textPrimary, size: 18),
                          tooltip: 'เปลี่ยนรูปภาพ',
                          onPressed: _pickImage,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Remove image button
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(color: Color(0x1A000000), blurRadius: 6),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626), size: 18),
                          tooltip: 'ลบรูปภาพ',
                          onPressed: () {
                            setState(() {
                              _pickedImageBytes = null;
                              _pickedImageName = null;
                              _networkImageUrl = null;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          else
            InkWell(
              onTap: _pickImage,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: AppColors.primaryLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add_a_photo_rounded,
                          size: 36,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'แตะเพื่อเลือกรูปภาพอาหารของคุณ',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'รองรับทั้งการเลือกไฟล์จากเครื่อง หรือกดสุ่มจาก TheMealDB',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    String? subtitle,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight, width: 1),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
            title: title,
            subtitle: subtitle,
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _imageErrorWidget() => Container(
        color: AppColors.surfaceContainer,
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.broken_image_rounded, size: 40, color: AppColors.textMuted),
              SizedBox(height: 6),
              Text(
                'ไม่สามารถแสดงตัวอย่างรูปภาพได้',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      );
}
