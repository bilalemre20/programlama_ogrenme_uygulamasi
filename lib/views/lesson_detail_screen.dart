import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/lesson_model.dart';
import '../viewmodels/lesson_view_model.dart';

class LessonDetailScreen extends StatefulWidget {
  final Lesson lesson;
  final bool isReviewMode; 

  const LessonDetailScreen({
    super.key, 
    required this.lesson,
    this.isReviewMode = false, 
  });

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  late TextEditingController _codeController;
  String _lastExerciseId = ""; 

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController();

    // Ekran açılır açılmaz ViewModel'e dersi yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LessonViewModel>(context, listen: false)
          .loadLesson(widget.lesson, isReview: widget.isReviewMode);
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LessonViewModel>(
      builder: (context, viewModel, child) {
        
        // --- HATA ENGELLEYİCİ KONTROL ---
        // Eğer veri henüz yüklenmediyse dönen top göster (Hata vermez)
        if (!viewModel.isInitialized) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        // ---------------------------------

        // Kod editörünü yeni soruya göre güncelle
        if (viewModel.currentExercise.id != _lastExerciseId) {
          _codeController.text = viewModel.currentExercise.initialCode;
          _lastExerciseId = viewModel.currentExercise.id;
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(widget.lesson.title),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Center(
                  child: Text(
                    "${viewModel.currentExerciseIndex + 1} / ${widget.isReviewMode ? widget.lesson.reviewExercises.length : widget.lesson.initialExercises.length}",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              )
            ],
          ),
          body: Column(
            children: [
              // 1. TEORİ ve GÖREV
              Expanded(
                flex: 3,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Bilgi:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[800])),
                      Text(viewModel.currentTheory),
                      const SizedBox(height: 10),
                      const Divider(),
                      Text("Görev:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange[800])),
                      Text(viewModel.currentExercise.taskDescription, style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 5),
                      Text("Beklenen Çıktı: ${viewModel.currentExercise.expectedOutput}", style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
              ),

              // 2. KOD EDİTÖRÜ
              Expanded(
                flex: 4,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  color: const Color(0xFF2d2d2d),
                  child: TextField(
                    controller: _codeController,
                    maxLines: null,
                    style: const TextStyle(color: Colors.white, fontFamily: 'Courier'),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Kodunu buraya yaz...',
                      hintStyle: TextStyle(color: Colors.white54),
                    ),
                  ),
                ),
              ),

              // 3. KONTROL PANELİ
              Expanded(
                flex: 4,
                child: Container(
                  color: Colors.grey[100],
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: viewModel.isLessonFinished 
                                  ? () => Navigator.pop(context) 
                                  : viewModel.isSuccess
                                      ? () => viewModel.nextExercise() 
                                      : viewModel.isLoading 
                                          ? null 
                                          : () => viewModel.runCode(_codeController.text),
                              icon: viewModel.isLoading 
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                                  : Icon(viewModel.isSuccess ? Icons.arrow_forward : Icons.play_arrow),
                              label: Text(viewModel.isLessonFinished 
                                  ? "DERS BİTTİ" 
                                  : viewModel.isSuccess 
                                      ? "SONRAKİ SORU" 
                                      : "KODU ÇALIŞTIR"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: viewModel.isSuccess ? Colors.blue : Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          if (!viewModel.isSuccess && viewModel.consoleOutput.isNotEmpty && !viewModel.isLoading)
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: IconButton(
                                icon: const Icon(Icons.psychology, size: 32, color: Colors.purple),
                                onPressed: () => viewModel.runCode(_codeController.text),
                                tooltip: "Yapay Zeka Asistanı",
                              ),
                            )
                        ],
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: viewModel.isSuccess ? Colors.green[50] : Colors.red[50],
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  viewModel.consoleOutput.isEmpty ? "Sonuç burada görünecek..." : viewModel.consoleOutput,
                                  style: TextStyle(
                                    fontFamily: 'Courier', 
                                    color: viewModel.isSuccess ? Colors.green[900] : Colors.red[900]
                                  ),
                                ),
                                if (viewModel.isLessonFinished)
                                  const Text("\n🎉 TEBRİKLER! Tüm soruları tamamladın.", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // AI TAVSİYESİ (Varsa göster)
                      if (viewModel.isAiLoading)
                         const LinearProgressIndicator(),
                      
                      if (viewModel.aiAdvice.isNotEmpty)
                        Container(
                          // 1. DÜZELTME: Maksimum yükseklik veriyoruz (Ekranı patlatmasın)
                          constraints: const BoxConstraints(maxHeight: 140), 
                          
                          margin: const EdgeInsets.only(top: 5),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.purple[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.purple.shade200),
                          ),
                          // 2. DÜZELTME: Yazı çok uzunsa kutunun içi kaydırılsın
                          child: SingleChildScrollView( 
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.auto_awesome, size: 16, color: Colors.purple),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    viewModel.aiAdvice, 
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}