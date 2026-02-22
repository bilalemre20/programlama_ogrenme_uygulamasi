import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/lesson_view_model.dart';
import '../viewmodels/theme_view_model.dart';

class LessonDetailScreen extends StatefulWidget {
  const LessonDetailScreen({super.key});

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen>
    with SingleTickerProviderStateMixin {
  late TextEditingController _codeController;
  late AnimationController _fadeController;
  bool _theoryVisible = true;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400))
      ..forward();
    final vm = context.read<LessonViewModel>();
    _codeController =
        TextEditingController(text: vm.currentExercise.initialCode);
  }

  @override
  void dispose() {
    _codeController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _onExerciseChanged(LessonViewModel vm) {
    _codeController.text = vm.currentExercise.initialCode;
    _fadeController.forward(from: 0);
    setState(() => _theoryVisible = false);
  }

  @override
  Widget build(BuildContext context) {
    final themeVM = context.watch<ThemeViewModel>();
    final isDark = themeVM.isDark;

    // Tema renkleri
    final bgColor =
        isDark ? const Color(0xFF0F0F1A) : const Color(0xFFF0F0FF);
    final cardBg = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final editorBg = isDark ? const Color(0xFF12121F) : const Color(0xFFF8F8FF);
    final terminalBg =
        isDark ? const Color(0xFF0A0A14) : const Color(0xFFF0F0F8);
    final titleColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final bodyColor = isDark
        ? Colors.white.withOpacity(0.75)
        : const Color(0xFF1A1A2E).withOpacity(0.75);
    final borderColor = isDark
        ? Colors.white.withOpacity(0.06)
        : Colors.black.withOpacity(0.06);

    return Consumer<LessonViewModel>(
      builder: (context, vm, _) {
        if (vm.isLessonFinished) {
          return _FinishedScreen(isDark: isDark, onBack: () => Navigator.pop(context));
        }

        return Scaffold(
          backgroundColor: bgColor,
          body: SafeArea(
            child: Column(
              children: [
                // ── TOP BAR ────────────────────────────────────────
                _TopBar(vm: vm, isDark: isDark, titleColor: titleColor),

                // ── CONTENT ────────────────────────────────────────
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeController,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Konu Anlatımı
                          _TheoryCard(
                            theory: vm.currentTheory,
                            isVisible: _theoryVisible,
                            isDark: isDark,
                            cardBg: cardBg,
                            bodyColor: bodyColor,
                            onToggle: () => setState(
                                () => _theoryVisible = !_theoryVisible),
                          ),
                          const SizedBox(height: 14),

                          // Görev
                          _TaskCard(
                            task: vm.currentExercise.taskDescription,
                            isDark: isDark,
                            cardBg: cardBg,
                          ),
                          const SizedBox(height: 14),

                          // Kod Editörü
                          _CodeEditor(
                            controller: _codeController,
                            isDark: isDark,
                            editorBg: editorBg,
                            borderColor: borderColor,
                          ),
                          const SizedBox(height: 14),

                          // Çalıştır
                          _RunButton(
                            isLoading: vm.isLoading,
                            onRun: () => vm.runCode(_codeController.text),
                          ),
                          const SizedBox(height: 14),

                          // Konsol
                          if (vm.consoleOutput.isNotEmpty)
                            _ConsoleOutput(
                              output: vm.consoleOutput,
                              isSuccess: vm.isSuccess,
                              isDark: isDark,
                              terminalBg: terminalBg,
                            ),

                          // AI Tavsiye
                          if (vm.isAiLoading || vm.aiAdvice.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            _AiAdviceCard(
                              isLoading: vm.isAiLoading,
                              advice: vm.aiAdvice,
                              attemptCount: vm.attemptCount,
                              bodyColor: bodyColor,
                            ),
                          ],
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── SONRAKİ BUTON ───────────────────────────────────
                if (vm.isSuccess)
                  _NextButton(
                    isDark: isDark,
                    onNext: () {
                      vm.nextExercise();
                      _onExerciseChanged(vm);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── TOP BAR ────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final LessonViewModel vm;
  final bool isDark;
  final Color titleColor;
  const _TopBar(
      {required this.vm, required this.isDark, required this.titleColor});

  @override
  Widget build(BuildContext context) {
    final barBg = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final borderCol = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.08);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: barBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderCol),
              ),
              child: Icon(Icons.arrow_back_ios_new_rounded,
                  color: titleColor, size: 16),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vm.isReviewMode ? '🔄 Tekrar Modu' : '📘 Ders',
                  style: TextStyle(
                    color: titleColor.withOpacity(0.4),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Soru ${vm.currentExerciseIndex + 1}',
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (vm.attemptCount > 0)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: vm.attemptCount >= 3
                    ? const Color(0xFFFF6584).withOpacity(0.12)
                    : const Color(0xFFFFBF69).withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: vm.attemptCount >= 3
                      ? const Color(0xFFFF6584).withOpacity(0.4)
                      : const Color(0xFFFFBF69).withOpacity(0.4),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.favorite_rounded,
                      size: 12,
                      color: vm.attemptCount >= 3
                          ? const Color(0xFFFF6584)
                          : const Color(0xFFFFBF69)),
                  const SizedBox(width: 4),
                  Text(
                    '${vm.attemptCount} deneme',
                    style: TextStyle(
                      color: vm.attemptCount >= 3
                          ? const Color(0xFFFF6584)
                          : const Color(0xFFFFBF69),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── KONU ANLATIMI ──────────────────────────────────────────────────
class _TheoryCard extends StatelessWidget {
  final String theory;
  final bool isVisible;
  final bool isDark;
  final Color cardBg;
  final Color bodyColor;
  final VoidCallback onToggle;

  const _TheoryCard({
    required this.theory,
    required this.isVisible,
    required this.isDark,
    required this.cardBg,
    required this.bodyColor,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: const Color(0xFF6C63FF).withOpacity(0.25)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C63FF)
                  .withOpacity(isDark ? 0.05 : 0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.menu_book_rounded,
                        color: Color(0xFF6C63FF), size: 16),
                  ),
                  const SizedBox(width: 10),
                  const Text('Konu Anlatımı',
                      style: TextStyle(
                          color: Color(0xFF6C63FF),
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                  const Spacer(),
                  AnimatedRotation(
                    turns: isVisible ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(Icons.keyboard_arrow_down_rounded,
                        color: bodyColor.withOpacity(0.5)),
                  ),
                ],
              ),
            ),
            if (isVisible)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(theory,
                    style: TextStyle(
                        color: bodyColor, fontSize: 13.5, height: 1.65)),
              ),
          ],
        ),
      ),
    );
  }
}

// ── GÖREV KARTI ────────────────────────────────────────────────────
class _TaskCard extends StatelessWidget {
  final String task;
  final bool isDark;
  final Color cardBg;
  const _TaskCard(
      {required this.task, required this.isDark, required this.cardBg});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white.withOpacity(0.85) : const Color(0xFF1A1A2E);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(0xFF00C6AE).withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00C6AE)
                .withOpacity(isDark ? 0.05 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF00C6AE).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.assignment_rounded,
                    color: Color(0xFF00C6AE), size: 16),
              ),
              const SizedBox(width: 10),
              const Text('Görev',
                  style: TextStyle(
                      color: Color(0xFF00C6AE),
                      fontWeight: FontWeight.w700,
                      fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          Text(task,
              style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  height: 1.6,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ── KOD EDİTÖRÜ ────────────────────────────────────────────────────
class _CodeEditor extends StatelessWidget {
  final TextEditingController controller;
  final bool isDark;
  final Color editorBg;
  final Color borderColor;

  const _CodeEditor({
    required this.controller,
    required this.isDark,
    required this.editorBg,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final headerBg = isDark
        ? Colors.white.withOpacity(0.04)
        : Colors.black.withOpacity(0.03);
    final labelColor = isDark
        ? Colors.white.withOpacity(0.35)
        : Colors.black.withOpacity(0.3);
    final codeColor =
        isDark ? const Color(0xFFA78BFA) : const Color(0xFF5B52CC);

    return Container(
      decoration: BoxDecoration(
        color: editorBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: headerBg,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                _dot(const Color(0xFFFF5F57)),
                const SizedBox(width: 6),
                _dot(const Color(0xFFFFBD2E)),
                const SizedBox(width: 6),
                _dot(const Color(0xFF28CA41)),
                const SizedBox(width: 12),
                Text('main.py',
                    style: TextStyle(
                        color: labelColor,
                        fontSize: 12,
                        fontFamily: 'monospace')),
                const Spacer(),
                Icon(Icons.edit_rounded, color: labelColor, size: 14),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: controller,
              maxLines: null,
              style: TextStyle(
                color: codeColor,
                fontFamily: 'monospace',
                fontSize: 13.5,
                height: 1.7,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: '# Kodunu buraya yaz...',
                hintStyle: TextStyle(
                  color: isDark
                      ? Colors.white.withOpacity(0.18)
                      : Colors.black.withOpacity(0.2),
                  fontFamily: 'monospace',
                  fontSize: 13,
                ),
              ),
              cursorColor: const Color(0xFF6C63FF),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(Color color) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

// ── ÇALIŞTIR BUTONU ────────────────────────────────────────────────
class _RunButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback onRun;
  const _RunButton({required this.isLoading, required this.onRun});

  @override
  State<_RunButton> createState() => _RunButtonState();
}

class _RunButtonState extends State<_RunButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:
          widget.isLoading ? null : (_) => setState(() => _pressed = true),
      onTapUp: widget.isLoading
          ? null
          : (_) {
              setState(() => _pressed = false);
              widget.onRun();
            },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.isLoading
                  ? [Colors.grey.shade600, Colors.grey.shade700]
                  : [const Color(0xFF00C6AE), const Color(0xFF009E8E)],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: widget.isLoading
                ? []
                : [
                    const BoxShadow(
                      color: Color(0x4400C6AE),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.isLoading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
              else
                const Icon(Icons.play_arrow_rounded,
                    color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Text(
                widget.isLoading ? 'Çalışıyor...' : 'KODU ÇALIŞTIR',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    letterSpacing: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── KONSOL ÇIKTISI ─────────────────────────────────────────────────
class _ConsoleOutput extends StatelessWidget {
  final String output;
  final bool isSuccess;
  final bool isDark;
  final Color terminalBg;

  const _ConsoleOutput({
    required this.output,
    required this.isSuccess,
    required this.isDark,
    required this.terminalBg,
  });

  @override
  Widget build(BuildContext context) {
    final accent =
        isSuccess ? const Color(0xFF00C6AE) : const Color(0xFFFF6584);
    final textColor = isDark
        ? Colors.white.withOpacity(0.8)
        : const Color(0xFF1A1A2E).withOpacity(0.8);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: terminalBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.terminal_rounded, size: 14, color: accent),
              const SizedBox(width: 6),
              Text(
                isSuccess ? '✓  Doğru!' : '✗  Yanlış',
                style: TextStyle(
                    color: accent, fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(output,
              style: TextStyle(
                  color: textColor,
                  fontFamily: 'monospace',
                  fontSize: 13,
                  height: 1.6)),
        ],
      ),
    );
  }
}

// ── AI TAVSİYE ─────────────────────────────────────────────────────
class _AiAdviceCard extends StatelessWidget {
  final bool isLoading;
  final String advice;
  final int attemptCount;
  final Color bodyColor;

  const _AiAdviceCard({
    required this.isLoading,
    required this.advice,
    required this.attemptCount,
    required this.bodyColor,
  });

  @override
  Widget build(BuildContext context) {
    final isSolution = attemptCount >= 3;
    final color =
        isSolution ? const Color(0xFFFF6584) : const Color(0xFF6C63FF);
    final label = isSolution ? '🔓  Çözüm' : '💡  Yapay Zeka İpucu';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                    isSolution
                        ? Icons.lock_open_rounded
                        : Icons.auto_awesome_rounded,
                    color: color,
                    size: 16),
              ),
              const SizedBox(width: 10),
              Text(label,
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 14)),
              if (isLoading) ...[
                const Spacer(),
                SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        color: color, strokeWidth: 2)),
              ],
            ],
          ),
          if (!isLoading && advice.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(advice,
                style:
                    TextStyle(color: bodyColor, fontSize: 13.5, height: 1.65)),
          ],
          if (isLoading) ...[
            const SizedBox(height: 12),
            Text('Yapay zeka düşünüyor...',
                style: TextStyle(
                    color: bodyColor.withOpacity(0.5), fontSize: 13)),
          ],
        ],
      ),
    );
  }
}

