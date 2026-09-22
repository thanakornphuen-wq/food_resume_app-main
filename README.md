# 🍽️ Food Resume App

แอป Flutter สำหรับอวด "เรซูเม่อาหาร" ของตัวเอง — เพิ่มเมนู กด Like ให้เมนูที่ถูกใจที่สุดลอยขึ้นบนสุด
กรองตามหมวดหมู่ ค้นหาชื่อเมนู และบันทึก (Save) เรซูเม่ของคนอื่นไว้ดูในโปรไฟล์

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
    detail_screen.dart           รายละเอียดเรซูเม่อาหาร + ลบ (เจ้าของเท่านั้น)
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

### กฎความปลอดภัย (Firestore Rules) ตัวอย่างสำหรับใช้ตอนทำโปรเจกต์/เดโม

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /food_resumes/{id} {
      allow read: if true;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null &&
        (request.auth.uid == resource.data.ownerId ||
         request.resource.data.diff(resource.data).affectedKeys()
           .hasOnly(['likeCount', 'likedBy']));
    }
    match /users/{uid}/saved/{id} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }
  }
}
```

### Storage Rules ตัวอย่าง

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /food_images/{fileName} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

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
