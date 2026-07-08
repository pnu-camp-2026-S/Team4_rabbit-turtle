import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/reader_args.dart';
import '../services/saved_service.dart';
import '../theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/onboarding_widgets.dart';

/// 저장 탭 — 북마크한 글 + 매거진을 가로질러 모은 하이라이트.
class SavedPage extends StatefulWidget {
  const SavedPage({super.key});

  @override
  State<SavedPage> createState() => _SavedPageState();
}

class _SavedPageState extends State<SavedPage> {
  int _refreshToken = 0;

  void _refresh() {
    _refreshToken++;
  }

  /// (인용문, 하이라이트 색, 매거진, 발행사, 페이지)
  static const List<(String, Color, String, String, int)> _marks = [
    (
      'When light, texture, and proportion align, the quiet becomes a language.',
      Color(0xFFE9C46A),
      'Quiet Materials',
      'Studio Log',
      4,
    ),
    (
      'Objects that age well tell slower stories.',
      Color(0xFFA3C9A8),
      'ROOM NOTE',
      'Room Note Studio',
      12,
    ),
    (
      'A shelf is a diary of what we choose to keep.',
      Color(0xFFC98B9B),
      'CEREAL',
      'Cereal Magazine',
      8,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screen,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              const LogzineTopBar(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),
                    Text(
                      'Saved',
                      style: logoStyle(
                        size: 32,
                        weight: FontWeight.w500,
                        letterSpacingEm: 0.0,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '북마크한 글과 밑줄 친 문장이 여기에 모여요.',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 저장한 글
                    const SectionHeader(title: 'Saved articles'),
                    const SizedBox(height: 10),
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      key: ValueKey(_refreshToken),
                      stream: SavedService().watchSaved(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return _MessageCard(
                            message: '저장한 글을 불러오지 못했어요.',
                            actionLabel: 'Retry',
                            onAction: () => setState(_refresh),
                          );
                        }
                        if (snapshot.connectionState ==
                                ConnectionState.waiting &&
                            !snapshot.hasData) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 28),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppColors.forest,
                              ),
                            ),
                          );
                        }
                        final docs = snapshot.data?.docs ?? [];
                        if (docs.isEmpty) {
                          return const _MessageCard(
                            message: '아직 저장한 글이 없어요.\n리더에서 북마크를 눌러 저장해보세요.',
                          );
                        }
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            children: [
                              for (int i = 0; i < docs.length; i++) ...[
                                if (i > 0)
                                  const Divider(
                                    color: AppColors.border,
                                    height: 1,
                                  ),
                                _SavedTile(doc: docs[i]),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // 하이라이트 모아보기
                    SectionHeader(title: 'Marked passages', onViewAll: () {}),
                    const SizedBox(height: 4),
                    const Text(
                      '매거진을 읽으며 밑줄 친 문장들',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (final mark in _marks) ...[
                      _MarkCard(mark: mark),
                      const SizedBox(height: 10),
                    ],
                    const SizedBox(height: 10),
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

/// 저장한 글 한 줄.
class _SavedTile extends StatelessWidget {
  const _SavedTile({required this.doc});

  final QueryDocumentSnapshot<Map<String, dynamic>> doc;

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final String title =
        data['articleTitle'] as String? ?? 'Unavailable article';
    final String magazine = data['magazineTitle'] as String? ?? '';
    final String magazineId = data['magazineId'] as String? ?? '';
    final String thumb = data['coverUrl'] as String? ?? '';
    final Timestamp? savedAt = data['savedAt'] as Timestamp?;
    final String date = savedAt == null
        ? ''
        : '${savedAt.toDate().year}.'
              '${savedAt.toDate().month.toString().padLeft(2, '0')}.'
              '${savedAt.toDate().day.toString().padLeft(2, '0')}';

    return InkWell(
      onTap: () {
        if (magazineId.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This article is unavailable.')),
          );
          return;
        }
        Navigator.pushNamed(
          context,
          '/reader',
          arguments: ReaderArgs(
            title: title,
            publisher: magazine,
            magazineId: magazineId,
            articleId: doc.id,
            coverUrl: thumb.isEmpty ? null : thumb,
            initialSaved: true,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            SizedBox(
              width: 58,
              height: 58,
              child: NetworkPhoto(url: thumb, radius: 8),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    magazine.isEmpty ? date : '$magazine · $date',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () async {
                try {
                  await SavedService().unsave(doc.id);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Removed from saved articles'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                } catch (_) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('저장 해제 중 문제가 발생했어요')),
                  );
                }
              },
              tooltip: 'Remove from saved articles',
              icon: const Icon(
                Icons.bookmark,
                size: 20,
                color: AppColors.forest,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.message, this.actionLabel, this.onAction});

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

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
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onAction,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.ink,
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

/// 하이라이트 인용 카드 — 색상 바 + 세리프 인용문 + 출처.
class _MarkCard extends StatelessWidget {
  const _MarkCard({required this.mark});

  final (String, Color, String, String, int) mark;

  @override
  Widget build(BuildContext context) {
    final (quote, color, magazine, publisher, page) = mark;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => Navigator.pushNamed(
          context,
          '/reader',
          arguments: ReaderArgs(title: magazine, publisher: publisher),
        ),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: 52,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '“$quote”',
                      style: logoStyle(
                        size: 16,
                        weight: FontWeight.w500,
                        letterSpacingEm: 0.0,
                        color: AppColors.ink,
                      ).copyWith(height: 1.45),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$magazine · p.$page',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
