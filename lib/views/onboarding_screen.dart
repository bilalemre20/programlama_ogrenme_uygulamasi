import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/progress_service.dart';
import '../viewmodels/theme_view_model.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final ProgressService _progressService = ProgressService();
  int _step = 0; // 0 = yaş, 1 = seviye
  String? _selectedAge;
  String? _selectedLevel;
  bool _isSaving = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  final List<Map<String, String>> _ageOptions = [
    {'value': '7-12', 'label': '7-12', 'emoji': '🧒'},
    {'value': '13-17', 'label': '13-17', 'emoji': '🧑'},
    {'value': '18-25', 'label': '18-25', 'emoji': '👨'},
    {'value': '26+', 'label': '26+', 'emoji': '👨‍💼'},
  ];

  final List<Map<String, String>> _levelOptions = [
    {
      'value': 'beginner',
      'label': 'Hiç bilmiyorum',
      'emoji': '🌱',
      'desc': 'Programlamaya yeni başlıyorum'
    },
    {
      'value': 'elementary',
      'label': 'Biraz biliyorum',
      'emoji': '📘',
      'desc': 'Temel kavramları duydum'
    },
    {
      'value': 'intermediate',
      'label': 'Orta seviye',
      'emoji': '🚀',
      'desc': 'Basit programlar yazabiliyorum'
    },
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_step == 0 && _selectedAge == null) return;
    setState(() => _step = 1);
    _animController.forward(from: 0);
  }

  Future<void> _complete() async {
    if (_selectedLevel == null) return;
    setState(() => _isSaving = true);

    await _progressService.saveOnboarding(
      ageRange: _selectedAge!,
      level: _selectedLevel!,
    );

    if (!mounted) return;
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final themeVM = context.watch<ThemeViewModel>();
    final isDark = themeVM.isDark;

    final bgColor =
        isDark ? const Color(0xFF0F0F1A) : const Color(0xFFF0F0FF);
    final titleColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final subtitleColor = isDark
        ? Colors.white.withOpacity(0.5)
        : const Color(0xFF1A1A2E).withOpacity(0.5);
    final cardBg = isDark ? const Color(0xFF1A1A2E) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),

                // Logo
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF6C63FF), Color(0xFF00C6AE)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x556C63FF),
                          blurRadius: 20,
                          offset: Offset(0, 6)),
                    ],
                  ),
                  child: Center(
                    child: RichText(
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: '<',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w300),
                          ),
                          TextSpan(
                            text: '/>',
                            style: TextStyle(
                                color: Color(0xFFFFBF69),
                                fontSize: 22,
                                fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Adım göstergesi
                Row(
                  children: [
                    _StepDot(active: _step >= 0, isDark: isDark),
                    const SizedBox(width: 8),
                    _StepDot(active: _step >= 1, isDark: isDark),
                  ],
                ),

                const SizedBox(height: 24),

                // Başlık
                Text(
                  _step == 0 ? 'Kaç yaşındasın?' : 'Seviyeni seç',
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _step == 0
                      ? 'Sana en uygun açıklamaları yapabilelim.'
                      : 'Python hakkında ne kadar bilgin var?',
                  style:
                      TextStyle(color: subtitleColor, fontSize: 15, height: 1.5),
                ),

                const SizedBox(height: 32),

                // Seçenekler
                if (_step == 0)
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.4,
                      children: _ageOptions.map((opt) {
                        final selected = _selectedAge == opt['value'];
                        return _AgeCard(
                          emoji: opt['emoji']!,
                          label: opt['label']!,
                          selected: selected,
                          isDark: isDark,
                          cardBg: cardBg,
                          onTap: () =>
                              setState(() => _selectedAge = opt['value']),
                        );
                      }).toList(),
                    ),
                  )
                else
                  Expanded(
                    child: Column(
                      children: _levelOptions.map((opt) {
                        final selected = _selectedLevel == opt['value'];
                        return _LevelCard(
                          emoji: opt['emoji']!,
                          label: opt['label']!,
                          desc: opt['desc']!,
                          selected: selected,
                          isDark: isDark,
                          cardBg: cardBg,
                          onTap: () =>
                              setState(() => _selectedLevel = opt['value']),
                        );
                      }).toList(),
                    ),
                  ),

                const SizedBox(height: 20),

                // Devam butonu
                GestureDetector(
                  onTap: _isSaving
                      ? null
                      : (_step == 0 ? _nextStep : _complete),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: (_step == 0
                                ? _selectedAge != null
                                : _selectedLevel != null)
                            ? [
                                const Color(0xFF6C63FF),
                                const Color(0xFF5752D1)
                              ]
                            : [Colors.grey.shade600, Colors.grey.shade700],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: (_step == 0
                              ? _selectedAge != null
                              : _selectedLevel != null)
                          ? const [
                              BoxShadow(
                                  color: Color(0x446C63FF),
                                  blurRadius: 20,
                                  offset: Offset(0, 8))
                            ]
                          : [],
                    ),
                    child: Center(
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              _step == 0 ? 'Devam Et' : 'Başla 🚀',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── ADIM NOKTASI ───────────────────────────────────────────────────
class _StepDot extends StatelessWidget {
  final bool active;
  final bool isDark;
  const _StepDot({required this.active, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: active ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active
            ? const Color(0xFF6C63FF)
            : (isDark
                ? Colors.white.withOpacity(0.2)
                : Colors.black.withOpacity(0.15)),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

// ── YAŞ KARTI ─────────────────────────────────────────────────────
class _AgeCard extends StatelessWidget {
  final String emoji;
  final String label;
  final bool selected;
  final bool isDark;
  final Color cardBg;
  final VoidCallback onTap;

  const _AgeCard({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.isDark,
    required this.cardBg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF6C63FF).withOpacity(0.12)
              : cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? const Color(0xFF6C63FF)
                : (isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.08)),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? const [
                  BoxShadow(
                      color: Color(0x336C63FF),
                      blurRadius: 16,
                      offset: Offset(0, 4))
                ]
              : [
                  BoxShadow(
                      color: Colors.black
                          .withOpacity(isDark ? 0.2 : 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: selected
                    ? const Color(0xFF6C63FF)
                    : (isDark ? Colors.white : const Color(0xFF1A1A2E)),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'yaş',
              style: TextStyle(
                color: selected
                    ? const Color(0xFF6C63FF).withOpacity(0.7)
                    : (isDark
                        ? Colors.white.withOpacity(0.4)
                        : Colors.black.withOpacity(0.4)),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── SEVİYE KARTI ──────────────────────────────────────────────────
class _LevelCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String desc;
  final bool selected;
  final bool isDark;
  final Color cardBg;
  final VoidCallback onTap;

  const _LevelCard({
    required this.emoji,
    required this.label,
    required this.desc,
    required this.selected,
    required this.isDark,
    required this.cardBg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final subtitleColor = isDark
        ? Colors.white.withOpacity(0.45)
        : Colors.black.withOpacity(0.45);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF6C63FF).withOpacity(0.1)
              : cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? const Color(0xFF6C63FF)
                : (isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.08)),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? const [
                  BoxShadow(
                      color: Color(0x336C63FF),
                      blurRadius: 16,
                      offset: Offset(0, 4))
                ]
              : [
                  BoxShadow(
                      color: Colors.black
                          .withOpacity(isDark ? 0.2 : 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ],
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: selected
                          ? const Color(0xFF6C63FF)
                          : textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    desc,
                    style: TextStyle(
                      color: selected
                          ? const Color(0xFF6C63FF).withOpacity(0.7)
                          : subtitleColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded,
                  color: Color(0xFF6C63FF), size: 22),
          ],
        ),
      ),
    );
  }
}