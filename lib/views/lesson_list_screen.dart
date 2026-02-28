import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/lesson_model.dart';
import '../services/firebase_service.dart';
import '../services/progress_service.dart';
import '../viewmodels/lesson_view_model.dart';
import '../viewmodels/theme_view_model.dart';
import '../viewmodels/auth_view_model.dart';
import 'lesson_detail_screen.dart';
import 'profile_screen.dart';

class LessonListScreen extends StatefulWidget {
  const LessonListScreen({super.key});

  @override
  State<LessonListScreen> createState() => _LessonListScreenState();
}

class _LessonListScreenState extends State<LessonListScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  final ProgressService _progressService = ProgressService();
  List<Lesson> _lessons = [];
  List<String> _completedLessons = [];
  bool _isLoading = true;
  late AnimationController _animController;

  final List<Color> _cardColors = [
    const Color(0xFF6C63FF),
    const Color(0xFF00C6AE),
    const Color(0xFFFF6584),
    const Color(0xFFFFBF69),
    const Color(0xFF43CBFF),
    const Color(0xFFA78BFA),
    const Color(0xFFFF9A3C),
    const Color(0xFF56CFE1),
  ];

  final List<IconData> _cardIcons = [
    Icons.rocket_launch_rounded,
    Icons.data_object_rounded,
    Icons.account_tree_rounded,
    Icons.loop_rounded,
    Icons.format_list_bulleted_rounded,
    Icons.functions_rounded,
    Icons.code_rounded,
    Icons.auto_awesome_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _loadData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final lessons = await _firebaseService.getLessons();
    final completed = await _progressService.getCompletedLessons();
    if (!mounted) return;
    setState(() {
      _lessons = lessons;
      _completedLessons = completed;
      _isLoading = false;
    });
    _animController.forward(from: 0);
  }

  Color _getColor(int index) => _cardColors[index % _cardColors.length];
  IconData _getIcon(int index) => _cardIcons[index % _cardIcons.length];

  // Ders kilitli mi?
  bool _isLocked(int index) {
    if (index == 0) return false; // İlk ders her zaman açık
    final previousLesson = _lessons[index - 1];
    return !_completedLessons.contains(previousLesson.id);
  }

  // Ders tamamlandı mı?
  bool _isCompleted(String lessonId) => _completedLessons.contains(lessonId);

  @override
  Widget build(BuildContext context) {
    final themeVM = context.watch<ThemeViewModel>();
    final isDark = themeVM.isDark;
    final authVM = context.read<AuthViewModel>();

    final bgColor =
        isDark ? const Color(0xFF0F0F1A) : const Color(0xFFF0F0FF);
    final titleColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final subtitleColor = isDark
        ? Colors.white.withOpacity(0.45)
        : const Color(0xFF1A1A2E).withOpacity(0.45);
    final headerGrad = isDark
        ? [const Color(0xFF1A1A2E), const Color(0xFF0F0F1A)]
        : [const Color(0xFFE8E8FF), const Color(0xFFF0F0FF)];

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        slivers: [
          // ── HEADER ───────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: bgColor,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: headerGrad,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -40,
                      right: -40,
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(colors: [
                            const Color(0xFF6C63FF).withOpacity(0.2),
                            Colors.transparent,
                          ]),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -20,
                      left: -20,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(colors: [
                            const Color(0xFF00C6AE).withOpacity(0.15),
                            Colors.transparent,
                          ]),
                        ),
                      ),
                    ),
                    // Tema toggle + Çıkış butonu
                    Positioned(
                      top: 52,
                      right: 16,
                      child: Row(
                        children: [
                          _ThemeToggle(isDark: isDark, themeVM: themeVM),
                        ],
                      ),
                    ),
                    // Başlık
                    Positioned(
                      bottom: 24,
                      left: 20,
                      right: 120,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [
                                Color(0xFF6C63FF),
                                Color(0xFF43CBFF),
                              ]),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              '</>  CodeLearn',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Python\nDersleri',
                            style: TextStyle(
                              color: titleColor,
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _isLoading
                                ? 'Dersler yükleniyor...'
                                : '${_completedLessons.length}/${_lessons.length} ders tamamlandı',
                            style: TextStyle(
                                color: subtitleColor, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── İLERLEME ÇUBUĞU ─────────────────────────────────────
          if (!_isLoading && _lessons.isNotEmpty)
            SliverToBoxAdapter(
              child: _ProgressBar(
                completed: _completedLessons.length,
                total: _lessons.length,
                isDark: isDark,
              ),
            ),

          // ── İÇERİK ───────────────────────────────────────────────
          if (_isLoading)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                        color: Color(0xFF6C63FF), strokeWidth: 2.5),
                    const SizedBox(height: 16),
                    Text('Dersler yükleniyor...',
                        style:
                            TextStyle(color: subtitleColor, fontSize: 13)),
                  ],
                ),
              ),
            )
          else if (_lessons.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_off_rounded,
                        color: subtitleColor, size: 48),
                    const SizedBox(height: 12),
                    Text('Henüz ders bulunamadı.',
                        style:
                            TextStyle(color: subtitleColor, fontSize: 14)),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _loadData,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF6C63FF).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color(0xFF6C63FF)
                                  .withOpacity(0.4)),
                        ),
                        child: const Text('Tekrar Dene',
                            style: TextStyle(
                                color: Color(0xFF6C63FF),
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final lesson = _lessons[index];
                    final color = _getColor(index);
                    final icon = _getIcon(index);
                    final locked = _isLocked(index);
                    final completed = _isCompleted(lesson.id);
                    final delay = (index * 0.08).clamp(0.0, 0.8);

                    return AnimatedBuilder(
                      animation: _animController,
                      builder: (context, child) {
                        final raw = (_animController.value - delay) /
                            (1.0 - delay);
                        final t = Curves.easeOutCubic
                            .transform(raw.clamp(0.0, 1.0));
                        return Opacity(
                          opacity: t,
                          child: Transform.translate(
                            offset: Offset(0, 32 * (1 - t)),
                            child: child,
                          ),
                        );
                      },
                      child: _LessonCard(
                        lesson: lesson,
                        index: index,
                        color: color,
                        icon: icon,
                        isDark: isDark,
                        locked: locked,
                        completed: completed,
                        onTap: locked
                            ? () => _showLockedMessage(context, isDark)
                            : () async {
                                final vm = context.read<LessonViewModel>();
                                vm.loadLesson(lesson);
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ChangeNotifierProvider.value(
                                      value: vm,
                                      child: LessonDetailScreen(
                                        onLessonComplete: () async {
                                          await _progressService
                                              .completeLesson(lesson.id);
                                          await _loadData();
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              },
                      ),
                    );
                  },
                  childCount: _lessons.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showLockedMessage(BuildContext context, bool isDark) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.lock_rounded, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Text('Önceki dersi tamamlaman gerekiyor!'),
          ],
        ),
        backgroundColor: const Color(0xFFFF6584),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

// ── İLERLEME ÇUBUĞU ────────────────────────────────────────────────
class _ProgressBar extends StatelessWidget {
  final int completed;
  final int total;
  final bool isDark;

  const _ProgressBar({
    required this.completed,
    required this.total,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : completed / total;
    final bgColor = isDark
        ? Colors.white.withOpacity(0.06)
        : Colors.black.withOpacity(0.06);
    final textColor = isDark
        ? Colors.white.withOpacity(0.5)
        : Colors.black.withOpacity(0.4);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Genel İlerleme',
                style: TextStyle(
                    color: textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
              ),
              Text(
                '%${(progress * 100).toInt()}',
                style: const TextStyle(
                    color: Color(0xFF6C63FF),
                    fontSize: 12,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: bgColor,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF6C63FF),
              ),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

// ── ÇIKIŞ BUTONU ───────────────────────────────────────────────────
class _LogoutButton extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;
  const _LogoutButton({required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 32,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.black.withOpacity(0.06),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.08),
          ),
        ),
        child: Icon(
          Icons.logout_rounded,
          size: 16,
          color: isDark
              ? Colors.white.withOpacity(0.5)
              : Colors.black.withOpacity(0.4),
        ),
      ),
    );
  }
}

