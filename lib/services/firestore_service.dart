import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import '../models/food_resume.dart';

/// รวมทุกการติดต่อกับฐานข้อมูล Firebase (Firestore + Storage + Auth)
/// - Create / Read / Update / Delete เรซูเม่อาหาร
/// - ระบบ Like (real-time, ป้องกันกดซ้ำ)
/// - ระบบ Save/Bookmark เรซูเม่ของคนอื่นไว้ดูในโปรไฟล์
class FirestoreService {
  final _db = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  CollectionReference<Map<String, dynamic>> get _resumes =>
      _db.collection('food_resumes');

  String get currentUid => FirebaseAuth.instance.currentUser?.uid ?? 'guest';

  // ---------- CREATE ----------
  Future<void> addResume(FoodResume resume) async {
    await _resumes.add(resume.toMap());
  }

  /// อัปโหลดจาก bytes จึงใช้ได้ทั้ง Flutter Web, Android และ iOS
  Future<String> uploadImageBytes(Uint8List bytes, String fileName) async {
    final ref = _storage.ref().child('food_images/$fileName');
    final extension = fileName.split('.').last.toLowerCase();
    final contentType = switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      _ => 'image/jpeg',
    };
    final task = await ref.putData(
      bytes,
      SettableMetadata(contentType: contentType),
    );
    return task.ref.getDownloadURL();
  }

  // ---------- READ (real-time, เรียงตาม like มากไปน้อย) ----------
  Stream<List<FoodResume>> streamResumes({String? category, String? search}) {
    // กรองและเรียงฝั่งแอป เพื่อไม่บังคับให้ผู้ใช้สร้าง Firestore composite index
    // และทำให้การเปลี่ยนหมวดหมู่แสดงผลได้ทันที
    return _resumes.snapshots().map((snap) {
      var list = snap.docs.map((d) => FoodResume.fromDoc(d)).toList();
      if (category != null && category.isNotEmpty && category != 'ทั้งหมด') {
        list = list.where((r) => r.category == category).toList();
      }
      if (search != null && search.trim().isNotEmpty) {
        final q = search.trim().toLowerCase();
        list = list.where((r) => r.menuName.toLowerCase().contains(q)).toList();
      }
      list.sort((a, b) => b.likeCount.compareTo(a.likeCount));
      return list;
    });
  }

  Future<FoodResume> getResume(String id) async {
    final doc = await _resumes.doc(id).get();
    if (!doc.exists) {
      throw StateError('ไม่พบสูตรอาหารนี้ หรือสูตรอาหารถูกลบแล้ว');
    }
    return FoodResume.fromDoc(doc);
  }

  Stream<FoodResume?> streamResume(String id) {
    return _resumes.doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return FoodResume.fromDoc(doc);
    });
  }

  // ---------- UPDATE ----------
  Future<void> updateResume(String id, Map<String, dynamic> data) async {
    await _resumes.doc(id).update(data);
  }

  /// กด/ยกเลิก Like — ใช้ Transaction ป้องกันข้อมูลชนกันเวลามีคนกดพร้อมกัน
  Future<void> toggleLike(String resumeId) async {
    final uid = currentUid;
    final docRef = _resumes.doc(resumeId);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      final data = snap.data();
      if (data == null) return;
      final likedBy = List<String>.from(data['likedBy'] ?? []);
      int likeCount = data['likeCount'] ?? 0;

      if (likedBy.contains(uid)) {
        likedBy.remove(uid);
        likeCount = (likeCount - 1).clamp(0, 1 << 30);
      } else {
        likedBy.add(uid);
        likeCount += 1;
      }

      tx.update(docRef, {'likedBy': likedBy, 'likeCount': likeCount});
    });
  }

  // ---------- DELETE ----------
  Future<void> deleteResume(String id) async {
    await _resumes.doc(id).delete();
  }

  // ---------- SAVE / BOOKMARK (เก็บไว้ในโปรไฟล์) ----------
  CollectionReference<Map<String, dynamic>> _savedRef(String uid) =>
      _db.collection('users').doc(uid).collection('saved');

  Future<void> toggleSave(String resumeId) async {
    final uid = currentUid;
    final ref = _savedRef(uid).doc(resumeId);
    final existing = await ref.get();
    if (existing.exists) {
      await ref.delete();
    } else {
      await ref.set({'savedAt': Timestamp.now()});
    }
  }

  Stream<List<String>> streamSavedIds() {
    return _savedRef(currentUid).snapshots().map(
          (snap) => snap.docs.map((d) => d.id).toList(),
        );
  }

  Future<List<FoodResume>> getSavedResumes() async {
    final savedSnap = await _savedRef(currentUid)
        .orderBy('savedAt', descending: true)
        .get();
    final ids = savedSnap.docs.map((d) => d.id).toList();
    if (ids.isEmpty) return [];

    final results = <FoodResume>[];
    // Firestore whereIn รองรับสูงสุด 30 รายการต่อครั้ง
    for (var i = 0; i < ids.length; i += 30) {
      final chunk = ids.sublist(i, i + 30 > ids.length ? ids.length : i + 30);
      final snap = await _resumes
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      results.addAll(snap.docs.map((d) => FoodResume.fromDoc(d)));
    }
    // เรียงตามลำดับที่ผู้ใช้บันทึกล่าสุด แม้ Firestore whereIn จะคืนค่าไม่เรียง
    final byId = {for (final resume in results) resume.id: resume};
    return ids.map((id) => byId[id]).whereType<FoodResume>().toList();
  }
}
