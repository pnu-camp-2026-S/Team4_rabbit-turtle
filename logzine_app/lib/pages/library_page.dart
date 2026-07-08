import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/magazine.dart';
import '../models/reader_args.dart';
import '../services/auth_service.dart';
import '../services/magazine_service.dart';
import '../services/mark_service.dart';
import '../services/publisher_service.dart';
import '../services/saved_service.dart';
import '../theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/onboarding_widgets.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key, this.refreshToken = 0});

  final int refreshToken;

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

enum _LibrarySummary { magazines, publishers, saved }

typedef _PublisherItem = ({
  String id,
  String name,
  String imageUrl,
  String description,
});
typedef _SavedArticleItem = ({
  String articleId,
  String magazineId,
  String title,
  String publisher,
  String date,
  String imageUrl,
});
typedef _RecentViewedItem = ({
  String title,
  String publisher,
  int progress,
  String imageUrl,
});

/// 라이브러리 화면 데이터 묶음 — 매거진 목록 + 저장 글 + 이어 읽기 + 저장 개수.
class _LibraryData {
  const _LibraryData({
    required this.magazines,
    required this.savedArticles,
    required this.recentViewed,
    required this.savedCount,
    required this.followsCount,
    required this.followedPublishers,
    required this.isLoggedIn,
  });

  final List<Magazine> magazines;
  final List<_SavedArticleItem> savedArticles;
  final List<_RecentViewedItem> recentViewed;
  final int savedCount;
  final int followsCount;
  final List<_PublisherItem> followedPublishers;
  final bool isLoggedIn;
}

class _LibraryPageState extends State<LibraryPage> {
  /// [폴백] publishers 컬렉션이 비기 전까지 쓰는 데모 발행사 목록.
  /// id는 실 컬렉션이 채워지기 전까지 팔로우 문서 ID로 쓰는 안정적인 슬러그.
  static const List<_PublisherItem> _publishers = [
    (
      id: 'studio-log',
      name: 'Studio Log',
      imageUrl:
          'https://images.unsplash.com/photo-1493663284031-b7e3aefcae8e?auto=format&fit=crop&w=400&q=80',
      description:
          'Quiet interiors, lasting objects, and warm editorial photography.',
    ),
    (
      id: 'room-note',
      name: 'Room Note',
      imageUrl:
          'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&w=400&q=80',
      description:
          'A magazine about gentle rooms, slow mornings, and thoughtful living.',
    ),
    (
      id: 'oak-paper',
      name: 'Oak Paper',
      imageUrl:
          'https://images.unsplash.com/photo-1509423350716-97f9360b4e09?auto=format&fit=crop&w=400&q=80',
      description:
          'Independent print stories shaped around craft, paper, and tactile design.',
    ),
    (
      id: 'still-life',
      name: 'Still Life',
      imageUrl:
          'https://images.unsplash.com/photo-1519710164239-da123dc03ef4?auto=format&fit=crop&w=400&q=80',
      description:
          'Minimal domestic scenes and essays on how objects settle into memory.',
    ),
  ];

  /// 발행사 상세의 "Latest from this publisher" 임시 콘텐츠.
  /// Library의 Saved articles 탭에는 실제 저장 데이터만 보여준다.
  static const List<_SavedArticleItem> _demoSavedArticles = [
    (
      articleId: '',
      magazineId: '',
      title: 'The beauty of empty space',
      publisher: 'Openhouse',
      date: 'May 20, 2024',
      imageUrl:
          'https://images.unsplash.com/photo-1519710164239-da123dc03ef4?auto=format&fit=crop&w=400&q=80',
    ),
    (
      articleId: '',
      magazineId: '',
      title: 'A table, a chair, and the light',
      publisher: 'ARK Journal',
      date: 'May 18, 2024',
      imageUrl:
          'https://images.unsplash.com/photo-1503602642458-232111445657?auto=format&fit=crop&w=400&q=80',
    ),
  ];

