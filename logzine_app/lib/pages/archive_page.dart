import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/article.dart';
import '../services/article_text_size_service.dart';
import '../services/auth_service.dart';
import '../services/magazine_service.dart';
import '../services/mark_service.dart';
import '../services/saved_service.dart';
import '../services/user_service.dart';
import '../theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/onboarding_widgets.dart';
import 'main_shell.dart';

typedef _SavedArticleItem = ({String title, String publisher, String date, String imageUrl});
typedef _MarkItem = ({String quote, String source, String note, Color color});

/// Archive 화면 데이터 묶음. 폴백 정책(library_page와 동일):
/// 비로그인 → 데모 유지. 로그인 → 항상 실데이터, 빈 값/실패도 데모가 아닌
/// 빈 상태(0·[])로 — 로그인 사용자에게 남의 데모 데이터를 보여주지 않는다.
class _ArchiveData {
  const _ArchiveData({
    required this.isLoggedIn,
    required this.savedArticles,
    required this.marks,
    required this.marksCount,
  });

  final bool isLoggedIn;
  final List<_SavedArticleItem> savedArticles;
  final List<_MarkItem> marks;
  final int marksCount;
}

class ArchivePage extends StatefulWidget {
  const ArchivePage({super.key});

  @override
  State<ArchivePage> createState() => _ArchivePageState();
}

class _ArchivePageState extends State<ArchivePage> {
  static const String _avatarUrl =
      'https://images.unsplash.com/photo-1485955900006-10f4d324d411?auto=format&fit=crop&w=400&q=80';

  /// [폴백] 비로그인일 때만 노출하는 데모 저장 글.
  static const List<_SavedArticleItem> _demoSavedArticles = [
    (
      title: 'The beauty of empty space',
      publisher: 'Openhouse',
      date: 'May 20, 2024',
      imageUrl:
          'https://images.unsplash.com/photo-1519710164239-da123dc03ef4?auto=format&fit=crop&w=400&q=80',
    ),
    (
      title: 'A table, a chair, and the light',
      publisher: 'ARK Journal',
      date: 'May 18, 2024',
      imageUrl:
          'https://images.unsplash.com/photo-1503602642458-232111445657?auto=format&fit=crop&w=400&q=80',
    ),
  ];

  /// [폴백] 비로그인일 때만 노출하는 데모 문장 보관함.
  static const List<_MarkItem> _demoMarks = [
    (
      quote: 'When light, texture, and proportion align, the quiet becomes a language.',
      source: 'Quiet Materials · p.4',
      note: '좋아하는 공간감 표현',
      color: Color(0xFFE9C46A),
    ),
    (
      quote: 'Objects matter most when they become part of a daily ritual.',
      source: 'ROOM NOTE · p.12',
      note: '마이페이지 문장 보관함에 넣고 싶은 문장',
      color: Color(0xFFA3C9A8),
    ),
    (
      quote: 'A soft room is often made by restraint, not by abundance.',
      source: 'Openhouse · p.7',
      note: '취향 키워드와 연결됨',
      color: Color(0xFFC98B9B),
    ),
  ];

  /// [폴백] 비로그인일 때만 노출하는 데모 마크 개수.
  static const int _demoMarksCount = 12;

  Future<_ArchiveData> _archiveFuture = _loadArchive();

  /// 메인 셸 탭 전환 등으로 다시 보일 때 최신 데이터로 갱신 (#archive-saved-real 방식 채택)
  @override
  void didUpdateWidget(covariant ArchivePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _archiveFuture = _loadArchive();
  }

  static Future<_ArchiveData> _loadArchive() async {
    final bool isLoggedIn = AuthService().currentUser != null;
    if (!isLoggedIn) {
      return const _ArchiveData(
        isLoggedIn: false,
        savedArticles: _demoSavedArticles,
        marks: _demoMarks,
        marksCount: _demoMarksCount,
      );
    }

    List<_SavedArticleItem> savedArticles = const [];
    try {
      final docs = await SavedService().fetchSaved(limit: 20);
      // 저장 당시 coverUrl이 리더 기본 이미지였던 과거 데이터 보정 —
      // magazineId로 실제 매거진 표지를 우선 사용한다.
      Map<String, String> coverOf = const {};
      try {
        final mags = await MagazineService().fetchMagazines();
        coverOf = {for (final m in mags) m.id: m.coverUrl};
      } catch (_) {}
      savedArticles = [
        for (final doc in docs) _savedItemFromDoc(doc, coverOf),
      ];
    } catch (_) {
      savedArticles = const [];
    }

    int marksCount = 0;
    try {
      marksCount = await MarkService().fetchMarksCount();
    } catch (_) {
      marksCount = 0;
    }

    List<_MarkItem> marks = const [];
    try {
      final records = await MarkService().fetchRecentMarks(limit: 20);
      marks = await _resolveMarks(records);
    } catch (_) {
      marks = const [];
    }

    return _ArchiveData(
      isLoggedIn: true,
      savedArticles: savedArticles,
      marks: marks,
      marksCount: marksCount,
    );
  }

