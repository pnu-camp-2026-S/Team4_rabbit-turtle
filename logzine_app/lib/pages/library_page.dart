import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/magazine.dart';
import '../models/reader_args.dart';
import '../services/auth_service.dart';
import '../services/magazine_service.dart';
import '../services/publisher_service.dart';
import '../services/saved_service.dart';
import '../theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/onboarding_widgets.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

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

/// 라이브러리 화면 데이터 묶음 — 매거진 목록 + 저장 글 + 저장 개수.
class _LibraryData {
  const _LibraryData({
    required this.magazines,
    required this.savedArticles,
    required this.savedCount,
    required this.followsCount,
    required this.followedPublishers,
  });

  final List<Magazine> magazines;
  final List<_SavedArticleItem> savedArticles;
  final int savedCount;
  final int followsCount;
  final List<_PublisherItem> followedPublishers;
}

class _LibraryPageState extends State<LibraryPage> {
  /// [폴백] publishers 컬렉션이 비기 전까지 쓰는 데모 발행사 목록.
  /// id는 실 컬렉션이 채워지기 전까지 팔로우 문서 ID로 쓰는 안정적인 슬러그.
  /// 아바타는 이모지 대신 Unsplash 사진(Flutter Web에서 이모지 폰트가 없어
  /// 물음표로 깨지는 문제 회피)으로 되돌렸다.
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
    (
      id: 'the-pantry',
      name: 'The Pantry',
      imageUrl:
          'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?auto=format&fit=crop&w=400&q=80',
      description:
          'Recipes, corner cafés, and the quiet ritual of a shared table.',
    ),
    (
      id: 'night-index',
      name: 'Night Index',
      imageUrl:
          'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?auto=format&fit=crop&w=400&q=80',
      description: 'Fashion, sound, and the city after dark.',
    ),
    (
      id: 'field-notes',
      name: 'Field Notes',
      imageUrl:
          'https://images.unsplash.com/photo-1517649763962-0c623066013b?auto=format&fit=crop&w=400&q=80',
      description: 'Movement, breath, and stories from the trail.',
    ),
  ];

  static const List<_SavedArticleItem> _emptySavedArticles = [];

  /// [폴백] 비로그인일 때만 노출하는 데모 팔로우 수.
  static const int _demoFollowsCount = 8;

  late Future<_LibraryData> _libraryFuture = _loadLibrary();

  static Future<_LibraryData> _loadLibrary() async {
    List<Magazine> magazines;
    try {
      magazines = await MagazineService().fetchMagazines();
      if (magazines.isEmpty) magazines = kMagazines;
    } catch (_) {
      magazines = kMagazines;
    }
    // 폴백 정책: 비로그인 → 항상 데모(둘러보기 쇼케이스), 유지.
    // 로그인 → 항상 실데이터만. 조회가 성공해서 빈 값이면 빈 상태를,
    // 조회 자체가 실패(예외)해도 데모로 대체하지 않고 빈 상태로 —
    // 로그인 사용자에게 남의 데모 데이터를 보여주는 것이 가장 나쁨.
    final bool isLoggedIn = AuthService().currentUser != null;

    List<_SavedArticleItem> savedArticles = _emptySavedArticles;
    int savedCount = 0;
    if (isLoggedIn) {
      try {
        final savedDocs = await SavedService().fetchSaved(limit: 20);
        savedArticles = [for (final doc in savedDocs) _savedItemFromDoc(doc)];
      } catch (_) {
        savedArticles = const [];
      }
      try {
        savedCount = await SavedService().fetchSavedCount();
      } catch (_) {
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

    return _LibraryData(
      magazines: magazines,
      savedArticles: savedArticles,
      savedCount: savedCount,
      followsCount: followsCount,
      followedPublishers: followedPublishers,
    );
  }

  static _PublisherItem _publisherItemFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return (
      id: doc.id,
      name: data['publisherName'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      description: '',
    );
  }

  static _SavedArticleItem _savedItemFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final Timestamp? savedAt = data['savedAt'] as Timestamp?;
    return (
      title: data['articleTitle'] as String? ?? '(제목 없음)',
      publisher: data['magazineTitle'] as String? ?? '',
      articleId: doc.id,
      magazineId: data['magazineId'] as String? ?? '',
      date: savedAt == null ? '' : _formatDate(savedAt.toDate()),
      imageUrl: data['coverUrl'] as String? ?? '',
    );
  }

  static List<_SavedArticleItem> _savedItemsFromSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) => [for (final doc in snapshot.docs) _savedItemFromDoc(doc)];

  static String _formatDate(DateTime date) =>
      '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';

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
      setState(() => _libraryFuture = _loadLibrary());
    }
  }

  void _openSavedArticle(_SavedArticleItem item) {
    if (item.articleId.isEmpty || item.magazineId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This article is unavailable.')),
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
        initialSaved: true,
      ),
    );
  }

  Future<void> _unsaveArticle(_SavedArticleItem item) async {
    if (item.articleId.isEmpty) return;
    try {
      await SavedService().unsave(item.articleId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Removed from saved articles'),
          duration: Duration(seconds: 1),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('저장 해제 중 문제가 발생했어요')));
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
                  final bool isLoggedIn = AuthService().currentUser != null;
                  final savedArticles =
                      data?.savedArticles ?? _emptySavedArticles;
                  final savedCount = data?.savedCount ?? 0;
                  final followsCount = data?.followsCount ?? _demoFollowsCount;
                  final followedPublishers =
                      data?.followedPublishers ?? _publishers;

                  Widget buildContent({
                    required List<_SavedArticleItem> visibleSavedArticles,
                    required int visibleSavedCount,
                    bool savedFailed = false,
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
                            style: TextStyle(
                              fontSize: 13.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _SummaryCardGroup(
                            selected: _selectedSummary,
                            magazineCount: magazines.length,
                            savedCount: visibleSavedCount,
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
                              savedArticles: visibleSavedArticles,
                              savedFailed: savedFailed,
                              onPublisherTap: (publisher) =>
                                  _openPublisher(context, publisher),
                              onSavedTap: (item) => _openSavedArticle(item),
                              onSavedUnsave: (item) => _unsaveArticle(item),
                              onRetrySaved: () => setState(
                                () => _libraryFuture = _loadLibrary(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    );
                  }

                  if (!isLoggedIn) {
                    return buildContent(
                      visibleSavedArticles: savedArticles,
                      visibleSavedCount: savedCount,
                    );
                  }

                  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: SavedService().watchSaved(),
                    builder: (context, savedSnapshot) {
                      if (savedSnapshot.hasError) {
                        return buildContent(
                          visibleSavedArticles: const [],
                          visibleSavedCount: 0,
                          savedFailed: true,
                        );
                      }
                      if (!savedSnapshot.hasData) {
                        return buildContent(
                          visibleSavedArticles: savedArticles,
                          visibleSavedCount: savedCount,
                        );
                      }
                      final liveSaved = _savedItemsFromSnapshot(
                        savedSnapshot.data!,
                      );
                      return buildContent(
                        visibleSavedArticles: liveSaved,
                        visibleSavedCount: liveSaved.length,
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
    required this.savedFailed,
    required this.onPublisherTap,
    required this.onSavedTap,
    required this.onSavedUnsave,
    required this.onRetrySaved,
  });

  final _LibrarySummary selected;
  final List<Magazine> magazines;
  final List<_PublisherItem> publishers;
  final List<_SavedArticleItem> savedArticles;
  final bool savedFailed;
  final ValueChanged<_PublisherItem> onPublisherTap;
  final ValueChanged<_SavedArticleItem> onSavedTap;
  final ValueChanged<_SavedArticleItem> onSavedUnsave;
  final VoidCallback onRetrySaved;

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
        if (savedFailed) {
          return _ErrorStateCard(
            message: '저장한 글을 불러오지 못했어요.',
            onRetry: onRetrySaved,
          );
        }
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
                  onTap: () => onSavedTap(savedArticles[i]),
                  onUnsave: () => onSavedUnsave(savedArticles[i]),
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

class _ErrorStateCard extends StatelessWidget {
  const _ErrorStateCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textMuted,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onRetry,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.ink,
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Retry'),
          ),
        ],
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
              child: _PublisherAvatar(imageUrl: item.imageUrl, size: 64),
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

/// 발행사 아바타 — 사진(NetworkPhoto) 대신 원형 배경색 + 이모지로 통일.
/// publishers 컬렉션에 실 로고 데이터가 아직 없어(로드맵 #3) 이모지로
/// 대체하고, 색은 발행사별 고정 스와치(_publishers)를 그대로 쓴다.
class _PublisherAvatar extends StatelessWidget {
  const _PublisherAvatar({required this.imageUrl, this.size = 64});

  final String imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: NetworkPhoto(url: imageUrl, radius: 0),
      ),
    );
  }
}

class _SavedArticleTile extends StatelessWidget {
  const _SavedArticleTile({
    required this.item,
    required this.onTap,
    required this.onUnsave,
  });

  final _SavedArticleItem item;
  final VoidCallback onTap;
  final VoidCallback onUnsave;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
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
            IconButton(
              onPressed: onUnsave,
              tooltip: 'Remove from saved articles',
              icon: const Icon(
                Icons.bookmark,
                size: 18,
                color: AppColors.forest,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PublisherPage extends StatefulWidget {
  const _PublisherPage({required this.item});

  final _PublisherItem item;

  @override
  State<_PublisherPage> createState() => _PublisherPageState();
}

class _PublisherPageState extends State<_PublisherPage> {
  late final Future<List<Magazine>> _magazinesFuture = _loadMagazines();

  Future<List<Magazine>> _loadMagazines() async {
    try {
      return await MagazineService().fetchMagazinesByPublisher(widget.item.id);
    } catch (_) {
      return const [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final _PublisherItem item = widget.item;
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
                        _PublisherAvatar(imageUrl: item.imageUrl, size: 78),
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
                      imageUrl: item.imageUrl,
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
                    FutureBuilder<List<Magazine>>(
                      future: _magazinesFuture,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppColors.forest,
                              ),
                            ),
                          );
                        }
                        final magazines = snapshot.data!;
                        if (magazines.isEmpty) {
                          return const _EmptyStateCard(
                            message: '아직 이 발행사가 발행한 매거진이 없어요.',
                          );
                        }
                        return _SurfaceCard(
                          child: Column(
                            children: [
                              for (int i = 0; i < magazines.length; i++) ...[
                                if (i > 0)
                                  const Divider(
                                    color: AppColors.border,
                                    height: 1,
                                  ),
                                _SubscriptionTile(magazine: magazines[i]),
                              ],
                            ],
                          ),
                        );
                      },
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

/// 발행사 상세의 팔로우 토글 버튼. 팔로우 여부에 따라 텍스트/스타일이 바뀐다
/// (미팔로우: forest 채움 "Follow" / 팔로우 중: 아웃라인 "Following").
class _FollowButton extends StatefulWidget {
  const _FollowButton({
    required this.publisherId,
    required this.publisherName,
    required this.imageUrl,
  });

  final String publisherId;
  final String publisherName;
  final String imageUrl;

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
          imageUrl: widget.imageUrl,
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
