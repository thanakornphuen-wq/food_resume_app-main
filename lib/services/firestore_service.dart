import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('กรุณาเข้าสู่ระบบก่อนอัปโหลดรูป');
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
      SettableMetadata(
        contentType: contentType,
        customMetadata: {'ownerId': user.uid},
      ),
    );
    return task.ref.getDownloadURL();
  }

  // ---------- READ (real-time, เรียงตาม like มากไปน้อย) ----------
  Stream<List<FoodResume>> streamResumes({String? category, String? search}) {
    // กรองและเรียงฝั่งแอป เพื่อไม่บังคับให้ผู้ใช้สร้าง Firestore composite index
    // และทำให้การเปลี่ยนหมวดหมู่แสดงผลได้ทันที
    return Rx.combineLatest2(
      _resumes.snapshots(),
      _db.collectionGroup('food_likes').snapshots(),
      (QuerySnapshot<Map<String, dynamic>> snap,
          QuerySnapshot<Map<String, dynamic>> likes) {
      final byMenu = <String, Map<String, bool>>{};
      for (final like in likes.docs) {
        final parent = like.reference.parent.parent;
        if (parent?.parent.path != 'food_resumes') continue;
        byMenu.putIfAbsent(parent!.id, () => {})[like.id] = like.data()['active'] == true;
      }
      var list = snap.docs.map((d) => FoodResume.fromDoc(d)
          .withLikes(byMenu[d.id] ?? {})).toList();
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
    final resume = await streamResume(id).first;
    if (resume == null) {
      throw StateError('ไม่พบสูตรอาหารนี้ หรือสูตรอาหารถูกลบแล้ว');
    }
    return resume;
  }

  Stream<FoodResume?> streamResume(String id) {
    return Rx.combineLatest2(
      _resumes.doc(id).snapshots(),
      _resumes.doc(id).collection('food_likes').snapshots(),
      (DocumentSnapshot<Map<String, dynamic>> doc,
          QuerySnapshot<Map<String, dynamic>> likes) {
      if (!doc.exists) return null;
      return FoodResume.fromDoc(doc).withLikes({
        for (final like in likes.docs) like.id: like.data()['active'] == true,
      });
    });
  }

  // ---------- UPDATE ----------
  Future<void> updateResume(String id, Map<String, dynamic> data) async {
    await _resumes.doc(id).update(data);
  }

  /// กด/ยกเลิก Like — ใช้ Transaction ป้องกันข้อมูลชนกันเวลามีคนกดพร้อมกัน
  Future<void> toggleLike(String resumeId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('กรุณาเข้าสู่ระบบก่อนกดถูกใจ');
    final docRef = _resumes.doc(resumeId);
    final likeRef = docRef.collection('food_likes').doc(uid);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      final like = await tx.get(likeRef);
      final data = snap.data();
      if (data == null) return;
      final likedBy = List<String>.from(data['likedBy'] ?? []);
      final active = like.data()?['active'] as bool? ?? likedBy.contains(uid);
      tx.set(likeRef, {'active': !active});
    });
  }

  // ---------- DELETE ----------
  Future<void> deleteResume(String id) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('กรุณาเข้าสู่ระบบก่อนลบเมนู');
    final ref = _resumes.doc(id);
    final imageUrl = await _db.runTransaction<String>((tx) async {
      final snapshot = await tx.get(ref);
      final data = snapshot.data();
      if (data == null) throw StateError('ไม่พบเมนูนี้');
      tx.delete(ref);
      return data['imageUrl'] as String? ?? '';
    });

    // The document is already deleted. Image cleanup is best effort, and must
    // never turn a successful menu deletion into an error in the UI.
    if (imageUrl.isEmpty) return;
    try {
      final uri = Uri.tryParse(imageUrl);
      if (uri == null ||
          !(uri.scheme == 'gs' ||
              (uri.scheme == 'https' &&
                  uri.host == 'firebasestorage.googleapis.com'))) {
        return; // External images (for example TheMealDB) are not ours to delete.
      }
      final imageRef = _storage.refFromURL(imageUrl);
      if (imageRef.bucket != _storage.ref().bucket ||
          !imageRef.fullPath.startsWith('food_images/')) {
        return;
      }
      await imageRef.delete();
    } catch (error) {
      debugPrint('Menu deleted; image cleanup failed: $error');
    }
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
    return _savedRef(currentUid).orderBy('savedAt', descending: true).snapshots().map(
          (snap) => snap.docs.map((d) => d.id).toList(),
        );
  }

  Future<List<FoodResume>> getSavedResumes() async {
    final savedSnap = await _savedRef(currentUid)
        .orderBy('savedAt', descending: true)
        .get();
    final ids = savedSnap.docs.map((d) => d.id).toList();
    if (ids.isEmpty) return [];

    final results = await streamResumes().first;
    // Preserve saved order while including live and legacy likes.
    final byId = {for (final resume in results) resume.id: resume};
    return ids.map((id) => byId[id]).whereType<FoodResume>().toList();
  }
}
