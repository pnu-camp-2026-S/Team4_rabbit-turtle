import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../models/reader_args.dart';
import '../theme.dart';
import '../widgets/logzine_logo.dart';
import '../widgets/onboarding_widgets.dart';

import '../services/magazine_service.dart';
import '../services/mark_service.dart';

/// 하이라이트/메모 마크.
class _Mark {
  const _Mark({required this.color, this.memo});

  final Color color;
  final String? memo;

  /// 잉크(검정) 계열은 배경 대신 밑줄로 표시.
  bool get isUnderline => color == _ReaderPageState.kInkSwatch;
}

/// 매거진 읽기 화면 — 진행률 + 하이라이트/메모.
class ReaderPage extends StatefulWidget {
  const ReaderPage({super.key});

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  static const String _heroUrl =
      'https://images.unsplash.com/photo-1493809842364-78817add7ffb'
      '?auto=format&fit=crop&w=1200&q=80';

  static const int _totalPages = 12;

  /// 문단 → 탭 가능한 문장 조각. (조각 단위로 하이라이트)
  static const List<List<String>> _paragraphs = [
    [
      'Materials shape the mood of a space.',
      'When light, texture, and proportion align, '
          'the quiet becomes a language.',
    ],
    [
      'Wood, stone, linen—honest materials',
      'that age beautifully and hold meaning over time.',
    ],
    [
      'In a world that moves fast, slow spaces',
      'remind us to notice the small things.',
    ],
  ];

  /// 문단별 페이지 라벨 (p.4, p.5, p.6).
  static const List<int> _paragraphPages = [4, 5, 6];

  // 팔레트 스와치.
  static const Color kYellowSwatch = Color(0xFFE9C46A);
  static const Color kGreenSwatch = Color(0xFFA3C9A8);
  static const Color kPinkSwatch = Color(0xFFC98B9B);
  static const Color kInkSwatch = Color(0xFF3A3A3C); // 밑줄 펜

  /// 스와치 → 본문 하이라이트 배경색.
  static final Map<Color, Color> _highlightBg = {
    kYellowSwatch: const Color(0xFFF2DE9E),
    kGreenSwatch: const Color(0xFFC9E0C6),
    kPinkSwatch: const Color(0xFFEBC5CF),
  };

  final ScrollController _scroll = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final Map<(int, int), TapGestureRecognizer> _recognizers = {};

  bool _saved = false;
  bool _highlightMode = false;
  String _tool = 'pen'; // 'pen' | 'memo'
  List<Color> _palette = const [
    kYellowSwatch,
    kGreenSwatch,
    kPinkSwatch,
    kInkSwatch,
  ];
  Color _activeColor = kYellowSwatch;

  final Map<(int, int), _Mark> _marks = {};
  final List<Map<(int, int), _Mark>> _history = [];

  double _page = 4;
  bool _draggingSlider = false;
  String _query = '';

  ReaderArgs _args = const ReaderArgs();
  bool _argsApplied = false;

