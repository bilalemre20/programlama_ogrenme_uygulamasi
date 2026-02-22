import 'package:flutter/material.dart';
import '../models/lesson_model.dart';
import '../services/api_service.dart';

class LessonViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  // --- DURUM DEĞİŞKENLERİ (STATE) ---
  bool isLoading = false;       // Kod çalışıyor mu?
  bool isAiLoading = false;     // Yapay zeka düşünüyor mu?
  String consoleOutput = "";    // Ekrana basılacak sonuç
  String aiAdvice = "";         // AI'dan gelen mesaj
  bool isSuccess = false;       // O anki soru doğru yapıldı mı?
  
  // YENİ EKLENEN KRİTİK DEĞİŞKEN:
  bool isInitialized = false;   // Ders verisi yüklendi mi? (Hata engelleyici)

  // İlerleyiş Değişkenleri
  int attemptCount = 0;         // Kaç kere denedi?
  int currentExerciseIndex = 0; // Şu an kaçıncı sorudayız?
  bool isReviewMode = false;    // Tekrar modunda mıyız?
  bool isLessonFinished = false; // Tüm sorular bitti mi?
  
  late Lesson _currentLesson;   // Şu an işlenen ders objesi

  // --- 1. DERSİ YÜKLEME VE BAŞLATMA ---
  void loadLesson(Lesson lesson, {bool isReview = false}) {
    _currentLesson = lesson;
    isReviewMode = isReview;
    
    // Veriler sıfırlanıyor
    currentExerciseIndex = 0;
    attemptCount = 0;
    isLessonFinished = false;
    isSuccess = false;
    consoleOutput = "";
    aiAdvice = "";
    
    // ARTIK VERİ HAZIR DİYORUZ:
    isInitialized = true;
    
    notifyListeners();
  }

  // --- GETTER: ŞU ANKİ AKTİF SORUYU GETİR ---
  Exercise get currentExercise {
    // Güvenlik: Eğer veri yüklenmediyse boş bir nesne döndür (Çökmemesi için)
    if (!isInitialized) {
      return Exercise(id: '', taskDescription: '', initialCode: '', expectedOutput: '');
    }

    List<Exercise> activeList = isReviewMode 
        ? _currentLesson.reviewExercises 
        : _currentLesson.initialExercises;
        
    if (currentExerciseIndex >= activeList.length) {
      return activeList.last;
    }
    return activeList[currentExerciseIndex];
  }

  // --- GETTER: ŞU ANKİ AKTİF KONU ANLATIMINI GETİR ---
  String get currentTheory {
    if (!isInitialized) return "";
    return isReviewMode ? _currentLesson.reviewTheory : _currentLesson.initialTheory;
  }

  // --- 2. KODU ÇALIŞTIRMA MANTIĞI ---
  Future<void> runCode(String userCode) async {
    isLoading = true;
    consoleOutput = "Kod gönderiliyor...";
    isSuccess = false;
    aiAdvice = ""; 
    notifyListeners();

    try {
      // Judge0'a kodu gönder (Python ID: 71)
      final result = await _apiService.executeCode(userCode, 71);
      
      String finalOutput = "";
      if (result['stdout'] != null) {
        finalOutput = result['stdout'];
      } else if (result['stderr'] != null) {
        finalOutput = "HATA:\n${result['stderr']}";
      } else if (result['compile_output'] != null) {
        finalOutput = "DERLEME HATASI:\n${result['compile_output']}";
      }

      consoleOutput = finalOutput;

      // DOĞRULUK KONTROLÜ
      if (finalOutput.trim() == currentExercise.expectedOutput.trim()) {
        _handleSuccess();
      } else {
        await _handleFailure(userCode, finalOutput);
      }

    } catch (e) {
      consoleOutput = "Sistem Hatası: $e";
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // --- BAŞARI SENARYOSU ---
  void _handleSuccess() {
    isSuccess = true;
    attemptCount = 0; 
    aiAdvice = "Harika! Doğru cevap. 🎉 Sonraki soruya geçebilirsin.";
  }

  // --- BAŞARISIZLIK SENARYOSU (3 HAK KURALI) ---
  Future<void> _handleFailure(String userCode, String errorMsg) async {
    isSuccess = false;
    attemptCount++; 

    // GEÇICI TEST LOGLARI
    print('=== HATA SENARYOSU ===');
    print('Deneme sayısı: $attemptCount');
    print('AI Prompt Template: ${_currentLesson.aiPromptTemplate}');
    print('AI Solution Template: ${_currentLesson.aiSolutionTemplate}');
    print('Hata mesajı: $errorMsg');

    isAiLoading = true;
    notifyListeners();

    String promptTemplate;
    
    if (attemptCount < 3) {
      promptTemplate = _currentLesson.aiPromptTemplate;
    } else {
      promptTemplate = _currentLesson.aiSolutionTemplate;
    }

    aiAdvice = await _apiService.getAiHelp(promptTemplate, userCode, errorMsg);
    isAiLoading = false;
    notifyListeners(); // AI cevabı gelince ekranı güncelle
  }

  // --- 3. SONRAKİ SORUYA GEÇİŞ ---
  void nextExercise() {
    List<Exercise> activeList = isReviewMode 
        ? _currentLesson.reviewExercises 
        : _currentLesson.initialExercises;

    if (currentExerciseIndex < activeList.length - 1) {
      currentExerciseIndex++;
      isSuccess = false;
      consoleOutput = "";
      aiAdvice = "";
      attemptCount = 0;
    } else {
      isLessonFinished = true;
    }
    notifyListeners();
  }
}