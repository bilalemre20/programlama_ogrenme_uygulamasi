import 'package:cloud_firestore/cloud_firestore.dart';

// 1. SORU MODELİ
class Exercise {
  final String id;
  final String taskDescription;
  final String initialCode;
  final String expectedOutput;

  Exercise({
    required this.id,
    required this.taskDescription,
    required this.initialCode,
    required this.expectedOutput,
  });

  // Veritabanına gönderirken kullanacağız (Exercise için)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'task': taskDescription,
      'code': initialCode,
      'output': expectedOutput,
    };
  }

  factory Exercise.fromMap(Map<String, dynamic> data) {
    return Exercise(
      id: data['id'] ?? '',
      taskDescription: data['task'] ?? '',
      initialCode: data['code'] ?? '',
      expectedOutput: data['output'] ?? '',
    );
  }
}

// 2. DERS MODELİ
class Lesson {
  final String id;
  final String title;
  
  // --- A. İLK KARŞILAŞMA PAKETİ (Detaylı + 4 Soru) ---
  final String initialTheory;          // DETAYLI Konu Anlatımı
  final List<Exercise> initialExercises; // BURADA 4 SORU OLACAK

  // --- B. TEKRAR PAKETİ (Özet + 3 Soru) ---
  final String reviewTheory;           // ÖZET (Hatırlatma)
  final List<Exercise> reviewExercises;  // BURADA 3 SORU OLACAK

  // --- C. YAPAY ZEKA AYARLARI ---
  final String aiPromptTemplate;       // İpucu Promptu
  final String aiSolutionTemplate;     // Çözüm Promptu

  Lesson({
    required this.id,
    required this.title,
    required this.initialTheory,
    required this.initialExercises,
    required this.reviewTheory,
    required this.reviewExercises,
    required this.aiPromptTemplate,
    required this.aiSolutionTemplate,
  });

  // --- İŞTE SORDUĞUN KISIM BURAYA EKLENDİ ---
  // Bu fonksiyon Lesson nesnesini Firebase'in anlayacağı JSON formatına çevirir.
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'initialTheory': initialTheory,
      // Altındaki egzersiz listelerini de tek tek map'e çeviriyoruz:
      'initialExercises': initialExercises.map((e) => e.toMap()).toList(),
      'reviewTheory': reviewTheory,
      'reviewExercises': reviewExercises.map((e) => e.toMap()).toList(),
      'aiHintPrompt': aiPromptTemplate,
      'aiSolutionPrompt': aiSolutionTemplate,
    };
  }
  // ------------------------------------------

  // Firebase'den veri çekerken kullanılacak
  factory Lesson.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // 1. Başlangıç Sorularını Listeye Çevir
    var initList = data['initialExercises'] as List? ?? [];
    List<Exercise> initExercises = initList.map((i) => Exercise.fromMap(i)).toList();

    // 2. Tekrar Sorularını Listeye Çevir
    var revList = data['reviewExercises'] as List? ?? [];
    List<Exercise> revExercises = revList.map((i) => Exercise.fromMap(i)).toList();

    return Lesson(
      id: doc.id,
      title: data['title'] ?? '',
      
      // Veritabanı alan isimleri
      initialTheory: data['initialTheory'] ?? '',
      initialExercises: initExercises,
      
      reviewTheory: data['reviewTheory'] ?? '',
      reviewExercises: revExercises,
      
      aiPromptTemplate: data['aiHintPrompt'] ?? '',
      aiSolutionTemplate: data['aiSolutionPrompt'] ?? '',
    );
  }
}