import 'package:flutter/material.dart';

import '../models/reader_args.dart';
import '../theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/onboarding_widgets.dart';

/// 저장 탭 — 북마크한 글 + 매거진을 가로질러 모은 하이라이트.
class SavedPage extends StatelessWidget {
  const SavedPage({super.key});

  /// (제목, 발행사, 날짜, 썸네일)
  static const List<(String, String, String, String)> _saved = [
    (
      'The beauty of empty space',
      'Openhouse',
      'May 20, 2024',
      'https://images.unsplash.com/photo-1519710164239-da123dc03ef4?auto=format&fit=crop&w=400&q=80',
    ),
    (
      'A table, a chair, and the light',
      'ARK Journal',
      'May 18, 2024',
      'https://images.unsplash.com/photo-1503602642458-232111445657?auto=format&fit=crop&w=400&q=80',
    ),
    (
      'Quiet Materials',
      'Studio Log',
      'May 12, 2024',
      'https://images.unsplash.com/photo-1493809842364-78817add7ffb?auto=format&fit=crop&w=400&q=80',
    ),
  ];

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
                          fontSize: 13.5, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 20),

                    // 저장한 글
                    SectionHeader(title: 'Saved articles', onViewAll: () {}),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          for (int i = 0; i < _saved.length; i++) ...[
                            if (i > 0)
                              const Divider(
                                  color: AppColors.border, height: 1),
                            _SavedTile(item: _saved[i]),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 하이라이트 모아보기
                    SectionHeader(
                        title: 'Marked passages', onViewAll: () {}),
                    const SizedBox(height: 4),
                    const Text(
                      '매거진을 읽으며 밑줄 친 문장들',
                      style: TextStyle(
                          fontSize: 12.5, color: AppColors.textMuted),
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
  const _SavedTile({required this.item});

  final (String, String, String, String) item;

  @override
  Widget build(BuildContext context) {
    final (title, publisher, date, thumb) = item;
    return InkWell(
      onTap: () => Navigator.pushNamed(
        context,
        '/reader',
        arguments: ReaderArgs(title: title, publisher: publisher),
      ),
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
                    '$publisher · $date',
                    style: const TextStyle(
                        fontSize: 12.5, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.bookmark, size: 20, color: AppColors.forest),
          ],
        ),
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
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right,
                  size: 16, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
