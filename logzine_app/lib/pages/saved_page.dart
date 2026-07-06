import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/common_widgets.dart';
import '../models/reader_args.dart';
import '../widgets/onboarding_widgets.dart';

/// 저장 탭 — 북마크한 글과 하이라이트 모음.
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
                      '북마크한 글이 여기에 모여요.',
                      style: TextStyle(
                          fontSize: 13.5, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 18),
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
                    const SizedBox(height: 20),
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
