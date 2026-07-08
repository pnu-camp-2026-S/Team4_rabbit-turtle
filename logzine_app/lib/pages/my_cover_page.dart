import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/cover_art_service.dart';
import '../services/user_service.dart';
import '../theme.dart';

/// "이번 주 나의 표지" — 취향으로 만든 나만의 매거진 커버.
/// Gemini 생성 이미지가 있으면 그 위에 제호를 얹고,
/// 없으면(쿼터 등) 순수 타이포그래피 표지로 조판한다.
class MyCoverPage extends StatefulWidget {
  const MyCoverPage({super.key});

  @override
  State<MyCoverPage> createState() => _MyCoverPageState();
}

class _MyCoverPageState extends State<MyCoverPage> {
  List<String> _taste = const [];
  Uint8List? _art;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    List<String> taste = const [];
    try {
      taste = await UserService().fetchTasteTags() ?? const [];
    } catch (_) {}
    if (mounted) setState(() => _taste = taste);

    // 어떤 예외가 나도 로딩은 반드시 끝낸다 (무한 스피너 방지)
    Uint8List? art;
    try {
      art = await CoverArtService.weeklyCover(taste);
    } catch (_) {
      art = null;
    }
    if (mounted) {
      setState(() {
        _art = art;
        _loading = false;
      });
    }
  }

  static const List<String> _months = [
    'JANUARY', 'FEBRUARY', 'MARCH', 'APRIL', 'MAY', 'JUNE',
    'JULY', 'AUGUST', 'SEPTEMBER', 'OCTOBER', 'NOVEMBER', 'DECEMBER',
  ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final String issueLine =
        '${_months[now.month - 1]} ${now.day}, ${now.year}';
    final String name =
        (AuthService().currentUserName ?? 'YOUR').toUpperCase();
    final tags = _taste.isEmpty
        ? const ['따뜻한 나무 결', '조용한 방', '에디토리얼 무드']
        : _taste.take(4).toList();

    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        child: Column(
          children: [
            // 상단 바
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 24, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white70),
                  ),
                  const Spacer(),
                  Text(
                    'MY COVER',
                    style: eyebrowStyle(color: Colors.white54),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 0.72,
                  child: Container(
                    margin: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x66000000),
                          blurRadius: 34,
                          offset: Offset(0, 18),
                        ),
                      ],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Hero(
                        tag: 'my-weekly-cover',
                        child: _CoverArtwork(
                          art: _art,
                          loading: _loading,
                          name: name,
                          issueLine: issueLine,
                          tags: tags,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 26),
              child: Text(
                _loading
                    ? 'AI가 이번 주 표지를 그리는 중...'
                    : (_art != null
                        ? 'Gemini가 당신의 취향으로 그린 이번 주 표지예요'
                        : '취향 태그로 조판한 이번 주 표지예요'),
                style: const TextStyle(fontSize: 12.5, color: Colors.white60),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 표지 본체 — 이미지가 있으면 그 위에 제호, 없으면 타이포그래피 표지.
class _CoverArtwork extends StatelessWidget {
  const _CoverArtwork({
    required this.art,
    required this.loading,
    required this.name,
    required this.issueLine,
    required this.tags,
  });

  final Uint8List? art;
  final bool loading;
  final String name;
  final String issueLine;
  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    // 생성 표지는 제호·커버라인까지 이미지에 포함(레퍼런스 규칙) — 그대로 보여준다
    if (art != null) {
      return Image.memory(art!, fit: BoxFit.cover);
    }

    return Container(
      color: AppColors.screen,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Padding(
            padding: const EdgeInsets.all(26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 제호
                Row(
                  children: [
                    Text(
                      'LOGZINE',
                      style: logoStyle(
                        size: 21,
                        weight: FontWeight.w600,
                        letterSpacingEm: 0.18,
                        color: AppColors.ink,
                      ),
                    ),
                    const Spacer(),
                    Text('№1', style: eyebrowStyle(color: AppColors.wine)),
                  ],
                ),
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  height: 1,
                  color: AppColors.ink.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 18),
                Text('WEEKLY EDITION', style: eyebrowStyle()),
                const SizedBox(height: 10),
                Text(
                  '$name\nISSUE',
                  style: logoStyle(
                    size: 42,
                    weight: FontWeight.w600,
                    letterSpacingEm: 0.03,
                    color: AppColors.ink,
                  ).copyWith(height: 1.04),
                ),
                const SizedBox(height: 14),
                Container(width: 42, height: 2, color: AppColors.wine),
                const Spacer(),

                // 커버 라인 — 취향 태그
                if (art == null) ...[
                  for (final tag in tags)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: Row(
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              color: AppColors.wine,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            tag,
                            style: serifHeading(
                              size: 16,
                              weight: FontWeight.w500,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                ],

                // 폴리오
                Container(
                  padding: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: AppColors.ink.withValues(alpha: 0.35),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(issueLine, style: eyebrowStyle(size: 9.5)),
                      const Spacer(),
                      Text(
                        '취향으로 엮은 한 장',
                        style: eyebrowStyle(size: 9.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (loading)
            const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.forest,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
