import 'package:flutter/material.dart';

import '../models/article.dart';
import '../models/magazine.dart';
import '../models/reader_args.dart';
import '../services/article_text_size_service.dart';
import '../services/auth_service.dart';
import '../services/magazine_service.dart';
import '../services/mark_service.dart';
import '../services/reading_stats_service.dart';
import '../services/user_service.dart';
import '../theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/motion_widgets.dart';
import '../widgets/onboarding_widgets.dart';

typedef _MarkItem = ({
  String quote,
  String articleTitle,
  String magazineTitle,
  String source,
  String note,
  Color color,
  String type,
  String articleId,
  String magazineId,
  String coverUrl,
  String savedAt,
});
typedef _MagazineMeta = ({String title, String coverUrl, String publisherName});
typedef _RecentViewedItem = ({
  String articleId,
  String magazineId,
  String title,
  String publisher,
  int progress,
  String imageUrl,
});
typedef _HiddenMagazineItem = ({
  String id,
  String title,
  String issue,
  String publisherName,
});

/// Archive 화면 데이터 묶음. 폴백 정책(library_page와 동일):
/// 비로그인 → 데모 유지. 로그인 → 항상 실데이터, 빈 값/실패도 데모가 아닌
/// 빈 상태(0·[])로 — 로그인 사용자에게 남의 데모 데이터를 보여주지 않는다.
class _ArchiveData {
  const _ArchiveData({
    required this.isLoggedIn,
    required this.recentViewed,
    required this.marks,
    required this.marksCount,
    required this.todaySeconds,
  });

  final bool isLoggedIn;
  final List<_RecentViewedItem> recentViewed;
  final List<_MarkItem> marks;
  final int marksCount;
  final int todaySeconds;
}

/// 초 → '0m' / '1h 24m' 표기 (기존 화면 형식 유지).
String _formatReadTime(int seconds) {
  final int totalMinutes = seconds ~/ 60;
  final int hours = totalMinutes ~/ 60;
  final int minutes = totalMinutes % 60;
  return hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';
}

/// yyyyMMdd 문서 ID → 요일 라벨 (Mon~Sun)
String _weekdayLabelFor(String yyyyMMdd) {
  final DateTime date = DateTime(
    int.parse(yyyyMMdd.substring(0, 4)),
    int.parse(yyyyMMdd.substring(4, 6)),
    int.parse(yyyyMMdd.substring(6, 8)),
  );
  const List<String> labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return labels[date.weekday - 1];
}

const List<String> _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// "July 2026" 형식 — 통계 페이지 "This month" 섹션 라벨용.
String _monthYearLabel(DateTime date) =>
    '${_monthNames[date.month - 1]} ${date.year}';

class ArchivePage extends StatefulWidget {
  const ArchivePage({super.key});

  @override
  State<ArchivePage> createState() => _ArchivePageState();
}

class _ArchivePageState extends State<ArchivePage> {
  static const String _avatarUrl =
      'https://images.unsplash.com/photo-1485955900006-10f4d324d411?auto=format&fit=crop&w=400&q=80';

  /// [폴백] 비로그인일 때만 노출하는 데모 최근 본 매거진.
  static const List<_RecentViewedItem> _demoRecentViewed = [
    (
      articleId: '',
      magazineId: '',
      title: 'CEREAL',
      publisher: 'Cereal Magazine',
      progress: 68,
      imageUrl:
          'https://images.unsplash.com/photo-1519710164239-da123dc03ef4?auto=format&fit=crop&w=600&q=80',
    ),
    (
      articleId: '',
      magazineId: '',
      title: 'Quiet Materials',
      publisher: 'Studio Log',
      progress: 42,
      imageUrl:
          'https://images.unsplash.com/photo-1493809842364-78817add7ffb?auto=format&fit=crop&w=600&q=80',
    ),
    (
      articleId: '',
      magazineId: '',
      title: 'ROOM NOTES',
      publisher: 'Room Note',
      progress: 15,
      imageUrl:
          'https://images.unsplash.com/photo-1502005229762-cf1b2da7c5d6?auto=format&fit=crop&w=600&q=80',
    ),
  ];

