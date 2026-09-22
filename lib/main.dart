import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ล็อกอินแบบไม่ระบุตัวตน เพื่อให้ทุกคนมี uid สำหรับกด Like/Save ได้ทันที
  // โดยไม่ต้องสมัครสมาชิก (เปิดใช้ Anonymous ใน Firebase Console > Authentication)
  if (FirebaseAuth.instance.currentUser == null) {
    await FirebaseAuth.instance.signInAnonymously();
  }

  runApp(const FoodResumeApp());
}

class FoodResumeApp extends StatelessWidget {
  const FoodResumeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food Resume',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFFFF7A45),
        useMaterial3: true,
        fontFamily: 'Kanit',
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      ),
      // Responsive: MediaQuery + LayoutBuilder ถูกใช้ในแต่ละหน้าเพื่อรองรับ
      // ทั้งจอมือถือแนวตั้ง/แนวนอน และแท็บเล็ต (ดูรายละเอียดใน home_screen.dart)
      home: const HomeScreen(),
    );
  }
}
