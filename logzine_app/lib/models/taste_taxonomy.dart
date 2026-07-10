/// 취향 어휘의 **단일 출처(single source of truth)**.
///
/// 이 파일 하나에서 다음이 전부 파생된다 — 서로 어긋날 수 없다:
///   • AI 사진 분석 프롬프트의 허용 어휘 (photo_taste_analyzer)
///   • 취향 픽커 칩 (taste_picker_page)
///   • 추천 엔진의 표준 어휘와 유사 태그 폴백 (recommendation_service)
///   • 매거진 태그 검증 (magazine.dart / 테스트)
///
/// 2단 계층: 카테고리(대분류) → 키워드(세부).
/// 세부 키워드는 직접 일치가 어려우므로, **같은 카테고리의 형제 키워드**를
/// 자동 폴백으로 쓴다. (예: '농구'를 좋아하는데 농구 매거진이 없으면
/// 같은 SPORTS의 '축구'·'스포츠 관람' 매거진으로 착지)
library;

/// 취향 대분류 하나.
class TasteCategory {
  const TasteCategory({
    required this.id,
    required this.label,
    required this.keywords,
  });

  /// 영문 대문자 식별자 (AI 프롬프트의 카테고리 라벨로도 쓰인다).
  final String id;

  /// 사용자에게 보이는 한국어 대분류명.
  final String label;

  /// 이 카테고리의 세부 취향 키워드.
  final List<String> keywords;
}

/// 전체 취향 분류. 키워드는 카테고리 안에서 유일하고, 전체에서도 유일하다.
/// (같은 단어가 두 카테고리에 있으면 계층 폴백이 모호해지므로 금지 —
///  '클래식'(패션)과 '클래식 음악'(음악)처럼 구분해서 붙인다.)
const List<TasteCategory> kTasteTaxonomy = [
  TasteCategory(
    id: 'FOOD',
    label: '음식',
    keywords: [
      '카페',
      '커피',
      '디저트',
      '베이커리',
      '브런치',
      '전통차',
      '와인',
      '파인다이닝',
      '집밥',
      '로컬 맛집',
    ],
  ),
  TasteCategory(
    id: 'FASHION',
    label: '패션',
    keywords: [
      '미니멀',
      '빈티지',
      '스트릿',
      '클래식',
      '디자이너 브랜드',
      '스포츠웨어',
      '액세서리',
      '데일리룩',
    ],
  ),
  TasteCategory(
    id: 'SPACE',
    label: '공간',
    keywords: [
      '인테리어',
      '가구',
      '한옥',
      '호텔',
      '전시 공간',
      '서점',
      '정원',
      '복합문화공간',
      '작업실',
    ],
  ),
  TasteCategory(
    id: 'TRAVEL',
    label: '여행',
    keywords: [
      '도시 여행',
      '해외 도시',
      '랜드마크',
      '골목 탐방',
      '자연',
      '숙소',
      '미식 여행',
      '스포츠 여행',
      '주말 여행',
      '동네 가게',
    ],
  ),
  TasteCategory(
    id: 'ART',
    label: '예술',
    keywords: [
      '전시',
      '현대미술',
      '건축',
      '공예',
      '디자인',
      '일러스트',
      '사진',
      '아트페어',
    ],
  ),
  TasteCategory(
    id: 'MUSIC',
    label: '음악',
    keywords: [
      '힙합',
      '락',
      'R&B',
      '일렉트로닉',
      '인디',
      '재즈',
      '클래식 음악',
      '라이브 공연',
      '페스티벌',
      '플레이리스트',
      '바이닐',
      '사운드트랙',
    ],
  ),
  TasteCategory(
    id: 'SPORTS',
    label: '스포츠',
    keywords: [
      '축구',
      '농구',
      '야구',
      '배구',
      '테니스',
      '러닝',
      '요가',
      '클라이밍',
      '등산',
      '스포츠 관람',
      '경기장 투어',
    ],
  ),
  TasteCategory(
    id: 'PET',
    label: '반려',
    keywords: [
      '강아지',
      '고양이',
      '반려 산책',
      '반려 용품',
    ],
  ),
  TasteCategory(
    id: 'LIFESTYLE',
    label: '라이프',
    keywords: [
      '독서',
      '웰니스',
      '작업 루틴',
      '홈라이프',
      '취미 수집',
      '조용한 휴식',
      '로컬 탐방',
      '산책',
    ],
  ),
];

/// 전체 키워드 (선언 순서 유지).
final List<String> kAllTasteKeywords = [
  for (final category in kTasteTaxonomy) ...category.keywords,
];

/// 빠른 유효성 검사용 집합.
final Set<String> kAllTasteKeywordSet = kAllTasteKeywords.toSet();

/// 키워드 → 카테고리 ID.
final Map<String, String> kCategoryIdOfKeyword = {
  for (final category in kTasteTaxonomy)
    for (final keyword in category.keywords) keyword: category.id,
};

/// 카테고리 ID → 카테고리.
final Map<String, TasteCategory> kCategoryById = {
  for (final category in kTasteTaxonomy) category.id: category,
};