  /// [폴백] 비로그인일 때만 노출하는 데모 문장 보관함.
  static const List<_MarkItem> _demoMarks = [
    (
      quote:
          'When light, texture, and proportion align, the quiet becomes a language.',
      articleTitle: 'Quiet Materials',
      magazineTitle: 'Openhouse',
      source: 'Quiet Materials · p.4',
      note: '좋아하는 공간감 표현',
      color: Color(0xFFE9C46A),
      type: 'highlight',
      articleId: '',
      magazineId: '',
      coverUrl: '',
      savedAt: '2026.07.08',
    ),
    (
      quote: 'Objects matter most when they become part of a daily ritual.',
      articleTitle: 'ROOM NOTE',
      magazineTitle: 'ROOM NOTE',
      source: 'ROOM NOTE · p.12',
      note: '마이페이지 문장 보관함에 넣고 싶은 문장',
      color: AppColors.ink,
      type: 'memo',
      articleId: '',
      magazineId: '',
      coverUrl: '',
      savedAt: '2026.07.07',
    ),
    (
      quote: 'A soft room is often made by restraint, not by abundance.',
      articleTitle: 'A soft room',
      magazineTitle: 'Openhouse',
      source: 'Openhouse · p.7',
      note: '취향 키워드와 연결됨',
      color: Color(0xFFC98B9B),
      type: 'memo',
      articleId: '',
      magazineId: '',
      coverUrl: '',
      savedAt: '2026.07.06',
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
        recentViewed: _demoRecentViewed,
        marks: _demoMarks,
        marksCount: _demoMarksCount,
        todaySeconds: 0,
      );
    }

    final magazineService = MagazineService();
    Map<String, _MagazineMeta> magazineMeta = const {};
    try {
      final magazines = await magazineService.fetchMagazines();
      magazineMeta = {
        for (final magazine in magazines)
          magazine.id: (
            title: magazine.title,
            coverUrl: magazine.coverUrl,
            publisherName: magazine.publisherName,
          ),
      };
    } catch (_) {
      magazineMeta = const {};
    }

    List<_RecentViewedItem> recentViewed = const [];
    try {
      final progress = await MarkService().fetchProgressList(limit: 10);
      final resolved = await Future.wait(
        progress.map((record) => _recentItemFromProgress(record, magazineMeta)),
      );
      recentViewed = resolved.whereType<_RecentViewedItem>().toList();
    } catch (_) {
      recentViewed = const [];
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
      marks = await _resolveMarks(records, magazineMeta);
    } catch (_) {
      marks = const [];
    }

    int todaySeconds = 0;
    try {
      todaySeconds = await ReadingStatsService().fetchTodaySeconds();
    } catch (_) {
      todaySeconds = 0;
    }

