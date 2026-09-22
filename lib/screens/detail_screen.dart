import 'package:flutter/material.dart';
import '../models/food_resume.dart';
import '../services/firestore_service.dart';

class DetailScreen extends StatelessWidget {
  final String resumeId;
  const DetailScreen({super.key, required this.resumeId});

  @override
  Widget build(BuildContext context) {
    final firestore = FirestoreService();

    return Scaffold(
      body: FutureBuilder<FoodResume>(
        future: firestore.getResume(resumeId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final r = snapshot.data!;
          final isOwner = r.ownerId == firestore.currentUid;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                actions: isOwner
                    ? [
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () async {
                            await firestore.deleteResume(r.id);
                            if (context.mounted) Navigator.pop(context);
                          },
                        ),
                      ]
                    : null,
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.menuName,
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      const Text('คำอธิบาย / เรื่องราวของเมนูนี้',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text(r.description.trim().isEmpty
                          ? 'ยังไม่มีคำอธิบาย'
                          : r.description),
                      const SizedBox(height: 16),
                      const Text('ชื่อผู้สร้างเมนู',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text(r.ownerName.trim().isEmpty ||
                              r.ownerName.trim() == 'ไม่ระบุชื่อ'
                          ? 'ไม่ระบุชื่อผู้สร้าง'
                          : r.ownerName),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
