import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/lesson_model.dart';
import '../services/firebase_service.dart';
import '../viewmodels/lesson_view_model.dart';
import '../viewmodels/theme_view_model.dart';
import 'lesson_detail_screen.dart';

class LessonListScreen extends StatefulWidget {
  const LessonListScreen({super.key});

  @override
  State<LessonListScreen> createState() => _LessonListScreenState();
}

class _LessonListScreenState extends State<LessonListScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  List<Lesson> _lessons = [];
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
    _loadLessons();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadLessons() async {
    setState(() => _isLoading = true);
    final lessons = await _firebaseService.getLessons();
    setState(() {
      _lessons = lessons;
      _isLoading = false;
    });
    _animController.forward(from: 0);
  }

  Color _getColor(int index) => _cardColors[index % _cardColors.length];
  IconData _getIcon(int index) => _cardIcons[index % _cardIcons.length];

  @override
  Widget build(BuildContext context) {
    final themeVM = context.watch<ThemeViewModel>();
    final isDark = themeVM.isDark;

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
            expandedHeight: 210,
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
                    // Dekoratif daireler
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
                    // Tema toggle — sağ üst
                    Positioned(
                      top: 52,
                      right: 16,
                      child: _ThemeToggle(isDark: isDark, themeVM: themeVM),
                    ),
                    // Başlık
                    Positioned(
                      bottom: 24,
                      left: 20,
                      right: 80,
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
                              '🐍  Python Kursu',
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
                                : '${_lessons.length} ders · Yeni başlayanlar için',
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
                      onTap: _loadLessons,
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
                        onTap: () {
                          final vm = context.read<LessonViewModel>();
                          vm.loadLesson(lesson);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ChangeNotifierProvider.value(
                                value: vm,
                                child: const LessonDetailScreen(),
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

// ── DERS KARTI ─────────────────────────────────────────────────────
class _LessonCard extends StatefulWidget {
  final Lesson lesson;
  final int index;
  final Color color;
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;

  const _LessonCard({
    required this.lesson,
    required this.index,
    required this.color,
    required this.icon,
    required this.isDark,
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
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border:
                Border.all(color: widget.color.withOpacity(0.2), width: 1),
            boxShadow: [
              BoxShadow(
                color: widget.color
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
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        widget.color.withOpacity(0.9),
                        widget.color.withOpacity(0.45),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(widget.icon, color: Colors.white, size: 26),
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
                          '${widget.lesson.initialExercises.length} soru · Başlamak için dokun',
                          style: TextStyle(
                              color: subtitleColor, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: widget.color.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.arrow_forward_ios_rounded,
                      color: widget.color, size: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}