// ── TEMA TOGGLE ────────────────────────────────────────────────────
class _ThemeToggle extends StatelessWidget {
  final bool isDark;
  final ThemeViewModel themeVM;
  const _ThemeToggle({required this.isDark, required this.themeVM});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: themeVM.toggleTheme,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 60,
        height: 32,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isDark
              ? const Color(0xFF6C63FF).withOpacity(0.25)
              : Colors.white.withOpacity(0.85),
          border: Border.all(
            color: isDark
                ? const Color(0xFF6C63FF).withOpacity(0.5)
                : const Color(0xFF6C63FF).withOpacity(0.25),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C63FF)
                  .withOpacity(isDark ? 0.3 : 0.1),
              blurRadius: 12,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              left: 7,
              child: Icon(Icons.wb_sunny_rounded,
                  size: 13,
                  color: isDark
                      ? Colors.white.withOpacity(0.2)
                      : const Color(0xFFFFBF69)),
            ),
            Positioned(
              right: 7,
              child: Icon(Icons.nightlight_round,
                  size: 13,
                  color: isDark
                      ? const Color(0xFF9B97FF)
                      : Colors.black.withOpacity(0.15)),
            ),
            AnimatedAlign(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              alignment:
                  isDark ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            const Color(0xFF6C63FF),
                            const Color(0xFF9B97FF)
                          ]
                        : [
                            const Color(0xFFFFBF69),
                            const Color(0xFFFFD89B)
                          ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? const Color(0xFF6C63FF).withOpacity(0.6)
                          : const Color(0xFFFFBF69).withOpacity(0.5),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ── PROFİL BUTONU ──────────────────────────────────────────────────
class _ProfileButton extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;
  const _ProfileButton({required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 32,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.black.withOpacity(0.06),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.08),
          ),
        ),
        child: Icon(
          Icons.person_rounded,
          size: 16,
          color: isDark
              ? Colors.white.withOpacity(0.5)
              : Colors.black.withOpacity(0.4),
        ),
      ),
    );
  }
}

