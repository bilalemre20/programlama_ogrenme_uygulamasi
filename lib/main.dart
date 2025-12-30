import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'viewmodels/lesson_view_model.dart';
import 'views/lesson_list_screen.dart';

void main() async { // <-- 'async' kelimesi eklendi
  WidgetsFlutterBinding.ensureInitialized(); // <-- Önemli
  await Firebase.initializeApp(); // <-- Firebase başlatılıyor
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LessonViewModel()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Python Öğreniyorum',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const LessonListScreen(),
    );
  }
}