    return _ArchiveData(
      isLoggedIn: true,
      recentViewed: recentViewed,
      marks: marks,
      marksCount: marksCount,
      todaySeconds: todaySeconds,
    );
  }

  static String _formatDate(DateTime date) =>
      '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';

  static Future<_RecentViewedItem?> _recentItemFromProgress(
    ProgressRecord record,
    Map<String, _MagazineMeta> magazineMeta,
  ) async {
    final meta = magazineMeta[record.magazineId];
    if (meta == null) return null;

    String title = meta.title;
    try {
      final article = await MagazineService().fetchArticleById(
        magazineId: record.magazineId,
        articleId: record.articleId,
      );
      if (article != null && article.title.isNotEmpty) {
        title = article.title;
      }
    } catch (_) {
      // 아티클이 삭제됐거나 일시 실패하면 매거진 제목으로 대체
    }

    return (
      articleId: record.articleId,
      magazineId: record.magazineId,
      title: title,
      publisher: meta.publisherName.isNotEmpty
          ? meta.publisherName
          : meta.title,
      progress: record.percent.clamp(0, 100).toInt(),
      imageUrl: meta.coverUrl,
    );
  }

  /// 마크 레코드들을 인용문 카드로 해석. 같은 아티클을 참조하는 마크가
  /// 여러 개여도 아티클 조회는 한 번만(캐시) 하도록 순차 처리한다.
  /// 좌표가 가리키는 문장을 찾을 수 없으면(아티클 삭제 등) 그 마크는 건너뛴다.
  static Future<List<_MarkItem>> _resolveMarks(
    List<MarkRecord> records,
    Map<String, _MagazineMeta> magazineMeta,
  ) async {
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
      if (record.paragraphIdx < 0 ||
          record.paragraphIdx >= article.paragraphs.length) {
        continue;
      }
      final segments = article.paragraphs[record.paragraphIdx];
      if (record.segmentIdx < 0 || record.segmentIdx >= segments.length) {
        continue;
      }

      final String articleTitle = article.title.isNotEmpty
          ? article.title
          : '(제목 없음)';
      final meta = magazineMeta[record.magazineId];
      final String magazineTitle = meta?.title ?? 'LOGZINE';
      final String memoText = record.memoText?.trim() ?? '';
      final bool hasMemo = memoText.isNotEmpty;
      final String markType = hasMemo || record.type == 'memo'
          ? 'memo'
          : 'highlight';
      final String note = hasMemo
          ? memoText
          : (record.type == 'memo' ? '메모 표시' : '하이라이트 표시');

      items.add((
        quote: segments[record.segmentIdx],
        articleTitle: articleTitle,
        magazineTitle: magazineTitle,
        source: '$magazineTitle · 문단 ${record.paragraphIdx + 1}',
        note: note,
        color: _colorFromHex(record.color),
        type: markType,
        articleId: record.articleId,
        magazineId: record.magazineId,
        coverUrl: meta?.coverUrl ?? '',
        savedAt: record.createdAt == null
            ? '최근 저장'
            : _formatDate(record.createdAt!),
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
                  final recentViewed = data?.recentViewed ?? _demoRecentViewed;
                  final marks = data?.marks ?? _demoMarks;
                  final int marksCount = data?.marksCount ?? _demoMarksCount;
                  final int todaySeconds = data?.todaySeconds ?? 0;
                  final String timeRead = isLoggedIn
                      ? _formatReadTime(todaySeconds)
                      : '1h 24m';

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        const PageTitleHeader(title: 'Archive'),
                        const SizedBox(height: 18),
                        FadeSlideIn(
                          delay: FadeSlideIn.stagger(0),
                          child: _ProfileHeader(
                            avatarUrl: _avatarUrl,
                            userName: userName,
                          ),
                        ),
                        const SizedBox(height: 24),
                        FadeSlideIn(
                          delay: FadeSlideIn.stagger(1),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SectionHeader(title: 'This week'),
                              const SizedBox(height: 10),
                              _SurfaceCard(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  child: IntrinsicHeight(
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: InkWell(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      const _ReadingStatsPage(),
                                                ),
                                              );
                                            },
                                            child: _StatItem(
                                              label: 'Time read',
                                              value: timeRead,
                                              icon: Icons.schedule,
                                            ),
                                          ),
                                        ),
                                        const VerticalDivider(
                                          color: AppColors.border,
                                          width: 1,
                                        ),
                                        Expanded(
                                          child: InkWell(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      _MarksPage(items: marks),
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
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                        FadeSlideIn(
                          delay: FadeSlideIn.stagger(2),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SectionHeader(
                                title: 'Recently viewed',
                                onViewAll: recentViewed.isEmpty
                                    ? null
                                    : () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => _RecentViewedPage(
                                              items: recentViewed,
                                            ),
                                          ),
                                        );
                                      },
                              ),
                              const SizedBox(height: 10),
                              if (recentViewed.isEmpty)
                                const _EmptyStateCard(
                                  message:
                                      '아직 최근 본 매거진이 없어요.\n매거진 상세나 리더를 열면 여기에 기록돼요.',
                                )
                              else
                                _RecentShelf(
                                  items: recentViewed.take(6).toList(),
                                ),
                            ],
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
    _loadTaste();
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
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textMuted,
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [for (final tag in _tags) _TasteTag(tag)],
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

void _openRecentViewed(BuildContext context, _RecentViewedItem item) {
  if (item.magazineId.isEmpty || item.articleId.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('This magazine is unavailable.')),
    );
    return;
  }
  Navigator.pushNamed(
    context,
    '/reader',
    arguments: ReaderArgs(
      title: item.title,
      publisher: item.publisher,
      magazineId: item.magazineId,
      articleId: item.articleId,
      coverUrl: item.imageUrl.isEmpty ? null : item.imageUrl,
    ),
  );
}

String _progressLabel(int progress) {
  final clamped = progress.clamp(0, 100);
  if (clamped <= 0) return 'Not started';
  return '$clamped% read';
}

class _RecentShelf extends StatelessWidget {
  const _RecentShelf({required this.items});

