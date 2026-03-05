import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/lesson_model.dart';
import 'progress_service.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ProgressService _progressService = ProgressService();

  // Kullanıcının yaş aralığını Firestore'dan çek
  Future<String> _getUserAgeRange() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return '18-25';
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data()?['ageRange'] ?? '18-25';
    } catch (e) {
      return '18-25';
    }
  }

  Future<List<Lesson>> getLessons() async {
    try {
      final ageRange = await _getUserAgeRange();
      print('Yaş aralığı: $ageRange');

      // Yaşa göre doğru koleksiyondan çek
      QuerySnapshot snapshot = await _firestore
          .collection('lessons')
          .doc(ageRange)
          .collection('dersler')
          .get();

      // Eğer yaşa özel ders yoksa genel 'lessons' koleksiyonuna düş
      if (snapshot.docs.isEmpty) {
        print('Yaşa özel ders bulunamadı, genel dersler yükleniyor...');
        snapshot = await _firestore.collection('lessons').get();
      }

      if (snapshot.docs.isNotEmpty) {
        // Sadece sayısal ID'li dökümanları al (yaş grubu dökümanlarını atla)
        final list = snapshot.docs
            .where((doc) => int.tryParse(doc.id) != null)
            .map((doc) => Lesson.fromSnapshot(doc))
            .toList();
        list.sort((a, b) {
          final aNum = int.tryParse(a.id) ?? 0;
          final bNum = int.tryParse(b.id) ?? 0;
          return aNum.compareTo(bNum);
        });
        print('Dersler yüklendi: ${list.length} ders (yaş: $ageRange)');
        return list;
      } else {
        print('Veritabanı boş!');
        return [];
      }
    } catch (e) {
      print('Hata: $e');
      return [];
    }
  }
}