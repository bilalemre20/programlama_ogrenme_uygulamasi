import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../services/progress_service.dart';
import '../viewmodels/auth_view_model.dart';
import '../viewmodels/theme_view_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProgressService _progressService = ProgressService();
  Map<String, dynamic> _profile = {};
  List<Map<String, dynamic>> _mistakes = [];
  bool _isLoading = true;
  bool _isEditing = false;
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    final profile = await _progressService.getUserProfile();
    final mistakes = await _progressService.getMistakes();
    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;
    final name = profile['displayName'] as String? ??
        user?.displayName ??
        user?.email?.split('@')[0] ??
        'Kullanıcı';

    _nameController.text = name;

    setState(() {
      _profile = profile;
      _mistakes = mistakes;
      _isLoading = false;
    });
  }

  Future<void> _saveName() async {
    await _progressService.updateDisplayName(_nameController.text.trim());
    if (!mounted) return;
    setState(() => _isEditing = false);
    await _loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    final themeVM = context.watch<ThemeViewModel>();
    final isDark = themeVM.isDark;
    final user = FirebaseAuth.instance.currentUser;
    final authVM = context.read<AuthViewModel>();

    final bgColor =
        isDark ? const Color(0xFF0F0F1A) : const Color(0xFFF0F0FF);
    final cardBg = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final subtitleColor = isDark
        ? Colors.white.withOpacity(0.45)
        : const Color(0xFF1A1A2E).withOpacity(0.45);

    final completedLessons =
        (_profile['completedLessons'] as List? ?? []).length;
    final streak = _profile['streak'] as int? ?? 0;
    final displayName = _nameController.text.isNotEmpty
        ? _nameController.text
        : user?.email?.split('@')[0] ?? 'Kullanıcı';
    final badges = _progressService.getBadges(completedLessons, streak);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: const Color(0xFF6C63FF),
                  strokeWidth: 2.5,
                ),
              )
            : SingleChildScrollView(
                child: Column(
                  children: [
                    // ── HEADER ───────────────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? [
                                  const Color(0xFF1A1A2E),
                                  const Color(0xFF0F0F1A)
                                ]
                              : [
                                  const Color(0xFFE8E8FF),
                                  const Color(0xFFF0F0FF)
                                ],
                        ),
                      ),
                      child: Column(
                        children: [
                          // Çıkış butonu
                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: () async {
                                await authVM.logout();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF6584)
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFFFF6584)
                                        .withOpacity(0.3),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.logout_rounded,
                                        color: Color(0xFFFF6584),
                                        size: 14),
                                    SizedBox(width: 4),
                                    Text(
                                      'Çıkış',
                                      style: TextStyle(
                                        color: Color(0xFFFF6584),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Avatar
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF6C63FF),
                                  Color(0xFF00C6AE)
                                ],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x556C63FF),
                                  blurRadius: 20,
                                  offset: Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                displayName.isNotEmpty
                                    ? displayName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 36,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // İsim + düzenle
                          _isEditing
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 180,
                                      child: TextField(
                                        controller: _nameController,
                                        autofocus: true,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: titleColor,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                        ),
                                        decoration: InputDecoration(
                                          border: InputBorder.none,
                                          hintText: 'Adın...',
                                          hintStyle: TextStyle(
                                              color: subtitleColor),
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: _saveName,
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF00C6AE)
                                              .withOpacity(0.15),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                            Icons.check_rounded,
                                            color: Color(0xFF00C6AE),
                                            size: 16),
                                      ),
                                    ),
                                  ],
                                )
                              : GestureDetector(
                                  onTap: () =>
                                      setState(() => _isEditing = true),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        displayName,
                                        style: TextStyle(
                                          color: titleColor,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Icon(Icons.edit_rounded,
                                          color: subtitleColor, size: 14),
                                    ],
                                  ),
                                ),

                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? '',
                            style: TextStyle(
                                color: subtitleColor, fontSize: 13),
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // ── İSTATİSTİKLER ─────────────────────
                          Row(
                            children: [
                              Expanded(
                                child: _StatCard(
                                  icon: '📚',
                                  value: '$completedLessons',
                                  label: 'Ders\nTamamlandı',
                                  color: const Color(0xFF6C63FF),
                                  isDark: isDark,
                                  cardBg: cardBg,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StatCard(
                                  icon: '🔥',
                                  value: '$streak',
                                  label: 'Günlük\nSeri',
                                  color: const Color(0xFFFF9A3C),
                                  isDark: isDark,
                                  cardBg: cardBg,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StatCard(
                                  icon: '🏅',
                                  value:
                                      '${badges.where((b) => b['unlocked'] == true).length}',
                                  label: 'Kazanılan\nRozet',
                                  color: const Color(0xFF00C6AE),
                                  isDark: isDark,
                                  cardBg: cardBg,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // ── ROZETLER ─────────────────────────
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Rozetler',
                              style: TextStyle(
                                color: titleColor,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          GridView.builder(
                            shrinkWrap: true,
                            physics:
                                const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: 0.9,
                            ),
                            itemCount: badges.length,
                            itemBuilder: (context, index) {
                              final badge = badges[index];
                              return _BadgeCard(
                                icon: badge['icon'],
                                title: badge['title'],
                                desc: badge['desc'],
                                unlocked: badge['unlocked'],
                                isDark: isDark,
                                cardBg: cardBg,
                              );
                            },
                          ),

                          const SizedBox(height: 40),

                          // ── ZAYIF NOKTALAR (HATA PARMAK İZİ) ───────────────
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Zayıf Noktalar',
                              style: TextStyle(
                                color: titleColor,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          // Eğer hiç hata yapmamışsa tebrik mesajı göster
                          if (_mistakes.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: Colors.grey.withOpacity(0.15)),
                              ),
                              child: Text(
                                'Harika! Henüz kaydedilmiş bir hatan yok. 🎉',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: subtitleColor, fontSize: 13),
                              ),
                            )
                          else
                            // Hataları listele ve çubuk grafiğe dönüştür
                            ..._mistakes.asMap().entries.map((entry) {
                              final index = entry.key;
                              final mistake = entry.value;
                              final count = mistake['count'] as int;
                              
                              // Çubuğun doluluk oranını en çok hata yapılan derse göre hesapla
                              final maxCount = _mistakes.first['count'] as int;
                              final ratio = count / maxCount;

                              // Grafikleri renklendirmek için renk paleti
                              final colors = [
                                const Color(0xFFFF6584), // Kırmızı
                                const Color(0xFFFF9A3C), // Turuncu
                                const Color(0xFFFFBF69), // Sarı
                                const Color(0xFF6C63FF), // Mor
                                const Color(0xFF00C6AE), // Yeşil
                              ];
                              final color = colors[index % colors.length];

                              return _MistakeBar(
                                title: mistake['title'],
                                count: count,
                                ratio: ratio,
                                color: color,
                                isDark: isDark,
                                cardBg: cardBg,
                              );
                            }).toList(),

                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

// ── İSTATİSTİK KARTI ───────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String icon;
  final String value;
  final String label;
  final Color color;
  final bool isDark;
  final Color cardBg;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.isDark,
    required this.cardBg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(isDark ? 0.07 : 0.1),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark
                  ? Colors.white.withOpacity(0.4)
                  : Colors.black.withOpacity(0.4),
              fontSize: 11,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ── ROZET KARTI ─────────────────────────────────────────────────────
class _BadgeCard extends StatelessWidget {
  final String icon;
  final String title;
  final String desc;
  final bool unlocked;
  final bool isDark;
  final Color cardBg;

  const _BadgeCard({
    required this.icon,
    required this.title,
    required this.desc,
    required this.unlocked,
    required this.isDark,
    required this.cardBg,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final subtitleColor = isDark
        ? Colors.white.withOpacity(0.4)
        : Colors.black.withOpacity(0.4);

    return Opacity(
      opacity: unlocked ? 1.0 : 0.4,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: unlocked
                ? const Color(0xFF6C63FF).withOpacity(0.25)
                : Colors.grey.withOpacity(0.15),
          ),
          boxShadow: unlocked
              ? [
                  BoxShadow(
                    color: const Color(0xFF6C63FF)
                        .withOpacity(isDark ? 0.08 : 0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(unlocked ? icon : '🔒',
                style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: titleColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              desc,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: subtitleColor,
                fontSize: 9,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── HATA ÇUBUĞU ─────────────────────────────────────────────────────
class _MistakeBar extends StatelessWidget {
  final String title;
  final int count;
  final double ratio;
  final Color color;
  final bool isDark;
  final Color cardBg;

  const _MistakeBar({
    required this.title,
    required this.count,
    required this.ratio,
    required this.color,
    required this.isDark,
    required this.cardBg,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final subtitleColor = isDark
        ? Colors.white.withOpacity(0.4)
        : Colors.black.withOpacity(0.4);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(isDark ? 0.05 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count hata',
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: ratio,
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }
}