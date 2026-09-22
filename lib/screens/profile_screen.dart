import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../models/food_resume.dart';
import '../services/firestore_service.dart';
import '../widgets/resume_card.dart';
import 'detail_screen.dart';

/// หน้าโปรไฟล์ผู้ใช้ — แสดงเรซูเม่อาหารที่ "บันทึก (Save)" ไว้จากคนอื่น
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = FirestoreService();

    return Scaffold(
      appBar: AppBar(title: const Text('โปรไฟล์ของฉัน')),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: CircleAvatar(radius: 36, child: Icon(Icons.person, size: 36)),
          ),
          const Text('เรซูเม่อาหารที่บันทึกไว้', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<List<String>>(
              stream: firestore.streamSavedIds(),
              builder: (context, savedSnap) {
                if (!savedSnap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (savedSnap.data!.isEmpty) {
                  return const Center(child: Text('ยังไม่ได้บันทึกเมนูของใครไว้เลย'));
                }
                return FutureBuilder<List<FoodResume>>(
                  future: firestore.getSavedResumes(),
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final saved = snap.data!;
                    return MasonryGridView.extent(
                      padding: const EdgeInsets.all(12),
                      maxCrossAxisExtent:
                          200 * MediaQuery.textScalerOf(context).scale(14) / 14,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      itemCount: saved.length,
                      itemBuilder: (context, i) {
                        final r = saved[i];
                        return ResumeCard(
                          resume: r,
                          currentUid: firestore.currentUid,
                          isSaved: true,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => DetailScreen(resumeId: r.id)),
                          ),
                          onLike: () => firestore.toggleLike(r.id),
                          onSave: () => firestore.toggleSave(r.id),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
