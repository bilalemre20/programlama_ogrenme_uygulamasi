import 'package:flutter/material.dart';
import '../models/lesson_model.dart';
import '../services/api_service.dart';
import '../services/progress_service.dart';

class LessonViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final ProgressService _progressService = ProgressService();

  // --- DURUM DEĞİŞKENLERİ ---
  bool isLoading = false;
  bool isAiLoading = false;
  String consoleOutput = "";
  String aiAdvice = "";
  bool isSuccess = false;
  bool isInitialized = false;

  // İlerleyiş Değişkenleri
  int attemptCount = 0;
  int currentExerciseIndex = 0;
  bool isReviewMode = false;
  bool isLessonFinished = false;

  late Lesson _currentLesson;

  // --- 1. DERSİ YÜKLEME ---
  void loadLesson(Lesson lesson, {bool isReview = false}) {
    _currentLesson = lesson;
    isReviewMode = isReview;
    currentExerciseIndex = 0;
    attemptCount = 0;
    isLessonFinished = false;
    isSuccess = false;
    consoleOutput = "";
    aiAdvice = "";
    isInitialized = true;
    notifyListeners();
  }

  // --- GETTER: AKTİF SORU ---
  Exercise get currentExercise {
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

  // --- GETTER: AKTİF KONU ANLATIMI ---
  String get currentTheory {
    if (!isInitialized) return "";
    return isReviewMode ? _currentLesson.reviewTheory : _currentLesson.initialTheory;
  }

  // --- 2. KODU ÇALIŞTIRMA ---
  Future<void> runCode(String userCode) async {
    isLoading = true;
    consoleOutput = "Kod gönderiliyor...";
    isSuccess = false;
    aiAdvice = "";
    notifyListeners();

    try {
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

  // --- BAŞARISIZLIK SENARYOSU ---
  Future<void> _handleFailure(String userCode, String errorMsg) async {
    isSuccess = false;
    attemptCount++;

    // Hata parmak izini kaydet
    _progressService.recordMistake(_currentLesson.id, _currentLesson.title);

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
    notifyListeners();
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