  final List<_RecentViewedItem> items;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 288,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final item = items[index];
          return InkWell(
            onTap: () => _openRecentViewed(context, item),
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 150,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 150,
                      height: 250,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          NetworkPhoto(url: item.imageUrl, radius: 12),
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color(0x5A000000),
                                  Color(0x10000000),
                                  Color(0x00000000),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              item.title,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: logoStyle(
                                size: 17,
                                weight: FontWeight.w600,
                                letterSpacingEm: 0.06,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 10,
                    right: 10,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _progressLabel(item.progress),
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.body,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RecentViewedPage extends StatelessWidget {
  const _RecentViewedPage({required this.items});

  final List<_RecentViewedItem> items;

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
                        message: '아직 최근 본 매거진이 없어요.\n매거진 상세나 리더를 열면 여기에 기록돼요.',
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                      itemCount: items.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return _SurfaceCard(
                          child: InkWell(
                            onTap: () => _openRecentViewed(context, item),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 58,
                                    height: 78,
                                    child: NetworkPhoto(
                                      url: item.imageUrl,
                                      radius: 10,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.ink,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item.publisher,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          _progressLabel(item.progress),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.body,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right,
                                    size: 20,
                                    color: AppColors.textSecondary,
                                  ),
                                ],
                              ),
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
  bool _resettingHiddenMagazines = false;
  bool _showAllHiddenMagazines = false;
  final Set<String> _unhidingMagazineIds = <String>{};
  int _textSizeStep = ArticleTextSizeService.currentStep;
  late Future<List<_HiddenMagazineItem>> _hiddenMagazinesFuture =
      _loadHiddenMagazines();

  void _setTextSizeStep(int step) {
    setState(() => _textSizeStep = step);
    ArticleTextSizeService.setStep(step);
  }

  static Future<List<_HiddenMagazineItem>> _loadHiddenMagazines() async {
    final ids = await UserService().fetchExcludedMagazineIdsByRecentStrict();
    if (ids.isEmpty) return const [];

    List<Magazine> magazines;
    try {
      magazines = await MagazineService().fetchMagazines();
      if (magazines.isEmpty) magazines = kMagazines;
    } catch (_) {
      magazines = kMagazines;
    }

    final byId = {
      for (final magazine in magazines)
        if (magazine.id.isNotEmpty) magazine.id: magazine,
    };

    return [
      for (final id in ids)
        if (byId[id] != null)
          (
            id: id,
            title: byId[id]!.title,
            issue: byId[id]!.issue,
            publisherName: byId[id]!.publisherName,
          )
        else
          (id: id, title: 'Unavailable magazine', issue: '', publisherName: ''),
    ];
  }

  Future<void> _resetHiddenMagazines() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Show all hidden magazines again?'),
        content: const Text('They may appear in your recommendations again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.forest),
            child: const Text('Show all again'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _resettingHiddenMagazines = true);
    try {
      await UserService().resetExcludedMagazines();
      if (!mounted) return;
      setState(() {
        _showAllHiddenMagazines = false;
        _hiddenMagazinesFuture = _loadHiddenMagazines();
      });
      messenger.showSnackBar(
        const SnackBar(content: Text('Hidden magazines are visible again.')),
      );
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Sign in to manage hidden magazines.')),
      );
    } finally {
      if (mounted) setState(() => _resettingHiddenMagazines = false);
    }
  }

  Future<void> _unhideMagazine(_HiddenMagazineItem item) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _unhidingMagazineIds.add(item.id));
    try {
      await UserService().unhideMagazine(item.id);
      if (!mounted) return;
      setState(() {
        _hiddenMagazinesFuture = _loadHiddenMagazines();
      });
      messenger.showSnackBar(
        SnackBar(content: Text('${item.title} is visible again.')),
      );
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not unhide this magazine.')),
      );
    } finally {
      if (mounted) setState(() => _unhidingMagazineIds.remove(item.id));
    }
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
                          subtitle:
                              'Get notified for new issues and saved reading reminders.',
                          value: _notifications,
                          onChanged: (value) =>
                              setState(() => _notifications = value),
                        ),
                        const Divider(color: AppColors.border, height: 1),
                        _SwitchTile(
                          title: 'Reading reminders',
                          subtitle:
                              'Receive gentle nudges to continue where you left off.',
                          value: _readingReminder,
                          onChanged: (value) =>
                              setState(() => _readingReminder = value),
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
                          subtitle:
                              'Store highlighted lines and notes in your archive automatically.',
                          value: _autoSaveMarks,
                          onChanged: (value) =>
                              setState(() => _autoSaveMarks = value),
                        ),
                        const Divider(color: AppColors.border, height: 1),
                        _SwitchTile(
                          title: 'Private highlights',
                          subtitle:
                              'Keep saved highlights visible only to you.',
                          value: _privateHighlights,
                          onChanged: (value) =>
                              setState(() => _privateHighlights = value),
                        ),
                        const Divider(color: AppColors.border, height: 1),
                        _HiddenMagazinesTile(
                          future: _hiddenMagazinesFuture,
                          resetting: _resettingHiddenMagazines,
                          expanded: _showAllHiddenMagazines,
                          busyIds: _unhidingMagazineIds,
                          onReset: _resetHiddenMagazines,
                          onUnhide: _unhideMagazine,
                          onToggleExpanded: () {
                            setState(() {
                              _showAllHiddenMagazines =
                                  !_showAllHiddenMagazines;
                            });
                          },
                          onRefresh: () {
                            setState(() {
                              _hiddenMagazinesFuture = _loadHiddenMagazines();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SettingsSection(
                    title: 'Downloads',
                    child: _SwitchTile(
                      title: 'Download on Wi-Fi only',
                      subtitle:
                          'Preserve mobile data when saving issues offline.',
                      value: _downloadWifiOnly,
                      onChanged: (value) =>
                          setState(() => _downloadWifiOnly = value),
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

class _HiddenMagazinesTile extends StatelessWidget {
  const _HiddenMagazinesTile({
    required this.future,
    required this.resetting,
    required this.expanded,
    required this.busyIds,
    required this.onReset,
    required this.onUnhide,
    required this.onToggleExpanded,
    required this.onRefresh,
  });

  final Future<List<_HiddenMagazineItem>> future;
  final bool resetting;
  final bool expanded;
  final Set<String> busyIds;
  final VoidCallback onReset;
  final ValueChanged<_HiddenMagazineItem> onUnhide;
  final VoidCallback onToggleExpanded;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_HiddenMagazineItem>>(
      future: future,
      builder: (context, snapshot) {
        final loading = snapshot.connectionState != ConnectionState.done;
        final items = snapshot.data ?? const <_HiddenMagazineItem>[];
        final hasItems = items.isNotEmpty;
        final hasError = snapshot.hasError;
        final visibleItems = expanded ? items : items.take(5).toList();
        final remaining = items.length - visibleItems.length;

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Hidden magazines',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Refresh hidden list',
                    onPressed: loading || resetting || busyIds.isNotEmpty
                        ? null
                        : onRefresh,
                    icon: const Icon(
                      Icons.refresh_rounded,
                      semanticLabel: 'Refresh hidden list',
                      size: 19,
                    ),
                    color: AppColors.forest,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _statusText(loading: loading, hasError: hasError, items: items),
                style: const TextStyle(
                  fontSize: 12.5,
                  height: 1.45,
                  color: AppColors.textSecondary,
                ),
              ),
              if (loading) ...[
                const SizedBox(height: 14),
                const LinearProgressIndicator(
                  minHeight: 2,
                  color: AppColors.forest,
                  backgroundColor: AppColors.border,
                ),
              ] else if (hasError) ...[
                const SizedBox(height: 14),
                _HiddenListMessage(
                  icon: Icons.error_outline_rounded,
                  title: 'Could not load hidden magazines',
                  body: 'Check your connection or sign in again.',
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: loading || resetting || busyIds.isNotEmpty
                        ? null
                        : onRefresh,
                    icon: const Icon(
                      Icons.refresh_rounded,
                      semanticLabel: 'Try again',
                      size: 18,
                    ),
                    label: const Text('Try again'),
                    style: _hiddenActionButtonStyle(),
                  ),
                ),
              ] else if (hasItems) ...[
                const SizedBox(height: 14),
                for (final item in visibleItems)
                  _HiddenMagazineRow(
                    item: item,
                    busy: busyIds.contains(item.id),
                    disabled: resetting || busyIds.isNotEmpty,
                    onUnhide: () => onUnhide(item),
                  ),
                if (remaining > 0 || (expanded && items.length > 5)) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: resetting || busyIds.isNotEmpty
                        ? null
                        : onToggleExpanded,
                    icon: Icon(
                      expanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      semanticLabel: expanded
                          ? 'Show fewer hidden magazines'
                          : 'View more hidden magazines',
                      size: 18,
                    ),
                    label: Text(
                      expanded ? 'Show fewer' : 'View $remaining more',
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.forest,
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: resetting || busyIds.isNotEmpty ? null : onReset,
                    icon: resetting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.forest,
                            ),
                          )
                        : const Icon(
                            Icons.restore_rounded,
                            semanticLabel: 'Unhide all magazines',
                            size: 18,
                          ),
                    label: Text(
                      resetting ? 'Showing all...' : 'Unhide all magazines',
                    ),
                    style: _hiddenActionButtonStyle(),
                  ),
                ),
              ] else ...[
                const SizedBox(height: 14),
                const _HiddenListMessage(
                  icon: Icons.visibility_outlined,
                  title: 'No hidden magazines',
                  body:
                      'Magazines you hide from recommendations will appear here.',
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  static String _statusText({
    required bool loading,
    required bool hasError,
    required List<_HiddenMagazineItem> items,
  }) {
    if (loading) return 'Checking magazines removed with Not for me.';
    if (hasError) {
      return 'Hidden magazine settings are temporarily unavailable.';
    }
    if (items.isEmpty) return 'No magazines hidden from recommendations.';
    final suffix = items.length == 1 ? '' : 's';
    return '${items.length} magazine$suffix hidden from recommendations.';
  }

  static ButtonStyle _hiddenActionButtonStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: AppColors.forest,
      side: const BorderSide(color: AppColors.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}

class _HiddenListMessage extends StatelessWidget {
  const _HiddenListMessage({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.45,
                    color: AppColors.textSecondary,
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

class _HiddenMagazineRow extends StatelessWidget {
  const _HiddenMagazineRow({
    required this.item,
    required this.busy,
    required this.disabled,
    required this.onUnhide,
  });

  final _HiddenMagazineItem item;
  final bool busy;
  final bool disabled;
  final VoidCallback onUnhide;

  @override
  Widget build(BuildContext context) {
    final meta = [
      if (item.publisherName.isNotEmpty) item.publisherName,
      if (item.issue.isNotEmpty) item.issue,
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Semantics(
            label: 'Hidden magazine marker',
            child: Container(
              width: 4,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.forest.withValues(alpha: 0.42),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Tooltip(
            message: 'Unhide ${item.title}',
            child: TextButton(
              onPressed: disabled || busy ? null : onUnhide,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.forest,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                minimumSize: const Size(64, 36),
              ),
              child: busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.forest,
                      ),
                    )
                  : const Text('Unhide'),
            ),
          ),
        ],
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

class _MarksPage extends StatefulWidget {
  const _MarksPage({required this.items});

  final List<_MarkItem> items;

  @override
  State<_MarksPage> createState() => _MarksPageState();
}

class _MarksPageState extends State<_MarksPage> {
  String _filter = 'all';

  List<_MarkItem> get _visibleItems {
    if (_filter == 'all') return widget.items;
    return [
      for (final item in widget.items)
        if (item.type == _filter) item,
    ];
  }

  void _openReader(_MarkItem item) {
    Navigator.pushNamed(
      context,
      '/reader',
      arguments: ReaderArgs(
        title: item.articleTitle,
        publisher: item.magazineTitle,
        magazineId: item.magazineId.isEmpty ? null : item.magazineId,
        articleId: item.articleId.isEmpty ? null : item.articleId,
        coverUrl: item.coverUrl.isEmpty ? null : item.coverUrl,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleItems = _visibleItems;

    return Scaffold(
      backgroundColor: AppColors.screen,
      body: SafeArea(
        child: Column(
          children: [
            const LogzineTopBar(showBack: true, showBell: false),
            Expanded(
              child: widget.items.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.fromLTRB(24, 8, 24, 24),
                      child: _EmptyStateCard(
                        message: '아직 저장한 문장이 없어요.\n리더에서 하이라이트를 남겨보세요.',
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Marked sentences',
                                style: logoStyle(
                                  size: 28,
                                  weight: FontWeight.w500,
                                  letterSpacingEm: 0.0,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                            _CountPill(
                              label:
                                  '${visibleItems.length}/${widget.items.length}',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(value: 'all', label: Text('All')),
                              ButtonSegment(
                                value: 'highlight',
                                label: Text('Highlight'),
                              ),
                              ButtonSegment(value: 'memo', label: Text('Memo')),
                            ],
                            selected: {_filter},
                            showSelectedIcon: false,
                            onSelectionChanged: (selection) {
                              setState(() => _filter = selection.first);
                            },
                            style: ButtonStyle(
                              visualDensity: VisualDensity.compact,
                              side: WidgetStateProperty.resolveWith(
                                (_) =>
                                    const BorderSide(color: AppColors.border),
                              ),
                              backgroundColor: WidgetStateProperty.resolveWith(
                                (states) =>
                                    states.contains(WidgetState.selected)
                                    ? AppColors.forest
                                    : AppColors.card,
                              ),
                              foregroundColor: WidgetStateProperty.resolveWith(
                                (states) =>
                                    states.contains(WidgetState.selected)
                                    ? AppColors.card
                                    : AppColors.ink,
                              ),
                              textStyle: const WidgetStatePropertyAll(
                                TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (visibleItems.isEmpty)
                          const _EmptyStateCard(message: '해당 유형의 저장 문장이 없어요.')
                        else
                          for (int i = 0; i < visibleItems.length; i++) ...[
                            if (i > 0) const SizedBox(height: 12),
                            _MarkedSentenceCard(
                              item: visibleItems[i],
                              onTap: () => _openReader(visibleItems[i]),
                            ),
                          ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.forest,
        ),
      ),
    );
  }
}

class _MarkedSentenceCard extends StatelessWidget {
  const _MarkedSentenceCard({required this.item, required this.onTap});

  final _MarkItem item;
  final VoidCallback onTap;

  String get _typeLabel {
    switch (item.type) {
      case 'memo':
        return 'Memo';
      default:
        return 'Highlight';
    }
  }

  IconData get _typeIcon {
    switch (item.type) {
      case 'memo':
        return Icons.sticky_note_2_outlined;
      default:
        return Icons.border_color_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = item.color;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: _SurfaceCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: 116,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          height: 26,
                          padding: const EdgeInsets.symmetric(horizontal: 9),
                          decoration: BoxDecoration(
                            color: AppColors.sageSoft,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _typeIcon,
                                size: 14,
                                color: AppColors.forest,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                _typeLabel,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.forest,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Text(
                          item.savedAt,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      item.quote,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.55,
                        fontWeight: FontWeight.w500,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.menu_book_outlined,
                          size: 15,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${item.articleTitle} · ${item.source}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.chevron_right,
                          size: 18,
                          color: AppColors.textMuted,
                        ),
                      ],
                    ),
                    if (item.note.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.screen,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          item.note,
                          style: const TextStyle(
                            fontSize: 12.5,
                            height: 1.4,
                            color: AppColors.body,
                          ),
                        ),
                      ),
                    ],
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

/// "Time read" 카드를 탭하면 뜨는 읽기 통계 페이지 — 이번 달 달력(읽은 날
/// 마킹) + 이번 주(월~일) 막대 그래프. 비로그인 → 빈 상태 (My탭 카드는 이미
/// 데모 문구를 보여주고 있어 여기까지 들어올 일은 드물지만, 방어적으로 빈
/// 데이터를 반환한다).
class _ReadingStatsPage extends StatefulWidget {
  const _ReadingStatsPage();

  @override
  State<_ReadingStatsPage> createState() => _ReadingStatsPageState();
}

class _ReadingStatsData {
  const _ReadingStatsData({required this.weekly, required this.monthly});

  final List<ReadingStatRecord> weekly;
  final List<MonthlyReadingRecord> monthly;
}

class _ReadingStatsPageState extends State<_ReadingStatsPage> {
  late final Future<_ReadingStatsData> _future = _load();

  static Future<_ReadingStatsData> _load() async {
    if (AuthService().currentUser == null) {
      return const _ReadingStatsData(weekly: [], monthly: []);
    }
    List<ReadingStatRecord> weekly = const [];
    try {
      weekly = await ReadingStatsService().fetchWeeklyStats();
    } catch (_) {
      weekly = const [];
    }
    List<MonthlyReadingRecord> monthly = const [];
    try {
      monthly = await ReadingStatsService().fetchMonthlyStats();
    } catch (_) {
      monthly = const [];
    }
    return _ReadingStatsData(weekly: weekly, monthly: monthly);
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
              child: FutureBuilder<_ReadingStatsData>(
                future: _future,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.forest),
                    );
                  }
                  final data = snapshot.data!;
                  if (data.weekly.isEmpty && data.monthly.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.fromLTRB(24, 8, 24, 24),
                      child: _EmptyStateCard(
                        message: '아직 읽은 기록이 없어요.\n리더에서 글을 읽으면 여기에 쌓여요.',
                      ),
                    );
                  }

                  final int weeklyTotal = data.weekly.fold(
                    0,
                    (total, r) => total + r.secondsRead,
                  );
                  final int weeklyMax = data.weekly
                      .map((r) => r.secondsRead)
                      .fold(1, (a, b) => b > a ? b : a);

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    children: [
                      const SectionHeader(title: 'This month'),
                      const SizedBox(height: 8),
                      Text(
                        _monthYearLabel(DateTime.now()),
                        style: logoStyle(
                          size: 22,
                          weight: FontWeight.w500,
                          letterSpacingEm: 0.0,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _SurfaceCard(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: _MonthlyCalendar(records: data.monthly),
                        ),
                      ),
                      const SizedBox(height: 26),
                      const SectionHeader(title: 'This week'),
                      const SizedBox(height: 4),
                      Text(
                        'Total ${_formatReadTime(weeklyTotal)}',
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _SurfaceCard(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              for (int i = 0; i < data.weekly.length; i++) ...[
                                if (i > 0) const SizedBox(height: 14),
                                _WeeklyBarRow(
                                  record: data.weekly[i],
                                  maxSeconds: weeklyMax,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
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

/// 이번 달 달력 그리드 — 요일 헤더(월~일) + 날짜 셀. 읽은 날(secondsRead > 0)은
/// forest 옅은 배경으로, 오늘은 테두리로 구분.
class _MonthlyCalendar extends StatelessWidget {
  const _MonthlyCalendar({required this.records});

  final List<MonthlyReadingRecord> records;

  static const List<String> _weekdayHeaders = [
    '월',
    '화',
    '수',
    '목',
    '금',
    '토',
    '일',
  ];

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) return const SizedBox.shrink();
    final DateTime firstDay = records.first.date;
    final DateTime today = DateTime.now();
    // firstDay.weekday: 월=1~일=7 → 1일 앞에 놓일 빈 칸 수
    final int leadingBlanks = firstDay.weekday - 1;

    return Column(
      children: [
        Row(
          children: [
            for (final label in _weekdayHeaders)
              Expanded(
                child: Center(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          children: [
            for (int i = 0; i < leadingBlanks; i++) const SizedBox.shrink(),
            for (final record in records)
              _CalendarDayCell(
                record: record,
                isToday: _isSameDate(record.date, today),
              ),
          ],
        ),
      ],
    );
  }

  static bool _isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({required this.record, required this.isToday});

  final MonthlyReadingRecord record;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final bool hasRead = record.secondsRead > 0;
    return Container(
      decoration: BoxDecoration(
        color: hasRead
            ? AppColors.forest.withValues(alpha: 0.16)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isToday
            ? Border.all(color: AppColors.forest, width: 1.4)
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        '${record.date.day}',
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: hasRead ? FontWeight.w700 : FontWeight.w400,
          color: hasRead ? AppColors.forest : AppColors.ink,
        ),
      ),
    );
  }
}

class _WeeklyBarRow extends StatelessWidget {
  const _WeeklyBarRow({required this.record, required this.maxSeconds});

  final ReadingStatRecord record;
  final int maxSeconds;

  @override
  Widget build(BuildContext context) {
    final double ratio = maxSeconds == 0 ? 0 : record.secondsRead / maxSeconds;
    return Row(
      children: [
        SizedBox(
          width: 36,
          child: Text(
            _weekdayLabelFor(record.date),
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: const Color(0xFFEFEBE0),
              valueColor: const AlwaysStoppedAnimation(AppColors.forest),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 54,
          child: Text(
            _formatReadTime(record.secondsRead),
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
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
        style: const TextStyle(fontSize: 12.5, color: AppColors.ink),
      ),
    );
  }
}
