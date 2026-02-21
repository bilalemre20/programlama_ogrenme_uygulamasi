import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/lesson_model.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- ARTIK BURADA HİÇBİR DERS VERİSİ YOK! ---
  // Uygulama sadece "Bana Firebase'deki verileri ver" diyor.

  Future<List<Lesson>> getLessons() async {
    try {
      // 1. Firebase'e git ve 'lessons' kutusunu aç
      QuerySnapshot snapshot = await _firestore.collection('lessons').get();

      if (snapshot.docs.isNotEmpty) {
        // 2. Gelen verileri listeye çevir
        final list = snapshot.docs.map((doc) => Lesson.fromSnapshot(doc)).toList();
        
        // 3. ID numarasına göre (1, 2, 3...) sıraya diz
        list.sort((a, b) => int.parse(a.id).compareTo(int.parse(b.id)));
        
        print("✅ Veriler Buluttan Çekildi: ${list.length} ders var.");
        return list;
      } else {
        print("⚠️ Veritabanı bomboş!");
        return [];
      }
    } catch (e) {
      print("❌ Hata oluştu: $e");
      return [];
    }
  }
}