  static _SavedArticleItem _savedItemFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    Map<String, String> coverOf,
  ) {
    final data = doc.data();
    final Timestamp? savedAt = data['savedAt'] as Timestamp?;
    final String magazineId = data['magazineId'] as String? ?? '';
    return (
      title: data['articleTitle'] as String? ?? '(제목 없음)',
      publisher: data['magazineTitle'] as String? ?? '',
      date: savedAt == null ? '' : _formatDate(savedAt.toDate()),
      imageUrl: coverOf[magazineId] ?? data['coverUrl'] as String? ?? '',
    );
  }

  static String _formatDate(DateTime date) =>
      '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';

  /// 마크 레코드들을 인용문 카드로 해석. 같은 아티클을 참조하는 마크가
  /// 여러 개여도 아티클 조회는 한 번만(캐시) 하도록 순차 처리한다.
  /// 좌표가 가리키는 문장을 찾을 수 없으면(아티클 삭제 등) 그 마크는 건너뛴다.
  static Future<List<_MarkItem>> _resolveMarks(List<MarkRecord> records) async {
    final Map<String, Article?> articleCache = {};
    final List<_MarkItem> items = [];

    for (final record in records) {
      final String key = '${record.magazineId}/${record.articleId}';
      Article? article;
      if (articleCache.containsKey(key)) {
        article = articleCache[key];
      } else {
        try {
          article = await MagazineService().fetchArticleById(
            magazineId: record.magazineId,
            articleId: record.articleId,
          );
        } catch (_) {
          article = null;
        }
        articleCache[key] = article;
      }
      if (article == null) continue;
      if (record.paragraphIdx < 0 || record.paragraphIdx >= article.paragraphs.length) {
        continue;
      }
      final segments = article.paragraphs[record.paragraphIdx];
      if (record.segmentIdx < 0 || record.segmentIdx >= segments.length) continue;

      final String articleTitle = article.title.isNotEmpty ? article.title : '(제목 없음)';
      final String note = (record.memoText != null && record.memoText!.isNotEmpty)
          ? record.memoText!
          : (record.type == 'underline' ? '밑줄 표시' : '하이라이트 표시');

      items.add((
        quote: segments[record.segmentIdx],
        source: '$articleTitle · 문단 ${record.paragraphIdx + 1}',
        note: note,
        color: _colorFromHex(record.color),
      ));
    }
    return items;
  }

  /// 하이라이트 팔레트 색 hex → Color. 파싱 실패/메모 타입 등 색이 없으면
  /// 기존 하이라이트 팔레트의 기본색(노랑)으로 대체.
  static Color _colorFromHex(String? hex) {
    if (hex == null || hex.length < 7) return const Color(0xFFE9C46A);
    try {
      return Color(int.parse(hex.substring(1, 7), radix: 16) | 0xFF000000);
    } catch (_) {
      return const Color(0xFFE9C46A);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String userName = AuthService().currentUserName ?? 'Reader';

    return Scaffold(
      backgroundColor: AppColors.screen,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 4),
            LogzineTopBar(
              showBell: true,
              showSettings: true,
              showDivider: true,
              onSettingsTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const _SettingsPage()),
                );
              },
            ),
            Expanded(
              child: FutureBuilder<_ArchiveData>(
                future: _archiveFuture,
                builder: (context, snapshot) {
                  final data = snapshot.data;
                  final bool isLoggedIn = data?.isLoggedIn ?? false;
                  final savedArticles = data?.savedArticles ?? _demoSavedArticles;
                  final marks = data?.marks ?? _demoMarks;
                  final int marksCount = data?.marksCount ?? _demoMarksCount;
                  final String timeRead = isLoggedIn ? '0m' : '1h 24m';

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        Text(
                          'Archive',
                          style: logoStyle(
                            size: 32,
                            weight: FontWeight.w500,
                            letterSpacingEm: 0.0,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 18),
                        _ProfileHeader(avatarUrl: _avatarUrl, userName: userName),
                        const SizedBox(height: 24),
                        SectionHeader(
                          title: 'Saved articles',
                          onViewAll: savedArticles.isEmpty
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => _SavedArticlesPage(
                                        items: savedArticles,
                                      ),
                                    ),
                                  );
                                },
                        ),
                        const SizedBox(height: 10),
                        if (savedArticles.isEmpty)
                          const _EmptyStateCard(
                            message: '아직 저장한 글이 없어요.\n리더에서 북마크를 눌러 저장해보세요.',
                          )
                        else
                          _SurfaceCard(
                            child: Column(
                              children: [
                                for (int i = 0; i < savedArticles.length; i++) ...[
                                  if (i > 0) const Divider(color: AppColors.border, height: 1),
                                  _SavedTile(item: savedArticles[i]),
                                ],
                              ],
                            ),
                          ),
                        const SizedBox(height: 22),
                        const SectionHeader(title: 'This week'),
                        const SizedBox(height: 10),
                        _SurfaceCard(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: IntrinsicHeight(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _StatItem(
                                      label: 'Time read',
                                      value: timeRead,
                                      icon: Icons.schedule,
                                    ),
                                  ),
                                  const VerticalDivider(color: AppColors.border, width: 1),
                                  Expanded(
                                    child: InkWell(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => _MarksPage(items: marks),
                                          ),
                                        );
                                      },
                                      child: _StatItem(
                                        label: 'Marks',
                                        value: '$marksCount',
                                        icon: Icons.edit_outlined,
                                        highlight: true,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatefulWidget {
  const _ProfileHeader({required this.avatarUrl, required this.userName});

  final String avatarUrl;
  final String userName;

  @override
  State<_ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<_ProfileHeader> {
  /// Firestore에 저장된 취향이 없을 때 보여줄 기본값.
  static const List<String> _fallbackTags = [
    'Warm wood',
    'Quiet rooms',
    'Editorial mood',
  ];

  List<String> _tags = _fallbackTags;

  @override
  void initState() {
    super.initState();
    _loadTaste();
  }

  /// 온보딩에서 users/{uid}에 저장한 실제 취향 태그를 불러온다.
  /// 비로그인 → 데모 태그 유지. 로그인 → 항상 실데이터(빈 값 포함 — 빈
  /// 배열이면 build()에서 정직한 빈 상태 문구를 보여준다).
  Future<void> _loadTaste() async {
    final bool loggedIn = AuthService().currentUser != null;
    if (!loggedIn) {
      if (!mounted) return;
      setState(() => _tags = _fallbackTags);
      return;
    }
    final tags = await UserService().fetchTasteTags() ?? const [];
    if (!mounted) return;
    setState(() => _tags = tags);
  }

  Future<void> _openRefine() async {
    // 취향 재분석은 사진 분석/키워드 선택 진입 화면에서 시작한다.
    await Navigator.pushNamed(context, '/onboarding', arguments: 'edit');
    // 편집 화면에서 돌아오면 최신 취향으로 갱신
    if (!mounted) return;
    _loadTaste();
    MainShell.refreshTaste(context);
  }

  @override
  Widget build(BuildContext context) {
    final String avatarUrl = widget.avatarUrl;
    final String userName = widget.userName;
    return _SurfaceCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipOval(
              child: SizedBox(
                width: 64,
                height: 64,
                child: NetworkPhoto(url: avatarUrl, radius: 0),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_tags.isEmpty)
                    const Text(
                      '아직 취향을 설정하지 않았어요.',
                      style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final tag in _tags) _TasteTag(tag),
                      ],
                    ),
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: _openRefine,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.forest,
                      foregroundColor: AppColors.card,
                      minimumSize: const Size(0, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text('Refine taste'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 로그인 상태에서 실데이터가 비어 있을 때 보여주는 정직한 빈 상태 카드.
/// saved_page.dart의 빈 상태 톤(흰 배경 카드 + textMuted)과 동일하게 맞춘다.
class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 13,
          color: AppColors.textMuted,
          height: 1.6,
        ),
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _SavedTile extends StatelessWidget {
  const _SavedTile({required this.item});

  final _SavedArticleItem item;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, '/reader'),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            SizedBox(
              width: 58,
              height: 78,
              child: NetworkPhoto(url: item.imageUrl, radius: 10),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.publisher,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.date,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.bookmark, size: 18, color: AppColors.ink),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    this.highlight = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            color: highlight ? AppColors.forest : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: highlight ? AppColors.forest : AppColors.ink,
          ),
        ),
        const SizedBox(height: 6),
        Icon(
          icon,
          size: 17,
          color: highlight ? AppColors.forest : AppColors.textSecondary,
        ),
      ],
    );
  }
}

