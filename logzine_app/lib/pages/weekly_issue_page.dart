import 'package:flutter/material.dart';

import '../models/reader_args.dart';
import '../services/auth_service.dart';
import '../services/weekly_issue_service.dart';
import '../theme.dart';

/// "LOGZINE Weekly — 나의 주간 이슈" — 한 주의 취향 활동이 한 권의 매거진으로
/// 발행된다. 표지(MY COVER) → 목차(저장 아티클) → 에디터의 말(Gemini) →
/// 뒷표지(읽기 통계) 순서로 넘겨 본다.
class WeeklyIssuePage extends StatefulWidget {
  const WeeklyIssuePage({super.key});

  @override
  State<WeeklyIssuePage> createState() => _WeeklyIssuePageState();
}

class _WeeklyIssuePageState extends State<WeeklyIssuePage> {
  final PageController _controller = PageController(viewportFraction: 0.88);
  final Future<WeeklyIssueData> _future = WeeklyIssueService.compose();
  double _page = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (_controller.hasClients && _controller.position.haveDimensions) {
        setState(() => _page = _controller.page ?? 0);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String name = (AuthService().currentUserName ?? 'YOUR').toUpperCase();

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
                    'LOGZINE WEEKLY',
                    style: eyebrowStyle(color: Colors.white54),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<WeeklyIssueData>(
                future: _future,
                builder: (context, snapshot) {
                  final data = snapshot.data;
                  if (data == null) {
                    return const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white70,
                        ),
                      ),
                    );
                  }
                  return PageView(
                    controller: _controller,
                    children: [
                      _Sheet(child: _CoverSheet(data: data, name: name)),
                      _Sheet(child: _ContentsSheet(data: data)),
                      _Sheet(child: _EditorSheet(data: data)),
                      _Sheet(dark: true, child: _BackCoverSheet(data: data)),
                    ],
                  );
                },
              ),
            ),
            // 페이지 점 + 안내
            Padding(
              padding: const EdgeInsets.only(bottom: 22),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (int i = 0; i < 4; i++)
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: (_page.round() == i)
                                ? Colors.white
                                : Colors.white24,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '이번 주 당신이 한 권의 매거진이 됐어요 — 옆으로 넘겨보세요',
                    style: TextStyle(fontSize: 12, color: Colors.white54),
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

/// 매거진 낱장 — 흰 지면(또는 뒷표지 잉크 지면)을 종이 비율로 띄운다.
class _Sheet extends StatelessWidget {
  const _Sheet({required this.child, this.dark = false});

  final Widget child;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AspectRatio(
        aspectRatio: 0.72,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
          decoration: BoxDecoration(
            boxShadow: const [
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 30,
                offset: Offset(0, 14),
              ),
            ],
            borderRadius: BorderRadius.circular(4),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Container(
              color: dark ? const Color(0xFF232325) : AppColors.screen,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// 1면 — 표지. Gemini 생성 아트가 있으면 그대로, 없으면 타이포그래피 표지.
class _CoverSheet extends StatelessWidget {
  const _CoverSheet({required this.data, required this.name});

  final WeeklyIssueData data;
  final String name;

  String get _dateRange =>
      '${data.weekStart.month}.${data.weekStart.day} – '
      '${data.weekEnd.month}.${data.weekEnd.day}';

  @override
  Widget build(BuildContext context) {
    if (data.coverArt != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.memory(data.coverArt!, fit: BoxFit.cover),
          // 주간 이슈 배지 — 생성 표지 위에 호수만 살짝 얹는다
          Positioned(
            right: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.ink.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                'WEEKLY №${data.issueNumber} · $_dateRange',
                style: eyebrowStyle(size: 9, color: Colors.white),
              ),
            ),
          ),
        ],
      );
    }

    final tags = data.tasteTags.isEmpty
        ? const ['따뜻한 나무 결', '조용한 방', '에디토리얼 무드']
        : data.tasteTags.take(4).toList();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'LOGZINE',
                style: logoStyle(
                  size: 20,
                  weight: FontWeight.w600,
                  letterSpacingEm: 0.18,
                  color: AppColors.ink,
                ),
              ),
              const Spacer(),
              Text(
                '№${data.issueNumber}',
                style: eyebrowStyle(color: AppColors.wine),
              ),
            ],
          ),
          Container(
            margin: const EdgeInsets.only(top: 8),
            height: 1,
            color: AppColors.ink.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text('WEEKLY EDITION', style: eyebrowStyle()),
          const SizedBox(height: 8),
          Text(
            '$name\n호',
            style: logoStyle(
              size: 38,
              weight: FontWeight.w600,
              letterSpacingEm: 0.03,
              color: AppColors.ink,
            ).copyWith(height: 1.06),
          ),
          const SizedBox(height: 12),
          Container(width: 42, height: 2, color: AppColors.wine),
          const Spacer(),
          for (final tag in tags)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
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
                      size: 15,
                      weight: FontWeight.w500,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.only(top: 10),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.ink.withValues(alpha: 0.35)),
              ),
            ),
            child: Row(
              children: [
                Text(_dateRange, style: eyebrowStyle(size: 9.5)),
                const Spacer(),
                Text('한 주의 취향으로 엮은 호', style: eyebrowStyle(size: 9.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 2면 — 목차. 이번 주 저장한 아티클, 탭하면 리더로.
class _ContentsSheet extends StatelessWidget {
  const _ContentsSheet({required this.data});

  final WeeklyIssueData data;

  void _openEntry(BuildContext context, WeeklyIssueEntry entry) {
    if (entry.articleId.isEmpty || entry.magazineId.isEmpty) return;
    Navigator.pushNamed(
      context,
      '/reader',
      arguments: ReaderArgs(
        title: entry.articleTitle,
        publisher: entry.magazineTitle,
        magazineId: entry.magazineId,
        articleId: entry.articleId,
        coverUrl: entry.coverUrl.isEmpty ? null : entry.coverUrl,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('IN THIS WEEK', style: eyebrowStyle(color: AppColors.wine)),
          const SizedBox(height: 8),
          Text(
            'Contents',
            style: logoStyle(
              size: 28,
              weight: FontWeight.w600,
              letterSpacingEm: 0.02,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            data.entriesAreRecentFallback
                ? '이번 주 저장이 없어 최근 저장한 페이지를 실었어요.'
                : '이번 주 당신이 저장한 페이지들이에요.',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 6),
          if (data.entries.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  '아직 저장한 아티클이 없어요.\n마음에 드는 페이지를 저장하면\n다음 호 목차에 실려요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.6,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.zero,
                physics: const ClampingScrollPhysics(),
                itemCount: data.entries.length,
                separatorBuilder: (_, _) =>
                    const Divider(color: AppColors.border, height: 1),
                itemBuilder: (context, i) {
                  final entry = data.entries[i];
                  return InkWell(
                    onTap: () => _openEntry(context, entry),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      child: Row(
                        children: [
                          Text(
                            (i + 1).toString().padLeft(2, '0'),
                            style: logoStyle(
                              size: 14,
                              weight: FontWeight.w600,
                              letterSpacingEm: 0.04,
                              color: AppColors.wine,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.articleTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.ink,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  entry.magazineTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (entry.articleId.isNotEmpty)
                            const Icon(
                              Icons.chevron_right,
                              size: 16,
                              color: AppColors.textMuted,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 6),
          Text(
            '이번 주 밑줄 ${data.marksThisWeek}개 · 3면에서 이어져요',
            style: eyebrowStyle(size: 9.5),
          ),
        ],
      ),
    );
  }
}

/// 3면 — 에디터의 말 + 이번 주 밑줄 친 문장들.
class _EditorSheet extends StatelessWidget {
  const _EditorSheet({required this.data});

  final WeeklyIssueData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("EDITOR'S NOTE", style: eyebrowStyle(color: AppColors.wine)),
          const SizedBox(height: 12),
          Text(
            data.editorNote,
            style: serifHeading(
              size: 16.5,
              weight: FontWeight.w500,
              color: AppColors.ink,
            ).copyWith(height: 1.5),
          ),
          const SizedBox(height: 8),
          const Text(
            '— AI 큐레이터가 이번 주 활동을 읽고 씀',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 18),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 14),
          Text('MARKED PASSAGES', style: eyebrowStyle()),
          const SizedBox(height: 10),
          if (data.quotes.isEmpty)
            const Expanded(
              child: Text(
                '이번 주에는 밑줄이 없어요.\n마음에 닿는 문장을 만나면 남겨보세요.',
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.6,
                  color: AppColors.textMuted,
                ),
              ),
            )
          else
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final quote in data.quotes)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 3,
                              margin: const EdgeInsets.only(top: 3),
                              height: 34,
                              decoration: BoxDecoration(
                                color: AppColors.wine,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    quote.text,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      height: 1.5,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    quote.source,
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 4면 — 뒷표지. 한 주의 읽기 통계.
class _BackCoverSheet extends StatelessWidget {
  const _BackCoverSheet({required this.data});

  final WeeklyIssueData data;

  static const List<String> _dayLabels = ['월', '화', '수', '목', '금', '토', '일'];

  String get _timeLabel {
    final int minutes = data.weekSeconds ~/ 60;
    final int hours = minutes ~/ 60;
    return hours > 0 ? '${hours}h ${minutes % 60}m' : '${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final int maxSeconds = data.dailySeconds.isEmpty
        ? 0
        : data.dailySeconds.reduce((a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('THE WEEK IN NUMBERS', style: eyebrowStyle(color: Colors.white54)),
          const SizedBox(height: 20),
          _NumberRow(label: '읽은 시간', value: _timeLabel),
          _NumberRow(label: '남긴 밑줄', value: '${data.marksThisWeek}개'),
          _NumberRow(label: '실린 페이지', value: '${data.entries.length}편'),
          if (data.bestDayLabel.isNotEmpty)
            _NumberRow(label: '가장 깊이 읽은 날', value: data.bestDayLabel),
          const Spacer(),
          // 월~일 미니 그래프
          if (data.dailySeconds.length == 7 && maxSeconds > 0) ...[
            SizedBox(
              height: 72,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (int i = 0; i < 7; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            height:
                                6 + 48 * (data.dailySeconds[i] / maxSeconds),
                            decoration: BoxDecoration(
                              color: data.dailySeconds[i] == maxSeconds
                                  ? Colors.white
                                  : Colors.white30,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _dayLabels[i],
                            style: const TextStyle(
                              fontSize: 9,
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Colors.white24)),
            ),
            child: Row(
              children: [
                Text(
                  'LOGZINE WEEKLY №${data.issueNumber}',
                  style: eyebrowStyle(size: 9.5, color: Colors.white54),
                ),
                const Spacer(),
                Text(
                  '다음 호는 일요일 밤에',
                  style: eyebrowStyle(size: 9.5, color: Colors.white54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 뒷표지 숫자 한 줄.
class _NumberRow extends StatelessWidget {
  const _NumberRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12.5, color: Colors.white60),
          ),
          const Spacer(),
          Text(
            value,
            style: logoStyle(
              size: 24,
              weight: FontWeight.w600,
              letterSpacingEm: 0.02,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