// ── DERS KARTI ─────────────────────────────────────────────────────
class _LessonCard extends StatefulWidget {
  final Lesson lesson;
  final int index;
  final Color color;
  final IconData icon;
  final bool isDark;
  final bool locked;
  final bool completed;
  final VoidCallback onTap;

  const _LessonCard({
    required this.lesson,
    required this.index,
    required this.color,
    required this.icon,
    required this.isDark,
    required this.locked,
    required this.completed,
    required this.onTap,
  });

  @override
  State<_LessonCard> createState() => _LessonCardState();
}

class _LessonCardState extends State<_LessonCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final cardBg = widget.isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final titleColor =
        widget.isDark ? Colors.white : const Color(0xFF1A1A2E);
    final subtitleColor = widget.isDark
        ? Colors.white.withOpacity(0.38)
        : const Color(0xFF1A1A2E).withOpacity(0.4);

    // Kilitliyse renkleri soluklaştır
    final effectiveColor =
        widget.locked ? Colors.grey : widget.color;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Opacity(
          opacity: widget.locked ? 0.5 : 1.0,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: effectiveColor.withOpacity(0.2), width: 1),
              boxShadow: [
                BoxShadow(
                  color: effectiveColor
                      .withOpacity(widget.isDark ? 0.07 : 0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // İkon
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          effectiveColor.withOpacity(0.9),
                          effectiveColor.withOpacity(0.45),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          widget.locked
                              ? Icons.lock_rounded
                              : widget.completed
                                  ? Icons.check_rounded
                                  : widget.icon,
                          color: Colors.white,
                          size: 26,
                        ),
                        if (!widget.locked)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Center(
                                child: Text(
                                  '${widget.index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Başlık
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.lesson.title,
                            style: TextStyle(
                                color: titleColor,
                                fontSize: 15,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 5),
                        Text(
                          widget.locked
                              ? '🔒 Önceki dersi tamamla'
                              : widget.completed
                                  ? '✅ Tamamlandı'
                                  : '${widget.lesson.initialExercises.length} soru · Başlamak için dokun',
                          style: TextStyle(
                              color: widget.completed
                                  ? const Color(0xFF00C6AE)
                                  : subtitleColor,
                              fontSize: 12,
                              fontWeight: widget.completed
                                  ? FontWeight.w600
                                  : FontWeight.normal),
                        ),
                      ],
                    ),
                  ),
                  // Ok / Kilit
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: effectiveColor.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      widget.locked
                          ? Icons.lock_rounded
                          : Icons.arrow_forward_ios_rounded,
                      color: effectiveColor,
                      size: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}