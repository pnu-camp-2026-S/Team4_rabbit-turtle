/// UI에 노출되는 취향 키워드의 단일 출처.
///
/// docs/ui_keyword_vocabulary.md와 같은 목록이다. 화면, 저장값, 추천 매칭에
/// 쓰이는 태그는 이 목록을 통과한 값만 사용한다.
class UiKeywordVocabulary {
  const UiKeywordVocabulary._();

  static const Map<String, List<String>> groups = {
    'FOOD': ['카페', '커피', '디저트', '베이커리', '브런치', '전통차', '와인', '로컬 맛집'],
    'FASHION': [
      '미니멀',
      '빈티지',
      '스트릿',
      '클래식',
      '디자이너 브랜드',
      '스포츠웨어',
      '액세서리',
      '데일리룩',
    ],
    'SPACE': ['인테리어', '가구', '한옥', '호텔', '전시 공간', '서점', '정원', '복합문화공간'],
    'TRAVEL': [
      '도시 여행',
      '해외 도시',
      '랜드마크',
      '골목 탐방',
      '자연',
      '숙소',
      '미식 여행',
      '스포츠 여행',
    ],
    'ART': ['전시', '현대미술', '건축', '공예', '디자인', '일러스트', '사진', '아트페어'],
    'MUSIC': ['인디', '재즈', '라이브 공연', '페스티벌', '플레이리스트', '바이닐', '클래식', '사운드트랙'],
    'SPORTS': ['축구', '야구', '러닝', '요가', '클라이밍', '스포츠 관람', '경기장 투어', '스포츠 여행'],
    'LIFESTYLE': [
      '독서',
      '웰니스',
      '작업 루틴',
      '홈라이프',
      '반려생활',
      '취미 수집',
      '조용한 휴식',
      '로컬 탐방',
    ],
  };

  static final Map<String, String> categories = {
    for (final entry in groups.entries)
      for (final keyword in entry.value) keyword: entry.key,
  };

  static final List<String> all = [
    for (final keywords in groups.values) ...keywords,
  ];

  static final Set<String> allowed = {...all};

  static String? normalize(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return allowed.contains(trimmed) ? trimmed : aliases[trimmed];
  }

  static List<String> filter(Iterable<String> values) {
    final out = <String>[];
    final seen = <String>{};
    for (final value in values) {
      final normalized = normalize(value);
      if (normalized == null || !seen.add(normalized)) continue;
      out.add(normalized);
    }
    return out;
  }

  static const Map<String, List<String>> concepts = {
    '카페': ['place.cafe', 'food_drink.coffee'],
    '커피': ['food_drink.coffee'],
    '디저트': ['food_drink.dessert'],
    '베이커리': ['food_drink.dessert'],
    '브런치': ['food_drink.dessert'],
    '전통차': ['food_drink.tea'],
    '와인': [],
    '로컬 맛집': ['culture.local_culture'],
    '미니멀': [],
    '빈티지': ['mood.aesthetic'],
    '스트릿': [],
    '클래식': [],
    '디자이너 브랜드': [],
    '스포츠웨어': ['sports.live_sports'],
    '액세서리': [],
    '데일리룩': ['context.daily_leisure'],
    '인테리어': ['culture.architecture_design', 'mood.aesthetic'],
    '가구': ['culture.architecture_design'],
    '한옥': ['place.traditional_space', 'culture.history_tradition'],
    '호텔': [],
    '전시 공간': ['place.museum_gallery', 'culture.art_exhibition'],
    '서점': ['place.bookstore', 'activity.reading'],
    '정원': ['place.nature_outdoor', 'mood.relaxed'],
    '복합문화공간': ['context.cultural_outing', 'culture.local_culture'],
    '도시 여행': ['context.travel', 'travel.city_landmark'],
    '해외 도시': ['travel.overseas_city', 'context.travel'],
    '랜드마크': ['travel.city_landmark'],
    '골목 탐방': ['activity.local_walk', 'preference.local_discovery'],
    '자연': ['place.nature_outdoor'],
    '숙소': [],
    '미식 여행': ['context.travel', 'culture.local_culture'],
    '스포츠 여행': ['preference.sports_travel', 'context.travel'],
    '전시': ['culture.art_exhibition', 'place.museum_gallery'],
    '현대미술': ['culture.art_exhibition'],
    '건축': ['culture.architecture_design'],
    '공예': ['culture.history_tradition'],
    '디자인': ['culture.architecture_design'],
    '일러스트': [],
    '사진': ['mood.aesthetic'],
    '아트페어': ['culture.art_exhibition', 'context.cultural_outing'],
    '인디': [],
    '재즈': [],
    '라이브 공연': [],
    '페스티벌': ['mood.lively'],
    '플레이리스트': [],
    '바이닐': ['mood.aesthetic'],
    '사운드트랙': [],
    '축구': ['sports.football'],
    '야구': [],
    '러닝': ['place.nature_outdoor'],
    '요가': [],
    '클라이밍': [],
    '스포츠 관람': ['activity.sports_viewing', 'sports.live_sports'],
    '경기장 투어': ['place.stadium', 'activity.sports_viewing'],
    '독서': ['activity.reading', 'place.bookstore'],
    '웰니스': ['mood.relaxed'],
    '작업 루틴': ['activity.study_work', 'context.daily_leisure'],
    '홈라이프': ['context.daily_leisure', 'mood.relaxed'],
    '반려생활': [],
    '취미 수집': ['mood.aesthetic'],
    '조용한 휴식': ['mood.quiet', 'preference.quiet_space'],
    '로컬 탐방': ['preference.local_discovery', 'culture.local_culture'],
  };

  static const Map<String, String> aliases = {
    '집밥': '홈라이프',
    '산책': '골목 탐방',
    '파인다이닝': '미식 여행',
    '동네 가게': '로컬 탐방',
    '작업실': '작업 루틴',
    '주말 여행': '도시 여행',
    '공연': '라이브 공연',
    '로컬': '로컬 탐방',
    '갤러리': '전시',
    '예술': '전시',
    '문화생활': '전시',
    '문화/건축': '건축',
    '건축/디자인': '건축',
    '아웃도어': '자연',
    '여행': '도시 여행',
    '슬로우 라이프': '홈라이프',
    '공부/작업': '작업 루틴',
    '음악': '플레이리스트',
    '시장': '로컬 맛집',
    '동네': '로컬 탐방',
    '카페/커피': '카페',
    '전시/예술': '전시',
    '도시 탐험': '도시 여행',
    '수공예 & 휴식': '공예',
    'Warm wood': '가구',
    'Quiet rooms': '조용한 휴식',
    'Editorial mood': '디자인',
    'Light': '사진',
    'Interior': '인테리어',
    'Wood': '가구',
    'Objects': '취미 수집',
    'Books': '독서',
  };
}