/// [keyword]와 같은 카테고리에 속한 다른 키워드들 (자기 자신 제외).
/// 세부 취향이 직접 일치하지 않을 때의 1차 폴백.
List<String> siblingsOf(String keyword) {
  final categoryId = kCategoryIdOfKeyword[keyword];
  if (categoryId == null) return const [];
  return [
    for (final sibling in kCategoryById[categoryId]!.keywords)
      if (sibling != keyword) sibling,
  ];
}

/// 동의어·과거 어휘 → 현재 키워드. 사용자가 예전에 저장한 tasteTags나
/// 구버전 AI 라벨이 들어와도 추천이 끊기지 않게 한다.
///
/// 여기 실린 관계는 **직접 매칭**으로 취급된다 (인접 폴백보다 강함).
/// 의미가 사실상 같은 말만 넣을 것 — 단지 비슷한 정도면
/// [kCrossCategoryNeighbors]에 넣는다.
///
/// ⚠️ 값은 반드시 [kAllTasteKeywordSet] 안의 키워드여야 한다 (테스트로 검증).
const Map<String, List<String>> kLegacyTasteAliases = {
  // 동의어 (양방향)
  '호텔': ['숙소'],
  '숙소': ['호텔'],
  '커피': ['카페'],
  '베이커리': ['디저트'],
  // 큰 범주로만 저장돼 있던 옛 태그 → 세부 키워드로 확장
  '반려생활': ['강아지', '고양이'],
  '스포츠': ['축구', '스포츠 관람'],
  '음악': ['플레이리스트', '인디'],
  '예술': ['전시', '현대미술'],
  '여행': ['도시 여행', '주말 여행'],
  '문화생활': ['전시', '라이브 공연'],
  '아웃도어': ['자연', '등산'],
  '슬로우 라이프': ['조용한 휴식', '산책'],
  '공부/작업': ['작업실', '작업 루틴'],
  // 표기 흔들림 흡수
  '커피/카페': ['카페', '커피'],
  '갤러리': ['전시'],
  '시장': ['동네 가게'],
  '동네': ['동네 가게'],
  '문화/건축': ['건축', '디자인'],
  '건축/디자인': ['건축', '디자인'],
  '클래식(음악)': ['클래식 음악'],
  '힙합/랩': ['힙합'],
  '록': ['락'],
};

/// 카테고리를 넘나드는 의미적 인접 관계 (형제 폴백으로 못 잡는 것만 최소한으로).
/// 형제 폴백이 1차, 이 표가 2차다.
const Map<String, List<String>> kCrossCategoryNeighbors = {
  '와인': ['파인다이닝', '미식 여행'],
  '커피': ['카페', '작업 루틴'],
  '집밥': ['홈라이프', '로컬 맛집'],
  '빈티지': ['바이닐', '가구'],
  '스포츠웨어': ['러닝', '스트릿'],
  '인테리어': ['가구', '홈라이프'],
  '가구': ['공예', '인테리어'],
  '서점': ['독서', '조용한 휴식'],
  '정원': ['자연', '조용한 휴식'],
  '한옥': ['전통차', '건축'],
  '호텔': ['숙소', '주말 여행'],
  '작업실': ['작업 루틴', '공예'],
  '자연': ['등산', '산책'],
  '스포츠 여행': ['경기장 투어', '스포츠 관람'],
  '미식 여행': ['로컬 맛집', '파인다이닝'],
  '도시 여행': ['골목 탐방', '사진'],
  '건축': ['디자인', '전시 공간'],
  '사진': ['도시 여행', '전시'],
  '바이닐': ['재즈', '인디'],
  '라이브 공연': ['페스티벌', '락'],
  '축구': ['스포츠 관람', '경기장 투어'],
  '농구': ['스포츠 관람', '경기장 투어'],
  '야구': ['스포츠 관람', '경기장 투어'],
  '러닝': ['스포츠웨어', '산책'],
  '요가': ['웰니스', '조용한 휴식'],
  '클라이밍': ['등산', '자연'],
  '등산': ['자연', '산책'],
  '강아지': ['반려 산책', '산책'],
  '고양이': ['홈라이프', '반려 용품'],
  '반려 산책': ['산책', '자연'],
  '독서': ['서점', '조용한 휴식'],
  '웰니스': ['요가', '조용한 휴식'],
  '홈라이프': ['인테리어', '집밥'],
  '로컬 탐방': ['골목 탐방', '동네 가게'],
  '산책': ['자연', '조용한 휴식'],
  '조용한 휴식': ['웰니스', '독서'],
};

/// AI 프롬프트에 넣을 허용 어휘 블록 —
/// `FOOD: 카페, 커피, ...` 형태로 카테고리별 한 줄씩.
/// 프롬프트가 이 문자열을 쓰므로 어휘를 늘리면 프롬프트도 자동으로 따라온다.
String buildTaxonomyPromptBlock() {
  return [
    for (final category in kTasteTaxonomy)
      '${category.id}: ${category.keywords.join(', ')}',
  ].join('\n');
}
