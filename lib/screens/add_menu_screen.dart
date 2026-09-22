import 'package:flutter/material.dart';
import '../models/food_resume.dart';
import '../services/firestore_service.dart';

class AddMenuScreen extends StatefulWidget {
  const AddMenuScreen({super.key});

  @override
  State<AddMenuScreen> createState() => _AddMenuScreenState();
}

class _AddMenuScreenState extends State<AddMenuScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _ownerCtrl = TextEditingController();

  final _firestore = FirestoreService();

  FoodCategory _category = FoodCategory.thai;
  bool _saving = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final resume = FoodResume(
        id: '',
        menuName: _nameCtrl.text.trim(),
        category: _category.label,
        description: _descCtrl.text.trim(),
        ownerId: _firestore.currentUid,
        ownerName: _ownerCtrl.text.trim().isEmpty
            ? 'ไม่ระบุชื่อ'
            : _ownerCtrl.text.trim(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('เพิ่มเรซูเม่อาหารใหม่'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'ชื่อเมนู *'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'กรุณากรอกชื่อเมนู' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<FoodCategory>(
              initialValue: _category,
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
              controller: _ownerCtrl,
              decoration: const InputDecoration(
                  labelText: 'ชื่อผู้สร้างเมนู (แสดงบนเรซูเม่)'),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _submit,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save),
              label: Text(_saving ? 'กำลังบันทึก...' : 'บันทึกเรซูเม่อาหาร'),
            ),
          ],
        ),
      ),
    );
  }
}