class _SettingsPage extends StatefulWidget {
  const _SettingsPage();

  @override
  State<_SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<_SettingsPage> {
  bool _notifications = true;
  bool _downloadWifiOnly = true;
  bool _readingReminder = false;
  bool _privateHighlights = true;
  bool _autoSaveMarks = true;
  int _textSizeStep = ArticleTextSizeService.currentStep;

  void _setTextSizeStep(int step) {
    setState(() => _textSizeStep = step);
    ArticleTextSizeService.setStep(step);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screen,
      body: SafeArea(
        child: Column(
          children: [
            const LogzineTopBar(showBack: true, showBell: false),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                children: [
                  Text(
                    'Settings',
                    style: logoStyle(
                      size: 32,
                      weight: FontWeight.w500,
                      letterSpacingEm: 0.0,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _SettingsSection(
                    title: 'Reading',
                    child: Column(
                      children: [
                        _SwitchTile(
                          title: 'Push notifications',
                          subtitle: 'Get notified for new issues and saved reading reminders.',
                          value: _notifications,
                          onChanged: (value) => setState(() => _notifications = value),
                        ),
                        const Divider(color: AppColors.border, height: 1),
                        _SwitchTile(
                          title: 'Reading reminders',
                          subtitle: 'Receive gentle nudges to continue where you left off.',
                          value: _readingReminder,
                          onChanged: (value) => setState(() => _readingReminder = value),
                        ),
                        const Divider(color: AppColors.border, height: 1),
                        _SliderTile(
                          value: _textSizeStep,
                          onChanged: _setTextSizeStep,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SettingsSection(
                    title: 'Library & Archive',
                    child: Column(
                      children: [
                        _SwitchTile(
                          title: 'Auto-save marks to archive',
                          subtitle: 'Store highlighted lines and notes in your archive automatically.',
                          value: _autoSaveMarks,
                          onChanged: (value) => setState(() => _autoSaveMarks = value),
                        ),
                        const Divider(color: AppColors.border, height: 1),
                        _SwitchTile(
                          title: 'Private highlights',
                          subtitle: 'Keep saved highlights visible only to you.',
                          value: _privateHighlights,
                          onChanged: (value) => setState(() => _privateHighlights = value),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SettingsSection(
                    title: 'Downloads',
                    child: _SwitchTile(
                      title: 'Download on Wi-Fi only',
                      subtitle: 'Preserve mobile data when saving issues offline.',
                      value: _downloadWifiOnly,
                      onChanged: (value) => setState(() => _downloadWifiOnly = value),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 10),
        _SurfaceCard(child: child),
      ],
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12.5,
            height: 1.45,
            color: AppColors.textSecondary,
          ),
        ),
      ),
      trailing: Switch(
        value: value,
        activeThumbColor: AppColors.forest,
        onChanged: onChanged,
      ),
    );
  }
}

class _SliderTile extends StatelessWidget {
  const _SliderTile({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Text size',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Adjust how comfortably you read long editorial pieces.',
            style: TextStyle(
              fontSize: 12.5,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
          Slider(
            value: value.toDouble(),
            min: ArticleTextSizeService.minStep.toDouble(),
            max: ArticleTextSizeService.maxStep.toDouble(),
            divisions:
                ArticleTextSizeService.maxStep - ArticleTextSizeService.minStep,
            label: '$value단계',
            activeColor: AppColors.forest,
            onChanged: (next) => onChanged(next.round()),
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '1 작게',
                style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
              ),
              Text(
                '2 기본',
                style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
              ),
              Text(
                '3 크게',
                style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SavedArticlesPage extends StatelessWidget {
  const _SavedArticlesPage({required this.items});

  final List<_SavedArticleItem> items;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screen,
      body: SafeArea(
        child: Column(
          children: [
            const LogzineTopBar(showBack: true, showBell: false),
            Expanded(
              child: items.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.fromLTRB(24, 8, 24, 24),
                      child: _EmptyStateCard(
                        message: '아직 저장한 글이 없어요.\n리더에서 북마크를 눌러 저장해보세요.',
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                      itemCount: items.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _SurfaceCard(child: _SavedTile(item: items[index]));
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MarksPage extends StatelessWidget {
  const _MarksPage({required this.items});

  final List<_MarkItem> items;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screen,
      body: SafeArea(
        child: Column(
          children: [
            const LogzineTopBar(showBack: true, showBell: false),
            Expanded(
              child: items.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.fromLTRB(24, 8, 24, 24),
                      child: _EmptyStateCard(
                        message: '아직 저장한 문장이 없어요.\n리더에서 하이라이트를 남겨보세요.',
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                      itemCount: items.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return _SurfaceCard(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 5,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    color: item.color,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.quote,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          height: 1.5,
                                          color: AppColors.ink,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        item.source,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item.note,
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          color: AppColors.body,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TasteTag extends StatelessWidget {
  const _TasteTag(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12.5,
          color: AppColors.ink,
        ),
      ),
    );
  }
}