# 🍽️ Food Resume App

แอป Flutter สำหรับอวด "เรซูเม่อาหาร" ของตัวเอง — เพิ่มเมนู กด Like ให้เมนูที่ถูกใจที่สุดลอยขึ้นบนสุด
กรองตามหมวดหมู่ ค้นหาชื่อเมนู และบันทึก (Save) เรซูเม่ของคนอื่นไว้ดูในโปรไฟล์

## การแก้ไขเวอร์ชัน 1.0.1

- ตัวกรองหมวดหมู่แสดงเฉพาะรายการที่เลือกโดยไม่ต้องสร้าง Firestore composite index
- แก้หน้ารายละเอียดแดงจากการใช้วันที่ภาษาไทย และเพิ่มส่วนวัตถุดิบ/วิธีทำ
- เลือก แสดงตัวอย่าง และอัปโหลดรูปได้ทั้ง Flutter Web, Android และ iOS
- หน้าโปรไฟล์แสดงรูป/ข้อความของเมนูที่บันทึกไว้ และไม่เกิด Bottom Overflow

## ฟีเจอร์ตามที่กำหนด

| ข้อกำหนด | สิ่งที่ทำ |
|---|---|
| ใช้ฐานข้อมูล CRUD | Firebase Firestore — เพิ่ม/แก้ไข/ลบเรซูเม่อาหาร ระบบ Like/Save |
| เรียกใช้ API ภายนอก | [TheMealDB](https://www.themealdb.com/api.php) — สุ่ม/ค้นหาไอเดียเมนูตอนเพิ่มข้อมูล |
| เทคนิคใหม่ที่ไม่ได้สอนในห้อง | Offline-first caching ด้วย `shared_preferences`, Masonry/Staggered Grid layout, Firestore Transaction กันข้อมูลชนตอนกด Like พร้อมกัน, Debounced search |
| ใช้งานได้จริงบนมือถือ | ทดสอบผ่าน `flutter run` บนอุปกรณ์จริง/emulator ทั้ง Android และ iOS |
| Responsive UI | `LayoutBuilder` ปรับจำนวนคอลัมน์ของกริดตามความกว้างหน้าจอ |

## โครงสร้างโปรเจกต์

```
lib/
  models/food_resume.dart        โมเดลข้อมูลเรซูเม่อาหาร
  services/
    firestore_service.dart       CRUD + Like + Save (Firebase)
    meal_api_service.dart        เรียก API ภายนอก (TheMealDB)
    local_cache_service.dart     แคชข้อมูลไว้ใช้ออฟไลน์
  screens/
    home_screen.dart             หน้าแรก: ค้นหา/กรอง/กริดเรียงตามยอดไลก์
    add_menu_screen.dart         ฟอร์มเพิ่มเมนูใหม่ + สุ่มไอเดียจาก API
    detail_screen.dart           รายละเอียดเรซูเม่อาหาร + ลบ (ผู้ใช้ที่ล็อกอินทุกคน)
    profile_screen.dart          รายการที่บันทึกไว้
  widgets/resume_card.dart       การ์ดเรซูเม่อาหาร (ใช้ซ้ำหลายหน้า)
  firebase_options.dart          ⚠️ ต้องสร้างใหม่ด้วย flutterfire configure
  main.dart
```

## การตั้งค่า Firebase (ต้องทำก่อนรันแอป)

1. ติดตั้งเครื่องมือ (ทำครั้งเดียว):
   ```bash
   dart pub global activate flutterfire_cli
   npm install -g firebase-tools   # ถ้ายังไม่มี Firebase CLI
   firebase login
   ```
2. ที่โฟลเดอร์โปรเจกต์นี้ รัน:
   ```bash
   flutterfire configure
   ```
   เลือกสร้างโปรเจกต์ Firebase ใหม่ (หรือใช้ของเดิม) แล้วเลือกแพลตฟอร์ม Android/iOS
   คำสั่งนี้จะเขียนทับ `lib/firebase_options.dart` ให้อัตโนมัติด้วยค่าคีย์จริง
3. เปิดใช้บริการใน [Firebase Console](https://console.firebase.google.com):
   - **Authentication** → Sign-in method → เปิด **Anonymous**
   - **Firestore Database** → สร้างฐานข้อมูล (โหมด production หรือ test)
   - **Storage** → เปิดใช้งาน (สำหรับเก็บรูปเมนูที่ผู้ใช้ถ่าย/เลือกเอง)

### กฎความปลอดภัยและโครงสร้างข้อมูล

- เมนูยังอยู่ที่ `food_resumes/{id}` และใช้ `ownerId` ตามเดิม ไม่มี Admin/สิทธิ์ตาม role
- Feed, Category และ Search อ่านเมนูทั้งหมด ไม่มี filter ตาม UID
- Login เดิมเป็น Anonymous Authentication ไม่มีหน้า Login/Register แบบอีเมลใน repository นี้
- Saved ยังอยู่ที่ `users/{uid}/saved/{id}` และอ่าน/เขียนได้เฉพาะผู้ใช้คนนั้น
- ใช้ `firestore.rules` เป็นกฎจริง: อ่านและลบเมนูได้เมื่อล็อกอิน, สร้างในชื่อของตัวเอง, แก้ไขเมนูเฉพาะเจ้าของ และเปลี่ยนเจ้าของไม่ได้
- เพื่อให้คนอื่น Like ได้โดยไม่ต้องอนุญาต update document เมนู เพิ่ม `food_resumes/{id}/food_likes/{uid}` เก็บ `{active: true/false}` แต่ละคนเขียนได้เฉพาะ vote ของตนเอง
- แอปรวม vote ใหม่กับ `likedBy`/`likeCount` เดิมใน model ก่อนแสดงผลและเรียง Feed ไม่ต้อง migrate เมนูหรือ Like เดิม ค่าใน document หลักเป็นฐานเดิมและจะไม่เพิ่มตาม vote ใหม่
- ใช้ collectionGroup `food_likes` แบบไม่มี filter/orderBy จึงไม่ต้องสร้าง composite index และใช้ RxDart ที่มีอยู่แล้ว
- Profile รับเมนูแบบ realtime แล้วเลือกเฉพาะ Saved ของผู้ใช้ ทำให้เมนูที่ถูกลบหายทันที
- เมื่อลบเมนู แอปพยายามลบรูปจาก `imageUrl` เฉพาะ bucket เดิมและ path `food_images/` ถ้าลบรูปไม่สำเร็จยังถือว่าลบเมนูสำเร็จ
- Firestore ไม่ลบ subcollection ตาม document แม่: vote และ Saved reference เก่าอาจยังอยู่ แต่แอปไม่แสดงรายการที่ไม่มีเมนูแล้ว

### ขั้นตอนใน Firebase Console

1. เปิด project `foodresume-d6c84` → Authentication → Sign-in method → เปิด Anonymous ตามระบบ Login เดิม
2. เปิด Firestore Database → Rules → นำเนื้อหา `firestore.rules` ทั้งไฟล์ไปแทนกฎเดิม → Publish
3. เปิด Storage → Rules → นำเนื้อหา `storage.rules` ทั้งไฟล์ไปแทนกฎเดิม → Publish
4. รูปที่อัปโหลดผ่าน service หลังแก้จะมี custom metadata `ownerId` สำหรับตรวจสิทธิ์ลบ รูปเก่าที่ไม่มี metadata นี้อาจลบอัตโนมัติไม่ได้ ให้ตรวจ `imageUrl` และ `ownerId` ของเมนูเพื่อระบุรูป แล้วลบรูปเก่าที่ค้างใน Storage Console เองเมื่อจำเป็น อย่าเปิดสิทธิ์ลบรูปให้ทุกคน
5. ทดสอบด้วยผู้ใช้สอง UID: ทั้งสองเห็นเมนูเดียวกัน, Like/Save แยกกัน, ทั้งสองเห็นปุ่มลบใน Detail, ยกเลิกไม่ลบ, ยืนยันแล้วกลับ Home และเมนูหายจากรายการ รูปจะถูกลบด้วยเมื่อ Storage Rules อนุญาต

หรือใช้ Firebase CLI ที่ล็อกอินแล้ว:

```bash
firebase deploy --only firestore:rules,storage --project foodresume-d6c84
```

ไฟล์ `firebase.json` ผูก rules ให้แล้ว แต่การแก้ไฟล์ในเครื่องยังไม่เปลี่ยนกฎบน Firebase จนกว่าจะ Publish/deploy

อ้างอิง: [Firestore field rules](https://firebase.google.com/docs/firestore/security/rules-fields), [Storage conditions](https://firebase.google.com/docs/storage/security/rules-conditions), [Flutter Storage deletion](https://firebase.google.com/docs/storage/flutter/delete-files)

## วิธีรันแอป

```bash
flutter pub get
flutter run            # รันบนอุปกรณ์จริงหรือ emulator ที่เชื่อมต่ออยู่
```

## สิ่งที่ต้องแก้ก่อนส่งงานจริง

1. รัน `flutterfire configure` เพื่อแทนที่ `lib/firebase_options.dart` ด้วยค่าจริง
2. (ถ้าต้องการ) เพิ่มฟอนต์ `Kanit` ลงโฟลเดอร์ `assets/fonts` และประกาศใน `pubspec.yaml` หากต้องการใช้ฟอนต์ไทยที่สวยขึ้น มิฉะนั้นให้ลบบรรทัด `fontFamily: 'Kanit'` ออกจาก `main.dart`
3. Android: ต้องมี `android/app/google-services.json` (สร้างอัตโนมัติจาก `flutterfire configure`)
4. iOS: ต้องมี `ios/Runner/GoogleService-Info.plist` (สร้างอัตโนมัติจาก `flutterfire configure`)

## หมายเหตุเรื่อง API ภายนอก

TheMealDB คีย์ทดสอบ (`1`) ใช้ได้ฟรีไม่จำกัด เหมาะสำหรับโปรเจกต์การศึกษา หากต้องการ API เมนูอาหารไทยโดยเฉพาะ
สามารถเปลี่ยนไปเรียก endpoint อื่นใน `lib/services/meal_api_service.dart` ได้เช่นกัน
