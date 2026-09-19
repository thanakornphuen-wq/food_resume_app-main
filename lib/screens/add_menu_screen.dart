import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/food_resume.dart';
import '../services/firestore_service.dart';
import '../services/meal_api_service.dart';

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
        SnackBar(content: Text('เลือกรูปภาพไม่สำเร็จ: $e')),
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
          const SnackBar(content: Text('ยังโหลดไอเดียเมนูไม่ได้ กรุณาลองใหม่')),
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
        const SnackBar(content: Text('สุ่มไอเดียและสูตรจาก TheMealDB สำเร็จ 🎲')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เชื่อมต่อ TheMealDB ไม่สำเร็จ: $e')),
      );
    } finally {
      if (mounted) setState(() => _loadingIdea = false);
    }
  }

  void _addHighlight() {
    final text = _highlightCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _highlights.add(text);
      _highlightCtrl.clear();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
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
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
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
    final previewImage = _pickedImageBytes != null
        ? Image.memory(
            _pickedImageBytes!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Center(
              child: Icon(Icons.broken_image, size: 48, color: Colors.orangeAccent),
            ),
          )
        : (_networkImageUrl != null
            ? Image.network(
                _networkImageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.broken_image, size: 48, color: Colors.orangeAccent),
                ),
              )
            : null);

    return Scaffold(
      appBar: AppBar(
        title: const Text('เพิ่มเรซูเม่อาหารใหม่'),
        actions: [
          IconButton(
            tooltip: 'สุ่มไอเดียจาก API',
            icon: _loadingIdea
                ? const SizedBox(
                    width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.auto_awesome),
            onPressed: _loadingIdea ? null : _getRandomIdea,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(16),
                ),
                clipBehavior: Clip.antiAlias,
                child: previewImage ??
                    const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_a_photo, size: 40, color: Colors.orangeAccent),
                          SizedBox(height: 8),
                          Text('แตะเพื่อเลือกรูป หรือกด ✨ เพื่อสุ่มไอเดีย'),
                        ],
                      ),
                    ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'ชื่อเมนู *'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'กรุณากรอกชื่อเมนู' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<FoodCategory>(
              value: _category,
              decoration: const InputDecoration(labelText: 'หมวดหมู่ *'),
              items: FoodCategory.values
                  .map((c) => DropdownMenuItem(value: c, child: Text(c.label)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'คำอธิบาย / เรื่องราวของเมนูนี้',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _ingredientsCtrl,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'วัตถุดิบ',
                hintText: 'พิมพ์วัตถุดิบ 1 รายการต่อ 1 บรรทัด',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _instructionsCtrl,
              minLines: 3,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: 'วิธีทำ',
                hintText: 'พิมพ์ขั้นตอน 1 ขั้นต่อ 1 บรรทัด',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _ownerCtrl,
              decoration: const InputDecoration(labelText: 'ชื่อผู้สร้างเมนู (แสดงบนเรซูเม่)'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _highlightCtrl,
                    decoration: const InputDecoration(
                      labelText: 'จุดเด่น เช่น เผ็ดระดับ 5',
                    ),
                    onSubmitted: (_) => _addHighlight(),
                  ),
                ),
                IconButton(icon: const Icon(Icons.add_circle), onPressed: _addHighlight),
              ],
            ),
            Wrap(
              spacing: 8,
              children: _highlights
                  .map((h) => Chip(
                        label: Text(h),
                        onDeleted: () => setState(() => _highlights.remove(h)),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _submit,
              icon: _saving
                  ? const SizedBox(
                      width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save),
              label: Text(_saving ? 'กำลังบันทึก...' : 'บันทึกเรซูเม่อาหาร'),
            ),
          ],
        ),
      ),
    );
  }
}