// ── SONRAKI BUTON ──────────────────────────────────────────────────
class _NextButton extends StatelessWidget {
  final bool isDark;
  final VoidCallback onNext;
  const _NextButton({required this.isDark, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F0F1A) : const Color(0xFFF0F0FF),
        border: Border(
            top: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.06)
                    : Colors.black.withOpacity(0.06))),
      ),
      child: GestureDetector(
        onTap: onNext,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF5752D1)]),
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x446C63FF),
                  blurRadius: 20,
                  offset: Offset(0, 8)),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Sonraki Soru',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15)),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward_rounded,
                  color: Colors.white, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

// ── DERS BİTİŞ EKRANI ──────────────────────────────────────────────
class _FinishedScreen extends StatelessWidget {
  final bool isDark;
  final VoidCallback onBack;
  const _FinishedScreen({required this.isDark, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final bgColor =
        isDark ? const Color(0xFF0F0F1A) : const Color(0xFFF0F0FF);
    final titleColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final subtitleColor = isDark
        ? Colors.white.withOpacity(0.5)
        : const Color(0xFF1A1A2E).withOpacity(0.5);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF6C63FF), Color(0xFF00C6AE)]),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x556C63FF),
                          blurRadius: 30,
                          offset: Offset(0, 12)),
                    ],
                  ),
                  child: const Icon(Icons.emoji_events_rounded,
                      color: Colors.white, size: 52),
                ),
                const SizedBox(height: 28),
                Text('Harika! 🎉',
                    style: TextStyle(
                        color: titleColor,
                        fontSize: 32,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                Text(
                  'Bu dersteki tüm soruları\nbaşarıyla tamamladın!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: subtitleColor, fontSize: 16, height: 1.6),
                ),
                const SizedBox(height: 40),
                GestureDetector(
                  onTap: onBack,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [
                        Color(0xFF6C63FF),
                        Color(0xFF5752D1),
                      ]),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(
                            color: Color(0x446C63FF),
                            blurRadius: 20,
                            offset: Offset(0, 8)),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.home_rounded,
                            color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text('Ders Listesine Dön',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 15)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}