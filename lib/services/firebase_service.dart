import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/lesson_model.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- ARTIK KODUN İÇİNDE HİÇBİR VERİ YOK! ---
  // Uygulama sadece ve sadece Firebase'e soracak.

  Future<List<Lesson>> getLessons() async {
    try {
      // Firebase'deki 'lessons' koleksiyonuna git
      QuerySnapshot snapshot = await _firestore.collection('lessons').get();

      if (snapshot.docs.isNotEmpty) {
        // Verileri buldun, listeye çevirip gönder
        print("✅ Veriler Firebase Bulut'tan çekildi!");
        return snapshot.docs.map((doc) => Lesson.fromSnapshot(doc)).toList();
      } else {
        // Eğer veritabanı boşsa boş liste dön (Artık otomatik doldurmuyoruz)
        print("⚠️ Veritabanı boş!");
        return [];
      }
    } catch (e) {
      print("❌ Hata oluştu: $e");
      return [];
    }
  }
  
  // uploadMockData veya _seedDatabase fonksiyonlarını sildik.
  // Çünkü veritabanın artık dolu!
}