  final MarkService _markService = MarkService();
  String? _magazineId;
  String? _articleId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_argsApplied) {
      final Object? args = ModalRoute.of(context)?.settings.arguments;
      if (args is ReaderArgs) _args = args;
      _argsApplied = true;
    }
  }

  @override
  void initState() {
    super.initState();
    for (int p = 0; p < _paragraphs.length; p++) {
      for (int s = 0; s < _paragraphs[p].length; s++) {
        _recognizers[(p, s)] = TapGestureRecognizer()
          ..onTap = () => _onSegmentTap(p, s);
      }
    }
    // 스크롤 → 읽기 진행률 연동
    _scroll.addListener(() {
      if (_draggingSlider || !_scroll.hasClients) return;
      final double max = _scroll.position.maxScrollExtent;
      if (max <= 0) return;
      final double t = (_scroll.offset / max).clamp(0.0, 1.0);
      final double page = 1 + t * (_totalPages - 1);
      if ((page - _page).abs() > 0.05) setState(() => _page = page);
    });
    _loadRemote();
  }

  /// 아티클 ID 확인 + 저장된 마크/진행률 복원
  Future<void> _loadRemote() async {
    final ids = await MagazineService().fetchDemoArticleIds();
    if (ids == null || !mounted) return;
    _magazineId = ids.magazineId;
    _articleId = ids.articleId;

    final List<MarkRecord> marks =
        await _markService.fetchMarks(ids.articleId);
    final int? lastPage = await _markService.fetchLastPage(ids.articleId);
    if (!mounted) return;
    setState(() {
      for (final r in marks) {
        _marks[(r.paragraphIdx, r.segmentIdx)] = _Mark(
          color: r.type == 'underline' ? kInkSwatch : _colorFromHex(r.color),
          memo: r.memoText,
        );
      }
      if (lastPage != null) {
        _page = lastPage.clamp(1, _totalPages).toDouble();
      }
    });
  }

  /// 마크 1건 서버 반영 (null이면 삭제)
  void _syncMark((int, int) key, _Mark? mark) {
    final String? articleId = _articleId;
    final String? magazineId = _magazineId;
    if (articleId == null || magazineId == null) return;
    if (mark == null) {
      _markService.deleteMark(articleId, key.$1, key.$2);
    } else {
      _markService.saveMark(
        articleId: articleId,
        magazineId: magazineId,
        paragraphIdx: key.$1,
        segmentIdx: key.$2,
        type: mark.memo != null
            ? 'memo'
            : mark.isUnderline
                ? 'underline'
                : 'highlight',
        colorHex: _hex(mark.color),
        memoText: mark.memo,
      );
    }
  }

  void _saveProgress() {
    final String? articleId = _articleId;
    final String? magazineId = _magazineId;
    if (articleId == null || magazineId == null) return;
    _markService.saveProgress(
      articleId: articleId,
      magazineId: magazineId,
      lastPage: _page.round(),
      percent: (_page / _totalPages * 100).ceil().clamp(0, 100),
    );
  }

  static String _hex(Color c) =>
      '#${c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

  static Color _colorFromHex(String? hex) {
    if (hex == null || hex.length < 7) return kYellowSwatch;
    return Color(int.parse(hex.substring(1, 7), radix: 16) | 0xFF000000);
  }

  @override
  void dispose() {
    _saveProgress();
    for (final r in _recognizers.values) {
      r.dispose();
    }
    _scroll.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ── 마크 조작 ──────────────────────────────────────────────

  void _pushHistory() =>
      _history.add(Map<(int, int), _Mark>.from(_marks));

  void _undo() {
    if (_history.isEmpty) return;
    final Map<(int, int), _Mark> before = Map.of(_marks);
    setState(() {
      _marks
        ..clear()
        ..addAll(_history.removeLast());
    });
    for (final key in {...before.keys, ..._marks.keys}) {
      if (!identical(before[key], _marks[key])) _syncMark(key, _marks[key]);
    }
  }

  Future<void> _onSegmentTap(int p, int s) async {
    if (!_highlightMode) return;
    final key = (p, s);

    if (_tool == 'memo') {
      final String? memo = await _askMemo();
      if (memo == null || memo.trim().isEmpty) return;
      setState(() {
        _pushHistory();
        _marks[key] = _Mark(color: _activeColor, memo: memo.trim());
      });
      _syncMark(key, _marks[key]);
      return;
    }

    setState(() {
      _pushHistory();
      final _Mark? existing = _marks[key];
      if (existing != null &&
          existing.color == _activeColor &&
          existing.memo == null) {
        _marks.remove(key); // 같은 색으로 다시 탭 → 지우기
      } else {
        _marks[key] = _Mark(color: _activeColor);
      }
    });
    _syncMark(key, _marks[key]);
  }

  Future<String?> _askMemo() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('메모 남기기', style: TextStyle(fontSize: 17)),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(hintText: '이 문장에 대한 생각을 적어보세요'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.forest),
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  void _addCustomColor() {
    const extras = [Color(0xFF9DB8D2), Color(0xFFE0A458), Color(0xFFB39BC8)];
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '색상 추가',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                for (final c in extras)
                  Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          if (!_palette.contains(c)) {
                            _palette = [..._palette, c];
                          }
                          _activeColor = c;
                          // 새 색상도 하이라이트 배경으로 쓸 수 있게 등록
                        });
                        Navigator.pop(context);
                      },
                      child: CircleAvatar(radius: 16, backgroundColor: c),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Color _bgFor(Color swatch) =>
      _highlightBg[swatch] ?? swatch.withValues(alpha: 0.35);

  List<MapEntry<(int, int), _Mark>> get _sortedMarks {
    final entries = _marks.entries.toList()
      ..sort((a, b) {
        final int c = a.key.$1.compareTo(b.key.$1);
        return c != 0 ? c : a.key.$2.compareTo(b.key.$2);
      });
    if (_query.isEmpty) return entries;
    return entries
        .where((e) => _paragraphs[e.key.$1][e.key.$2]
            .toLowerCase()
            .contains(_query.toLowerCase()))
        .toList();
  }

  // ── UI ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screen,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(child: _buildArticle()),
            if (_highlightMode) _buildHighlightPanel() else _buildActionBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new,
                size: 19, color: AppColors.ink),
          ),
          const Expanded(
            child: Center(
              child: LogzineLogo(height: 22),
            ),
          ),
          IconButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('본문 검색은 준비 중이에요')),
            ),
            icon: const Icon(Icons.search, size: 22, color: AppColors.ink),
          ),
          IconButton(
            onPressed: () {
              setState(() => _saved = !_saved);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_saved ? '이 이슈를 저장했어요' : '저장을 취소했어요'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            icon: Icon(
              _saved ? Icons.bookmark : Icons.bookmark_border,
              size: 22,
              color: _saved ? AppColors.forest : AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArticle() {
    return SingleChildScrollView(
      controller: _scroll,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 히어로 이미지
          SizedBox(
            height: 230,
            width: double.infinity,
            child: NetworkPhoto(url: _heroUrl, radius: 0),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _args.category,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.forest,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _args.title,
                  style: logoStyle(
                    size: 36,
                    weight: FontWeight.w600,
                    letterSpacingEm: 0.0,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_args.publisher}   ·   ${_args.minutes} min read',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),

                // 오늘의 키워드 칩
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.wb_sunny_outlined,
                          size: 15, color: Color(0xFFE0A83C)),
                      SizedBox(width: 8),
                      Text(
                        "Today's keyword: ",
                        style: TextStyle(
                            fontSize: 13, color: AppColors.body),
                      ),
                      Text(
                        'Light',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(color: AppColors.border, height: 1),
                const SizedBox(height: 20),

                // 본문 1문단
                _buildParagraph(0),
                const SizedBox(height: 20),

                // 본문 이미지
                SizedBox(
                  height: 210,
                  width: double.infinity,
                  child: NetworkPhoto(url: kMoodPhotos[2], radius: 8),
                ),
                const SizedBox(height: 20),

                _buildParagraph(1),
                const SizedBox(height: 18),
                _buildParagraph(2),

                if (_highlightMode) ...[
                  const SizedBox(height: 14),
                  const Text(
                    '문장을 탭하면 선택한 색으로 표시돼요',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParagraph(int p) {
    return Text.rich(
      TextSpan(
        children: [
          for (int s = 0; s < _paragraphs[p].length; s++) ...[
            TextSpan(
              text: _paragraphs[p][s],
              recognizer: _recognizers[(p, s)],
              style: _segmentStyle(p, s),
            ),
            if (s != _paragraphs[p].length - 1) const TextSpan(text: ' '),
          ],
        ],
      ),
      style: const TextStyle(
        fontSize: 15,
        height: 1.65,
        color: AppColors.ink,
      ),
    );
  }

  TextStyle _segmentStyle(int p, int s) {
    final _Mark? mark = _marks[(p, s)];
    if (mark == null) return const TextStyle();
    if (mark.isUnderline) {
      return const TextStyle(
        decoration: TextDecoration.underline,
        decorationColor: AppColors.ink,
        decorationThickness: 1.8,
      );
    }
    return TextStyle(backgroundColor: _bgFor(mark.color));
  }

  // ── 하단: 일반 모드 ─────────────────────────────────────────

  Widget _buildActionBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 6, 24, 10),
      decoration: const BoxDecoration(
        color: AppColors.screen,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildProgressRow(),
          const SizedBox(height: 4),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ActionItem(
                icon: _saved ? Icons.bookmark : Icons.bookmark_border,
                label: 'Save',
                active: _saved,
                onTap: () => setState(() => _saved = !_saved),
              ),
              _ActionItem(
                icon: Icons.edit_outlined,
                label: 'Highlight',
                onTap: () => setState(() => _highlightMode = true),
              ),
              _ActionItem(
                icon: Icons.apartment,
                label: 'Publisher',
                onTap: _showPublisher,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showPublisher() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Studio Log',
                style: logoStyle(size: 22, letterSpacingEm: 0.04)),
            const SizedBox(height: 8),
            const Text(
              '공간과 사물의 온도를 기록하는 에디토리얼 스튜디오. '
              '조용한 인테리어와 오래 쓰는 물건 이야기를 다룹니다.',
              style: TextStyle(
                  fontSize: 13.5, height: 1.6, color: AppColors.body),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.forest,
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('발행사 팔로우'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 하단: 하이라이트 모드 패널 ───────────────────────────────

  Widget _buildHighlightPanel() {
    final marks = _sortedMarks;
    final visible = marks.take(2).toList();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        boxShadow: [
          BoxShadow(
              color: Color(0x1F000000),
              blurRadius: 16,
              offset: Offset(0, -4)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 도구 줄
          Row(
            children: [
              InkWell(
                onTap: () => setState(() => _highlightMode = false),
                borderRadius: BorderRadius.circular(6),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.keyboard_arrow_down,
                      size: 22, color: AppColors.ink),
                ),
              ),
              const SizedBox(width: 6),
              _ToolButton(
                icon: Icons.edit_outlined,
                label: 'Pen',
                selected: _tool == 'pen',
                onTap: () => setState(() => _tool = 'pen'),
              ),
              const SizedBox(width: 10),
              _ToolButton(
                icon: Icons.edit_note,
                label: 'Memo',
                selected: _tool == 'memo',
                onTap: () => setState(() => _tool = 'memo'),
              ),
              const SizedBox(width: 10),
              _ToolButton(
                icon: Icons.undo,
                label: 'Undo',
                selected: false,
                enabled: _history.isNotEmpty,
                onTap: _undo,
              ),
              const Spacer(),
              for (final c in _palette)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: GestureDetector(
                    onTap: () => setState(() => _activeColor = c),
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: _activeColor == c
                            ? Border.all(
                                color: AppColors.ink, width: 1.8)
                            : null,
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: GestureDetector(
                  onTap: _addCustomColor,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(Icons.add,
                        size: 13, color: AppColors.textSecondary),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Marked passages
          Row(
            children: [
              const Text(
                'Marked passages',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 160,
                height: 34,
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v),
                  style: const TextStyle(fontSize: 12.5),
                  decoration: InputDecoration(
                    hintText: 'Search marks',
                    hintStyle: const TextStyle(
                        fontSize: 12.5, color: AppColors.textMuted),
                    prefixIcon: const Icon(Icons.search,
                        size: 16, color: AppColors.textMuted),
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                    filled: true,
                    fillColor: const Color(0xFFF4F2EC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          if (marks.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text(
                '아직 표시한 문장이 없어요. 본문 문장을 탭해 보세요.',
                style:
                    TextStyle(fontSize: 12.5, color: AppColors.textMuted),
              ),
            )
          else ...[
            for (final e in visible) _buildMarkTile(e),
            InkWell(
              onTap: _showAllMarks,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'View all marks',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.forest.withValues(alpha: 0.95),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right,
                        size: 16, color: AppColors.forest),
                  ],
                ),
              ),
            ),
          ],

          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 4),
          _buildProgressRow(),
        ],
      ),
    );
  }

  Widget _buildMarkTile(MapEntry<(int, int), _Mark> e) {
    final text = _paragraphs[e.key.$1][e.key.$2];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 5,
            height: 36,
            decoration: BoxDecoration(
              color: e.value.color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.45,
                    color: AppColors.ink,
                  ),
                ),
                if (e.value.memo != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      '📝 ${e.value.memo}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11.5, color: AppColors.textSecondary),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Row(
              children: [
                Text(
                  'p.${_paragraphPages[e.key.$1]}',
                  style: const TextStyle(
                      fontSize: 11.5, color: AppColors.textSecondary),
                ),
                const Icon(Icons.chevron_right,
                    size: 15, color: AppColors.textSecondary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAllMarks() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'All marks',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [for (final e in _sortedMarks) _buildMarkTile(e)],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 진행률 ─────────────────────────────────────────────────

  Widget _buildProgressRow() {
    final int page = _page.round();
    final int percent = (_page / _totalPages * 100).ceil();
    return Row(
      children: [
        SizedBox(
          width: 42,
          child: Text(
            '$page / $_totalPages',
            style: const TextStyle(
                fontSize: 12.5, color: AppColors.textSecondary),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 3,
              activeTrackColor: AppColors.forest,
              inactiveTrackColor: const Color(0xFFDDD9CE),
              overlayShape: SliderComponentShape.noOverlay,
              thumbShape: const _BookmarkThumbShape(),
            ),
            child: Slider(
              value: _page,
              min: 1,
              max: _totalPages.toDouble(),
              onChangeStart: (_) => _draggingSlider = true,
              onChanged: (v) {
                setState(() => _page = v);
                if (_scroll.hasClients &&
                    _scroll.position.maxScrollExtent > 0) {
                  _scroll.jumpTo(_scroll.position.maxScrollExtent *
                      (v - 1) /
                      (_totalPages - 1));
                }
              },
              onChangeEnd: (_) {
                _draggingSlider = false;
                _saveProgress();
              },
            ),
          ),
        ),
        SizedBox(
          width: 38,
          child: Text(
            '$percent%',
            textAlign: TextAlign.end,
            style: const TextStyle(
                fontSize: 12.5, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}

/// 하단 액션 (Save / Highlight / Publisher).
class _ActionItem extends StatelessWidget {
  const _ActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.forest : AppColors.ink;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 21, color: color),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(fontSize: 11.5, color: color)),
          ],
        ),
      ),
    );
  }
}

/// 하이라이트 패널 도구 버튼 (선택 시 밑줄).
class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = !enabled
        ? AppColors.textMuted
        : selected
            ? AppColors.ink
            : AppColors.textSecondary;
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
            child: Row(
              children: [
                Icon(icon, size: 17, color: color),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.w400,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 2,
            width: 40,
            color: selected ? AppColors.ink : Colors.transparent,
          ),
        ],
      ),
    );
  }
}

/// 북마크 리본 모양의 슬라이더 썸.
class _BookmarkThumbShape extends SliderComponentShape {
  const _BookmarkThumbShape();

  static const double _width = 15;
  static const double _height = 20;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      const Size(_width, _height);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    final double l = center.dx - _width / 2;
    final double r = center.dx + _width / 2;
    final double t = center.dy - _height / 2;
    final double b = center.dy + _height / 2;

    final Path path = Path()
      ..moveTo(l + 2, t)
      ..lineTo(r - 2, t)
      ..quadraticBezierTo(r, t, r, t + 2)
      ..lineTo(r, b)
      ..lineTo(center.dx, b - 5) // 리본 홈
      ..lineTo(l, b)
      ..lineTo(l, t + 2)
      ..quadraticBezierTo(l, t, l + 2, t)
      ..close();

    canvas.drawShadow(path, Colors.black38, 2, true);
    canvas.drawPath(path, Paint()..color = AppColors.forest);
  }
}
