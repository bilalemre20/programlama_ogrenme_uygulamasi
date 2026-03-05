import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProgressService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  // --- İLERLEMEYİ OKU ---
  Future<List<String>> getCompletedLessons() async {
    if (_uid == null) return [];
    try {
      final doc = await _firestore.collection('users').doc(_uid).get();
      if (!doc.exists) return [];
      final data = doc.data();
      final completed = data?['completedLessons'] as List? ?? [];
      return completed.map((e) => e.toString()).toList();
    } catch (e) {
      return [];
    }
  }

  // --- PROFİL VERİSİNİ OKU ---
  Future<Map<String, dynamic>> getUserProfile() async {
    if (_uid == null) return {};
    try {
      final doc = await _firestore.collection('users').doc(_uid).get();
      if (!doc.exists) return {};
      return doc.data() ?? {};
    } catch (e) {
      return {};
    }
  }

  // --- DERSİ TAMAMLANDI OLARAK İŞARETLE ---
  Future<void> completeLesson(String lessonId) async {
    if (_uid == null) return;
    try {
      // Streak güncelle
      final profile = await getUserProfile();
      final lastActive = profile['lastActiveDate'] as String?;
      final today = _todayString();
      final yesterday = _yesterdayString();

      int currentStreak = profile['streak'] as int? ?? 0;

      if (lastActive == today) {
        // Bugün zaten aktif, streak değişmez
      } else if (lastActive == yesterday) {
        // Dün aktifti, streak devam ediyor
        currentStreak++;
      } else {
        // Uzun süre gelmemiş, streak sıfırlanıyor
        currentStreak = 1;
      }

      await _firestore.collection('users').doc(_uid).set({
        'completedLessons': FieldValue.arrayUnion([lessonId]),
        'lastActiveDate': today,
        'streak': currentStreak,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('✅ Ders tamamlandı: $lessonId | Streak: $currentStreak');
    } catch (e) {
      print('İlerleme kaydedilemedi: $e');
    }
  }

  // --- BUGÜN GİRİŞ YAPILDI OLARAK İŞARETLE ---
  Future<void> markTodayActive() async {
    if (_uid == null) return;
    try {
      final profile = await getUserProfile();
      final lastActive = profile['lastActiveDate'] as String?;
      final today = _todayString();
      final yesterday = _yesterdayString();

      if (lastActive == today) return; // Zaten işaretlendi

      int currentStreak = profile['streak'] as int? ?? 0;

      if (lastActive == yesterday) {
        currentStreak++;
      } else if (lastActive == null) {
        currentStreak = 1;
      } else {
        currentStreak = 1; // Sıfırla
      }

      await _firestore.collection('users').doc(_uid).set({
        'lastActiveDate': today,
        'streak': currentStreak,
      }, SetOptions(merge: true));
    } catch (e) {
      print('Streak güncellenemedi: $e');
    }
  }

  // --- KULLANICI ADINI GÜNCELLE ---
  Future<void> updateDisplayName(String name) async {
    if (_uid == null) return;
    try {
      await _firestore.collection('users').doc(_uid).set({
        'displayName': name,
      }, SetOptions(merge: true));
    } catch (e) {
      print('İsim güncellenemedi: $e');
    }
  }

  // --- ROZET HESAPLA ---
  List<Map<String, dynamic>> getBadges(
      int completedCount, int streak) {
    final badges = <Map<String, dynamic>>[];

    if (completedCount >= 1) {
      badges.add({
        'icon': '🚀',
        'title': 'İlk Adım',
        'desc': 'İlk dersi tamamladın',
        'unlocked': true,
      });
    } else {
      badges.add({
        'icon': '🚀',
        'title': 'İlk Adım',
        'desc': 'İlk dersi tamamla',
        'unlocked': false,
      });
    }

    if (completedCount >= 3) {
      badges.add({
        'icon': '⚡',
        'title': 'Hızlı Başlangıç',
        'desc': '3 ders tamamladın',
        'unlocked': true,
      });
    } else {
      badges.add({
        'icon': '⚡',
        'title': 'Hızlı Başlangıç',
        'desc': '3 ders tamamla',
        'unlocked': false,
      });
    }

    if (streak >= 3) {
      badges.add({
        'icon': '🔥',
        'title': 'Ateşli',
        'desc': '3 günlük seri yaptın',
        'unlocked': true,
      });
    } else {
      badges.add({
        'icon': '🔥',
        'title': 'Ateşli',
        'desc': '3 gün üst üste giriş yap',
        'unlocked': false,
      });
    }

    if (completedCount >= 5) {
      badges.add({
        'icon': '🏆',
        'title': 'Şampiyon',
        'desc': '5 ders tamamladın',
        'unlocked': true,
      });
    } else {
      badges.add({
        'icon': '🏆',
        'title': 'Şampiyon',
        'desc': '5 ders tamamla',
        'unlocked': false,
      });
    }

    if (streak >= 7) {
      badges.add({
        'icon': '💎',
        'title': 'Kararlı',
        'desc': '7 günlük seri yaptın',
        'unlocked': true,
      });
    } else {
      badges.add({
        'icon': '💎',
        'title': 'Kararlı',
        'desc': '7 gün üst üste giriş yap',
        'unlocked': false,
      });
    }

    return badges;
  }

  // --- HATA KAYDET ---
  Future<void> recordMistake(String lessonId, String lessonTitle) async {
    if (_uid == null) return;
    try {
      final docRef = _firestore.collection('users').doc(_uid);
      final doc = await docRef.get();
      final data = doc.data() ?? {};
      
      // Mevcut hata verisini al
      final mistakes = Map<String, dynamic>.from(data['mistakes'] ?? {});
      final current = Map<String, dynamic>.from(mistakes[lessonId] ?? {});
      
      final count = (current['count'] as int? ?? 0) + 1;
      
      mistakes[lessonId] = {
        'count': count,
        'title': lessonTitle,
        'lastMistake': DateTime.now().toIso8601String(),
      };
      
      await docRef.set({'mistakes': mistakes}, SetOptions(merge: true));
    } catch (e) {
      print('Hata kaydedilemedi: \$e');
    }
  }

  // --- HATA VERİSİNİ OKU ---
  Future<List<Map<String, dynamic>>> getMistakes() async {
    if (_uid == null) return [];
    try {
      final doc = await _firestore.collection('users').doc(_uid).get();
      if (!doc.exists) return [];
      final data = doc.data() ?? {};
      final mistakes = Map<String, dynamic>.from(data['mistakes'] ?? {});
      
      final list = mistakes.entries.map((e) {
        final val = Map<String, dynamic>.from(e.value);
        return {
          'lessonId': e.key,
          'title': val['title'] ?? 'Bilinmeyen Ders',
          'count': val['count'] ?? 0,
          'lastMistake': val['lastMistake'] ?? '',
        };
      }).toList();
      
      // En çok hata yapılandan en aza sırala
      list.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
      return list;
    } catch (e) {
      print('Hatalar okunamadı: \$e');
      return [];
    }
  }

  // --- ONBOARDING KAYDET ---
  Future<void> saveOnboarding({
    required String ageRange,
    required String level,
  }) async {
    if (_uid == null) return;
    try {
      await _firestore.collection('users').doc(_uid).set({
        'ageRange': ageRange,
        'level': level,
        'onboardingDone': true,
      }, SetOptions(merge: true));
    } catch (e) {
      print('Onboarding kaydedilemedi: \$e');
    }
  }

  // --- ONBOARDING TAMAMLANDI MI? ---
  Future<bool> isOnboardingDone() async {
    if (_uid == null) return false;
    try {
      final doc = await _firestore.collection('users').doc(_uid).get();
      if (!doc.exists) return false;
      return doc.data()?['onboardingDone'] == true;
    } catch (e) {
      return false;
    }
  }

  String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  String _yesterdayString() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
  }
}