  /// [폴백] 읽기 진행률이 없거나(비로그인 포함)/조회 실패 시 사용하는 데모 목록.
  static const List<_RecentViewedItem> _demoRecentViewed = [
    (
      title: 'CEREAL',
      publisher: 'Cereal Magazine',
      progress: 68,
      imageUrl:
          'https://images.unsplash.com/photo-1519710164239-da123dc03ef4?auto=format&fit=crop&w=600&q=80',
    ),
    (
      title: 'Quiet Materials',
      publisher: 'Studio Log',
      progress: 42,
      imageUrl:
          'https://images.unsplash.com/photo-1493809842364-78817add7ffb?auto=format&fit=crop&w=600&q=80',
    ),
    (
      title: 'ROOM NOTES',
      publisher: 'Room Note',
      progress: 15,
      imageUrl:
          'https://images.unsplash.com/photo-1502005229762-cf1b2da7c5d6?auto=format&fit=crop&w=600&q=80',
    ),
  ];

  /// [폴백] 비로그인일 때만 노출하는 데모 팔로우 수.
  static const int _demoFollowsCount = 8;

  late Future<_LibraryData> _libraryFuture = _loadLibrary();

  @override
  void didUpdateWidget(covariant LibraryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      _refreshLibrary();
    }
  }

  void _refreshLibrary() {
    if (!mounted) return;
    setState(() {
      _libraryFuture = _loadLibrary();
    });
  }

  static Future<_LibraryData> _loadLibrary() async {
    List<Magazine> magazines;
    try {
      magazines = await MagazineService().fetchMagazines();
      if (magazines.isEmpty) magazines = kMagazines;
    } catch (_) {
      magazines = kMagazines;
    }
    final magazineById = {for (final m in magazines) m.id: m};

    // 폴백 정책: Saved articles는 로그인/비로그인 모두 실제 저장 데이터만
    // 보여준다. 저장 데이터가 없거나 조회에 실패하면 데모가 아니라 빈 상태.
    final bool isLoggedIn = AuthService().currentUser != null;

    List<_SavedArticleItem> savedArticles = const [];
    int savedCount = 0;
    if (isLoggedIn) {
      try {
        final savedDocs = await SavedService().fetchSaved(limit: null);
        savedArticles = [for (final doc in savedDocs) _savedItemFromDoc(doc)];
        savedCount = savedArticles.length;
      } catch (_) {
        savedArticles = const [];
        savedCount = 0;
      }
    }

    int followsCount = _demoFollowsCount;
    List<_PublisherItem> followedPublishers = _publishers;
    if (isLoggedIn) {
      try {
        final followDocs = await PublisherService().fetchFollows();
        followsCount = followDocs.length;
        followedPublishers = [
          for (final doc in followDocs) _publisherItemFromDoc(doc),
        ];
      } catch (_) {
        followsCount = 0;
        followedPublishers = const [];
      }
    }

    List<_RecentViewedItem> recentViewed = _demoRecentViewed;
    if (isLoggedIn) {
      try {
        final progressList = await MarkService().fetchProgressList(limit: 10);
        final resolved = await Future.wait(
          progressList.map((p) => _recentItemFromProgress(p, magazineById)),
        );
        recentViewed = resolved.whereType<_RecentViewedItem>().toList();
      } catch (_) {
        recentViewed = const [];
      }
    }

    return _LibraryData(
      magazines: magazines,
      savedArticles: savedArticles,
      recentViewed: recentViewed,
      savedCount: savedCount,
      followsCount: followsCount,
      followedPublishers: followedPublishers,
      isLoggedIn: isLoggedIn,
    );
  }

  static _PublisherItem _publisherItemFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return (
      id: doc.id,
      name: data['publisherName'] as String? ?? '',
      imageUrl: data['logoUrl'] as String? ?? '',
      description: '',
    );
  }

  static _SavedArticleItem _savedItemFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final Timestamp? savedAt = data['savedAt'] as Timestamp?;
    return (
      articleId: doc.id,
      magazineId: data['magazineId'] as String? ?? '',
      title: data['articleTitle'] as String? ?? '(제목 없음)',
      publisher: data['magazineTitle'] as String? ?? '',
      date: savedAt == null ? '' : _formatDate(savedAt.toDate()),
      imageUrl: data['coverUrl'] as String? ?? '',
    );
  }

  static String _formatDate(DateTime date) =>
      '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';

  /// progress 문서 1건 → 표시용 아이템. 대상 매거진을 카탈로그에서 찾을 수
  /// 없으면(삭제됨 등) null — 호출부에서 건너뛴다.
  static Future<_RecentViewedItem?> _recentItemFromProgress(
    ProgressRecord record,
    Map<String, Magazine> magazineById,
  ) async {
    final magazine = magazineById[record.magazineId];
    if (magazine == null) return null;

    String title = magazine.title;
    try {
      final article = await MagazineService().fetchArticleById(
        magazineId: record.magazineId,
        articleId: record.articleId,
      );
      if (article != null && article.title.isNotEmpty) title = article.title;
    } catch (_) {
      // 아티클 조회 실패 — 매거진 제목으로 대체
    }

    return (
      title: title,
      publisher: magazine.title,
      progress: record.percent.clamp(0, 100),
      imageUrl: magazine.coverUrl,
    );
  }

  _LibrarySummary _selectedSummary = _LibrarySummary.magazines;

  /// 발행사 상세로 이동 — 거기서 팔로우/언팔로우가 일어날 수 있으므로
  /// 돌아오면 목록을 새로 불러온다 (home_page의 _openMagazine과 동일 패턴).
  Future<void> _openPublisher(
    BuildContext context,
    _PublisherItem publisher,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _PublisherPage(item: publisher)),
    );
    if (mounted) {
      setState(() {
        _libraryFuture = _loadLibrary();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screen,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 4),
            const LogzineTopBar(
              showBell: false,
              showSettings: false,
              showDivider: true,
            ),
            Expanded(
              child: FutureBuilder<_LibraryData>(
                future: _libraryFuture,
                builder: (context, snapshot) {
                  final data = snapshot.data;
                  final magazines = data?.magazines ?? const <Magazine>[];
                  final initialSavedArticles =
                      data?.savedArticles ?? const <_SavedArticleItem>[];
                  final recentViewed = data?.recentViewed ?? _demoRecentViewed;
                  final followsCount = data?.followsCount ?? _demoFollowsCount;
                  final followedPublishers =
                      data?.followedPublishers ?? _publishers;
                  final isLoggedIn =
                      data?.isLoggedIn ?? AuthService().currentUser != null;

                  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: isLoggedIn
                        ? SavedService().watchSaved()
                        : const Stream.empty(),
                    builder: (context, savedSnapshot) {
                      final savedArticles = savedSnapshot.hasData
                          ? [
                              for (final doc in savedSnapshot.data!.docs)
                                _savedItemFromDoc(doc),
                            ]
                          : initialSavedArticles;

                      return _buildLibraryContent(
                        context: context,
                        magazines: magazines,
                        savedArticles: savedArticles,
                        recentViewed: recentViewed,
                        followsCount: followsCount,
                        followedPublishers: followedPublishers,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLibraryContent({
    required BuildContext context,
    required List<Magazine> magazines,
    required List<_SavedArticleItem> savedArticles,
    required List<_RecentViewedItem> recentViewed,
    required int followsCount,
    required List<_PublisherItem> followedPublishers,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          const PageTitleHeader(title: 'My Library'),
          const SizedBox(height: 4),
          const Text(
            'Subscriptions, follows, and saved reading in one place.',
            style: TextStyle(fontSize: 13.5, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          _SummaryCardGroup(
            selected: _selectedSummary,
            magazineCount: magazines.length,
            savedCount: savedArticles.length,
            followsCount: followsCount,
            onSelect: (summary) {
              setState(() => _selectedSummary = summary);
            },
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: _LibraryDetailPanel(
              key: ValueKey(_selectedSummary),
              selected: _selectedSummary,
              magazines: magazines,
              publishers: followedPublishers,
              savedArticles: savedArticles,
              onPublisherTap: (publisher) => _openPublisher(context, publisher),
              onSavedArticleReturn: _refreshLibrary,
            ),
          ),
          const SizedBox(height: 26),
          SectionHeader(
            title: 'Recently viewed',
            onViewAll: recentViewed.isEmpty
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => _RecentViewedPage(items: recentViewed),
                      ),
                    );
                  },
          ),
          const SizedBox(height: 12),
          if (recentViewed.isEmpty)
            const _EmptyStateCard(
              message: '아직 읽은 글이 없어요.\n매거진을 펼쳐보면 여기에 기록이 남아요.',
            )
          else
            _RecentShelf(items: recentViewed),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _SummaryCardGroup extends StatelessWidget {
  const _SummaryCardGroup({
    required this.selected,
    required this.magazineCount,
    required this.savedCount,
    required this.followsCount,
    required this.onSelect,
  });

  final _LibrarySummary selected;
  final int magazineCount;
  final int savedCount;
  final int followsCount;
  final ValueChanged<_LibrarySummary> onSelect;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _SummaryItem(
                label: 'Magazine subs',
                value: '$magazineCount',
                icon: Icons.menu_book_outlined,
                active: selected == _LibrarySummary.magazines,
                onTap: () => onSelect(_LibrarySummary.magazines),
              ),
            ),
            const VerticalDivider(color: AppColors.border, width: 1),
            Expanded(
              child: _SummaryItem(
                label: 'Publisher follows',
                value: '$followsCount',
                icon: Icons.person_outline,
                active: selected == _LibrarySummary.publishers,
                onTap: () => onSelect(_LibrarySummary.publishers),
              ),
            ),
            const VerticalDivider(color: AppColors.border, width: 1),
            Expanded(
              child: _SummaryItem(
                label: 'Saved articles',
                value: '$savedCount',
                icon: Icons.bookmark_border,
                active: selected == _LibrarySummary.saved,
                onTap: () => onSelect(_LibrarySummary.saved),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.all(6),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? AppColors.forest : Colors.transparent,
            width: active ? 1.4 : 1,
          ),
          boxShadow: active
              ? const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ]
              : const [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 32,
              child: Center(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                    color: active ? AppColors.forest : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 30,
              child: Center(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: active ? AppColors.forest : AppColors.ink,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 20,
              child: Icon(
                icon,
                size: 17,
                color: active ? AppColors.forest : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LibraryDetailPanel extends StatelessWidget {
  const _LibraryDetailPanel({
    super.key,
    required this.selected,
    required this.magazines,
    required this.publishers,
    required this.savedArticles,
    required this.onPublisherTap,
    required this.onSavedArticleReturn,
  });

  final _LibrarySummary selected;
  final List<Magazine> magazines;
  final List<_PublisherItem> publishers;
  final List<_SavedArticleItem> savedArticles;
  final ValueChanged<_PublisherItem> onPublisherTap;
  final VoidCallback onSavedArticleReturn;

  @override
  Widget build(BuildContext context) {
    switch (selected) {
      case _LibrarySummary.magazines:
        return _SurfaceCard(
          child: Column(
            children: [
              for (int i = 0; i < magazines.length; i++) ...[
                if (i > 0) const Divider(color: AppColors.border, height: 1),
                _SubscriptionTile(magazine: magazines[i]),
              ],
            ],
          ),
        );
      case _LibrarySummary.publishers:
        if (publishers.isEmpty) {
          return const _EmptyStateCard(
            message: '아직 팔로우한 발행사가 없어요.\n발행사 프로필에서 Follow를 눌러보세요.',
          );
        }
        return _SurfaceCard(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Wrap(
              spacing: 18,
              runSpacing: 18,
              children: [
                for (final publisher in publishers)
                  _PublisherBubble(
                    item: publisher,
                    onTap: () => onPublisherTap(publisher),
                  ),
              ],
            ),
          ),
        );
      case _LibrarySummary.saved:
        if (savedArticles.isEmpty) {
          return const _EmptyStateCard(
            message: '아직 저장한 글이 없어요.\n리더에서 북마크를 눌러 저장해보세요.',
          );
        }
        return _SurfaceCard(
          child: Column(
            children: [
              for (int i = 0; i < savedArticles.length; i++) ...[
                if (i > 0) const Divider(color: AppColors.border, height: 1),
                _SavedArticleTile(
                  item: savedArticles[i],
                  onReturn: onSavedArticleReturn,
                ),
              ],
            ],
          ),
        );
    }
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
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: child,
      ),
    );
  }
}

class _SubscriptionTile extends StatelessWidget {
  const _SubscriptionTile({required this.magazine});

  final Magazine magazine;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () =>
          Navigator.pushNamed(context, '/discover/why', arguments: magazine),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            SizedBox(
              width: 58,
              height: 78,
              child: NetworkPhoto(url: magazine.coverUrl, radius: 10),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    magazine.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    magazine.issue,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    magazine.tagline,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
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
    );
  }
}

class _PublisherBubble extends StatelessWidget {
  const _PublisherBubble({required this.item, required this.onTap});

  final _PublisherItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        width: 86,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: ClipOval(
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: NetworkPhoto(url: item.imageUrl, radius: 0),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.name,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5, color: AppColors.ink),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedArticleTile extends StatelessWidget {
  const _SavedArticleTile({required this.item, this.onReturn});

  final _SavedArticleItem item;
  final VoidCallback? onReturn;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        await Navigator.pushNamed(
          context,
          '/reader',
          arguments: ReaderArgs(
            title: item.title,
            publisher: item.publisher,
            magazineId: item.magazineId.isEmpty ? null : item.magazineId,
            articleId: item.articleId.isEmpty ? null : item.articleId,
            coverUrl: item.imageUrl.isEmpty ? null : item.imageUrl,
          ),
        );
        onReturn?.call();
      },
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
            onTap: () => Navigator.pushNamed(context, '/reader'),
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
                        '${item.progress}% read',
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

class _PublisherPage extends StatelessWidget {
  const _PublisherPage({required this.item});

  final _PublisherItem item;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screen,
      body: SafeArea(
        child: Column(
          children: [
            const LogzineTopBar(showBack: true, showBell: false),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ClipOval(
                          child: SizedBox(
                            width: 78,
                            height: 78,
                            child: NetworkPhoto(url: item.imageUrl, radius: 0),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: logoStyle(
                                  size: 30,
                                  weight: FontWeight.w600,
                                  letterSpacingEm: 0.02,
                                  color: AppColors.ink,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                item.description,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  height: 1.55,
                                  color: AppColors.body,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _FollowButton(
                      publisherId: item.id,
                      publisherName: item.name,
                      logoUrl: item.imageUrl,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Latest from this publisher',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (final article
                        in _LibraryPageState._demoSavedArticles) ...[
                      _SavedArticleTile(item: article),
                      const SizedBox(height: 10),
                    ],
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

/// 발행사 상세의 팔로우 토글 버튼. 팔로우 여부에 따라 텍스트/스타일이 바뀐다
/// (미팔로우: forest 채움 "Follow" / 팔로우 중: 아웃라인 "Following").
class _FollowButton extends StatefulWidget {
  const _FollowButton({
    required this.publisherId,
    required this.publisherName,
    required this.logoUrl,
  });

  final String publisherId;
  final String publisherName;
  final String logoUrl;

  @override
  State<_FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<_FollowButton> {
  bool _following = false;

  @override
  void initState() {
    super.initState();
    _loadFollowing();
  }

  Future<void> _loadFollowing() async {
    final following = await PublisherService().isFollowing(widget.publisherId);
    if (!mounted) return;
    setState(() => _following = following);
  }

  Future<void> _toggle() async {
    final bool nowFollowing = !_following;
    setState(() => _following = nowFollowing);
    try {
      if (nowFollowing) {
        await PublisherService().follow(
          publisherId: widget.publisherId,
          publisherName: widget.publisherName,
          logoUrl: widget.logoUrl,
        );
      } else {
        await PublisherService().unfollow(widget.publisherId);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _following = !nowFollowing);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('처리 중 문제가 발생했어요')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_following) {
      return OutlinedButton(
        onPressed: _toggle,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          side: const BorderSide(color: AppColors.border),
          minimumSize: const Size(0, 40),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        child: const Text('Following'),
      );
    }
    return FilledButton(
      onPressed: _toggle,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.forest,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      child: const Text('Follow'),
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
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                itemCount: items.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _SurfaceCard(
                    child: InkWell(
                      onTap: () => Navigator.pushNamed(context, '/reader'),
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
                                  const SizedBox(height: 6),
                                  Text(
                                    '${item.progress}% read',
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
