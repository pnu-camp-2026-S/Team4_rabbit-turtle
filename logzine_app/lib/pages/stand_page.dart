import 'package:flutter/material.dart';

import '../models/magazine.dart';
import '../services/magazine_service.dart';
import '../services/recommendation_service.dart';
import '../services/user_service.dart';
import '../theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/magazine_shelf.dart';

/// 가판대 목록 데이터 — 추천순 매거진 + 사용자 취향(일치 태그 표시용).
class _StandData {
  const _StandData({required this.magazines, required this.taste});

  final List<Magazine> magazines;
  final List<String> taste;
}

class StandPage extends StatefulWidget {
  const StandPage({super.key});

  @override
  State<StandPage> createState() => _StandPageState();
}

class _StandPageState extends State<StandPage> {
  late final Future<_StandData> _standFuture = _loadStand();

  /// 매거진을 취향∩태그 점수 순으로 정렬해 목록을 만든다.
  static Future<_StandData> _loadStand() async {
    List<Magazine> magazines;
    try {
      magazines = await MagazineService().fetchMagazines();
      if (magazines.isEmpty) magazines = kMagazines;
    } catch (_) {
      magazines = kMagazines;
    }

    List<String> taste = const [];
    try {
      taste = await UserService().fetchTasteTags() ?? const [];
    } catch (_) {
      // 비로그인 — 개인화 없이 진행
    }

    return _StandData(
      magazines: RecommendationService.rank(taste, magazines),
      taste: taste,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screen,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const LogzineTopBar(showBack: true, showBell: false),
            Expanded(
              child: FutureBuilder<_StandData>(
                future: _standFuture,
                builder: (context, snapshot) {
                  final magazines =
                      snapshot.data?.magazines ?? const <Magazine>[];
                  final taste = snapshot.data?.taste ?? const <String>[];
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    itemCount: magazines.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final magazine = magazines[index];
                      final matched =
                          RecommendationService.matchedTags(taste, magazine);
                      return Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      onTap: () => Navigator.pushNamed(context, '/discover/why'),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 94,
                              height: 126,
                              child: MagazineCover(magazine: magazine),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    magazine.title,
                                    style: logoStyle(
                                      size: 24,
                                      weight: FontWeight.w600,
                                      letterSpacingEm: 0.04,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    magazine.tagline,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      height: 1.5,
                                      color: AppColors.body,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    magazine.issue,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  // 추천 근거 — 내 취향과 겹치는 태그
                                  if (matched.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: [
                                        for (final tag in matched)
                                          _MatchedTag(label: tag),
                                      ],
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  const Row(
                                    children: [
                                      Text(
                                        'Open issue',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.forest,
                                        ),
                                      ),
                                      SizedBox(width: 4),
                                      Icon(
                                        Icons.chevron_right,
                                        size: 16,
                                        color: AppColors.forest,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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

/// "내 취향과 일치" 태그 칩 — 추천 근거를 시각화한다.
class _MatchedTag extends StatelessWidget {
  const _MatchedTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.forest.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.forest.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check, size: 11, color: AppColors.forest),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.forest,
            ),
          ),
        ],
      ),
    );
  }
}
