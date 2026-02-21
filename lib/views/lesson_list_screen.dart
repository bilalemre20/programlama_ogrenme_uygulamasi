import 'package:flutter/material.dart';
import '../models/lesson_model.dart';
import '../services/firebase_service.dart';
import 'lesson_detail_screen.dart';

class LessonListScreen extends StatefulWidget {
  const LessonListScreen({super.key});

  @override
  State<LessonListScreen> createState() => _LessonListScreenState();
}

class _LessonListScreenState extends State<LessonListScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Python Dersleri"),
      ),
      body: FutureBuilder<List<Lesson>>(
        future: _firebaseService.getLessons(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Hata: ${snapshot.error}"));
          }

          final lessons = snapshot.data ?? [];

          if (lessons.isEmpty) {
            return const Center(child: Text("Ders bulunamadı."));
          }

          return ListView.builder(
            itemCount: lessons.length,
            itemBuilder: (context, index) {
              return Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text(lessons[index].id)),
                  title: Text(lessons[index].title),
                  subtitle: const Text("Başlamak için dokun"),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LessonDetailScreen(lesson: lessons[index]),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}