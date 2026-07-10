/// 매거진 정보 (선반 캐러셀 · 상세 · 홈 공용 모델).
class Magazine {
  const Magazine({
    this.id = '',
    required this.title,
    required this.tagline,
    required this.issue,
    required this.coverUrl,
    this.tags = const <String>[],
    this.publisherId = '',
    this.publisherName = '',
  });

  /// Firestore 문서 ID. 데모 상수(kMagazines)는 빈 문자열.
  final String id;
  final String title;
  final String tagline;
  final String issue;
  final String coverUrl;

  /// 취향 매칭용 태그 — 취향 픽커(taste_picker_page) 어휘와 동일해야
  /// 사용자 tasteTags와 교집합 추천이 성립한다.
  final List<String> tags;

  /// 발행사 매핑 (스키마 v5). id는 library_page.dart의 _publishers 슬러그와
  /// 동일. 데모 상수(kMagazines)는 빈 문자열 — 실데이터는
  /// MagazineService.syncPublishers() 마이그레이션 이후 채워진다.
  final String publisherId;
  final String publisherName;
}

/// 데모용 매거진 카탈로그.
/// TODO: 전 화면 Firestore 전환 후 제거.
/// TODO(#8): 백엔드/로컬 저장소 연동 시 리포지토리 계층으로 대체.
/// 데모용 매거진 카탈로그 — **Firestore `magazines` 컬렉션의 미러**.
/// 앞쪽은 현재 시드된 매거진과 태그가 동일하므로 syncCatalog가 덮어쓰지 않는다.
/// 태그는 반드시 `taste_taxonomy.dart`의 키워드만 사용한다 (테스트가 강제).
const List<Magazine> kMagazines = [
  Magazine(
    title: 'CEREAL',
    tagline: 'Focus on the essentials',
    issue: 'Vol. 34',
    coverUrl:
        'https://images.unsplash.com/photo-1497366754035-f200968a6e72'
        '?auto=format&fit=crop&w=900&q=80',
    tags: ['미니멀', '도시 여행', '사진'],
  ),
  Magazine(
    title: 'KINDRED ROOMS',
    tagline: 'Soft light, slow living',
    issue: 'Issue 08',
    coverUrl:
        'https://images.unsplash.com/photo-1524758631624-e2822e304c36'
        '?auto=format&fit=crop&w=900&q=80',
    tags: ['인테리어', '조용한 휴식', '홈라이프'],
  ),
  Magazine(
    title: 'KINFOLK',
    tagline: 'Soft light, slow living',
    issue: 'Vol. 45',
    coverUrl:
        'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267'
        '?auto=format&fit=crop&w=600&q=80',
    tags: ['인테리어', '집밥', '산책'],
  ),
  Magazine(
    title: 'ROOM NOTE',
    tagline: 'A quiet life with things that last',
    issue: 'Issue 28',
    coverUrl:
        'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85'
        '?auto=format&fit=crop&w=900&q=80',
    tags: ['인테리어', '가구', '공예'],
  ),
  Magazine(
    title: 'ARK JOURNAL',
    tagline: 'Architecture in everyday life',
    issue: 'Issue 16',
    coverUrl:
        'https://images.unsplash.com/photo-1511818966892-d7d671e672a2'
        '?auto=format&fit=crop&w=900&q=80',
    tags: ['건축', '인테리어', '디자인'],
  ),
  Magazine(
    title: 'apartamento',
    tagline: 'Life in small spaces',
    issue: 'Issue 33',
    coverUrl:
        'https://images.unsplash.com/photo-1484154218962-a197022b5858'
        '?auto=format&fit=crop&w=600&q=80',
    tags: ['인테리어', '빈티지', '집밥'],
  ),
  Magazine(
    title: 'Drift',
    tagline: 'Coffee, one city at a time',
    issue: 'Vol. 12',
    coverUrl:
        'https://images.unsplash.com/photo-1442512595331-e89e73853f31'
        '?auto=format&fit=crop&w=900&q=80',
    tags: ['카페', '커피', '도시 여행'],
  ),
  Magazine(
    title: 'The Gourmand',
    tagline: 'Food, art, and everything between',
    issue: 'Issue 21',
    coverUrl:
        'https://images.unsplash.com/photo-1504674900247-0877df9cc836'
        '?auto=format&fit=crop&w=900&q=80',
    tags: ['디저트', '브런치', '현대미술'],
  ),
  Magazine(
    title: 'Fantastic Man',
    tagline: 'Style for the quietly confident',
    issue: 'Issue 38',
    coverUrl:
        'https://images.unsplash.com/photo-1496747611176-843222e1e57c'
        '?auto=format&fit=crop&w=900&q=80',
    tags: ['데일리룩', '디자이너 브랜드', '미니멀'],
  ),
  Magazine(
    title: 'Wax Poetics',
    tagline: 'Records worth returning to',
    issue: 'Issue 72',
    coverUrl:
        'https://images.unsplash.com/photo-1516280440614-37939bbacd81'
        '?auto=format&fit=crop&w=900&q=80',
    tags: ['바이닐', '재즈', '인디'],
  ),
  Magazine(
    title: 'Openhouse',
    tagline: 'Homes and the people who open them',
    issue: 'Issue 19',
    coverUrl:
        'https://images.unsplash.com/photo-1524758631624-e2822e304c36'
        '?auto=format&fit=crop&w=901&q=80',
    tags: ['전시 공간', '서점', '복합문화공간'],
  ),
  Magazine(
    title: 'Frieze',
    tagline: 'Contemporary art and culture',
    issue: 'Issue 240',
    coverUrl:
        'https://images.unsplash.com/photo-1531058020387-3be344556be6'
        '?auto=format&fit=crop&w=900&q=80',
    tags: ['전시', '현대미술', '디자인'],
  ),
  Magazine(
    title: 'SUITCASE',
    tagline: 'Travel slowly, stay curious',
    issue: 'Vol. 27',
    coverUrl:
        'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee'
        '?auto=format&fit=crop&w=900&q=80',
    tags: ['도시 여행', '숙소', '골목 탐방'],
  ),
  Magazine(
    title: 'Hanok Life',
    tagline: 'Traditional rooms, modern rituals',
    issue: 'Issue 04',
    // 기존 표지 URL(photo-1538485399081…)은 404 — 검증된 한옥 사진으로 교체.
    coverUrl:
        'https://images.unsplash.com/photo-1601721826401-c5e789be0be6'
        '?auto=format&fit=crop&w=600&q=80',
    tags: ['한옥', '전통차', '조용한 휴식'],
  ),
  Magazine(
    title: 'Stadium Field',
    tagline: 'Football, places, and matchday culture',
    issue: 'Vol. 06',
    coverUrl:
        'https://images.unsplash.com/photo-1489944440615-453fc2b6a9a9'
        '?auto=format&fit=crop&w=900&q=80',
    tags: ['축구', '스포츠 관람', '경기장 투어'],
  ),
  Magazine(
    title: 'Run Log',
    tagline: 'Routes, recovery, and morning pace',
    issue: 'Issue 03',
    coverUrl:
        'https://images.unsplash.com/photo-1461896836934-ffe607ba8211'
        '?auto=format&fit=crop&w=900&q=80',
    tags: ['러닝', '웰니스', '자연'],
  ),
  Magazine(
    title: 'Craft Index',
    tagline: 'Hands, clay, paper, and collected objects',
    issue: 'Issue 11',
    coverUrl:
        'https://images.unsplash.com/photo-1452860606245-08befc0ff44b'
        '?auto=format&fit=crop&w=900&q=80',
    tags: ['공예', '취미 수집', '디자인'],
  ),
  Magazine(
    title: 'Garden Edit',
    tagline: 'Leaves, courtyards, and small outdoor rooms',
    issue: 'Vol. 05',
    coverUrl:
        'https://images.unsplash.com/photo-1416879595882-3373a0480b5b'
        '?auto=format&fit=crop&w=900&q=80',
    tags: ['정원', '자연', '웰니스'],
  ),
  Magazine(
    title: 'Bookshop Map',
    tagline: 'Reading rooms and local shelves',
    issue: 'Issue 14',
    coverUrl:
        'https://images.unsplash.com/photo-1526243741027-444d633d7365'
        '?auto=format&fit=crop&w=900&q=80',
    tags: ['서점', '독서', '로컬 탐방'],
  ),
  Magazine(
    title: 'Vinyl Night',
    tagline: 'Listening bars and warm records',
    issue: 'Vol. 09',
    coverUrl:
        'https://images.unsplash.com/photo-1470225620780-dba8ba36b745'
        '?auto=format&fit=crop&w=900&q=80',
    tags: ['바이닐', '재즈', '라이브 공연'],
  ),
  Magazine(
    title: 'Bakery Letters',
    tagline: 'Bread, dessert, and neighborhood mornings',
    issue: 'Issue 02',
    coverUrl:
        'https://images.unsplash.com/photo-1509440159596-0249088772ff'
        '?auto=format&fit=crop&w=900&q=80',
    tags: ['베이커리', '디저트', '카페'],
  ),
  Magazine(
    title: 'Local Table',
    tagline: 'Neighborhood food and small discoveries',
    issue: 'Vol. 18',
    coverUrl:
        'https://images.unsplash.com/photo-1514933651103-005eec06c04b'
        '?auto=format&fit=crop&w=900&q=80',
    tags: ['로컬 맛집', '미식 여행', '골목 탐방'],
  ),
  Magazine(
    title: 'Hotel Note',
    tagline: 'Stays with texture and calm',
    issue: 'Issue 07',
    coverUrl:
        'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb'
        '?auto=format&fit=crop&w=900&q=80',
    tags: ['호텔', '숙소', '조용한 휴식'],
  ),
  Magazine(
    title: 'City Walks',
    tagline: 'Alleys, landmarks, and local rhythm',
    issue: 'Issue 15',
    coverUrl:
        'https://images.unsplash.com/photo-1518005020951-eccb494ad742'
        '?auto=format&fit=crop&w=900&q=80',
    tags: ['골목 탐방', '랜드마크', '로컬 탐방'],
  ),
  Magazine(
    title: 'Artfair Week',
    tagline: 'Collectors, booths, and the tempo of looking',
    issue: 'Vol. 03',
    coverUrl:
        'https://images.unsplash.com/photo-1529156069898-49953e39b3ac'
        '?auto=format&fit=crop&w=900&q=80',
    tags: ['아트페어', '전시', '취미 수집'],
  ),
  Magazine(
    title: 'Yoga Paper',
    tagline: 'Breath, balance, and gentle routines',
    issue: 'Issue 06',
    coverUrl:
        'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b'
        '?auto=format&fit=crop&w=900&q=80',
    tags: ['요가', '웰니스', '작업 루틴'],
  ),
  // ── 아래부터: 취향 세분화로 생긴 빈 칸을 채우는 매거진
  Magazine(
    title: 'BOOM BAP',
    tagline: 'Rhythm as a first language',
    issue: 'Issue 18',
    coverUrl:
        'https://images.unsplash.com/photo-1415886541506-6efc5e4b1786'
        '?auto=format&fit=crop&w=600&q=80',
    tags: ['힙합', 'R&B', '일렉트로닉'],
  ),
  Magazine(
    title: 'FEEDBACK',
    tagline: 'Loud rooms, long nights',
    issue: 'Issue 22',
    coverUrl:
        'https://images.unsplash.com/photo-1429962714451-bb934ecdc4ec'
        '?auto=format&fit=crop&w=600&q=80',
    tags: ['락', '페스티벌', '라이브 공연'],
  ),
  Magazine(
    title: 'RESONANCE',
    tagline: 'Scores for ordinary days',
    issue: 'Vol. 31',
    coverUrl:
        'https://images.unsplash.com/photo-1465847899084-d164df4dedc6'
        '?auto=format&fit=crop&w=600&q=80',
    tags: ['클래식 음악', '사운드트랙', '플레이리스트'],
  ),
  Magazine(
    title: 'FULL COURT',
    tagline: 'Games measured in heartbeats',
    issue: 'Issue 04',
    coverUrl:
        'https://images.unsplash.com/photo-1474224017046-182ece80b263'
        '?auto=format&fit=crop&w=600&q=80',
    tags: ['농구', '배구', '테니스'],
  ),
  Magazine(
    title: 'EXTRA INNING',
    tagline: 'Nine innings, no clock',
    issue: 'Issue 07',
    coverUrl:
        'https://images.unsplash.com/photo-1471295253337-3ceaaedca402'
        '?auto=format&fit=crop&w=600&q=80',
    tags: ['야구', '스포츠 관람', '스포츠 여행'],
  ),
  Magazine(
    title: 'HOLD',
    tagline: 'Grip, trust, move',
    issue: 'Issue 05',
    coverUrl:
        'https://images.unsplash.com/photo-1502126324834-38f8e02d7160'
        '?auto=format&fit=crop&w=600&q=80',
    tags: ['클라이밍', '등산', '스포츠웨어'],
  ),
  Magazine(
    title: 'GOOD BOY',
    tagline: 'Life at the end of a leash',
    issue: 'Issue 03',
    coverUrl:
        'https://images.unsplash.com/photo-1503256207526-0d5d80fa2f47'
        '?auto=format&fit=crop&w=600&q=80',
    tags: ['강아지', '반려 산책', '반려 용품'],
  ),
  Magazine(
    title: 'NINE LIVES',
    tagline: 'Quiet company, loud opinions',
    issue: 'Issue 06',
    coverUrl:
        'https://images.unsplash.com/photo-1472491235688-bdc81a63246e'
        '?auto=format&fit=crop&w=600&q=80',
    tags: ['고양이', '반려 용품', '홈라이프'],
  ),
  Magazine(
    title: 'CONCRETE FIT',
    tagline: 'Streetwear, plainly',
    issue: 'Issue 20',
    coverUrl:
        'https://images.unsplash.com/photo-1508216310976-c518daae0cdc'
        '?auto=format&fit=crop&w=600&q=80',
    tags: ['스트릿', '액세서리', '클래식'],
  ),
  Magazine(
    title: 'CELLAR',
    tagline: 'Bottles worth the wait',
    issue: 'Issue 09',
    coverUrl:
        'https://images.unsplash.com/photo-1472352327492-9765783b74e1'
        '?auto=format&fit=crop&w=600&q=80',
    tags: ['와인', '파인다이닝', '미식 여행'],
  ),
  Magazine(
    title: 'NIGHT DESK',
    tagline: 'Checked in, somewhere else',
    issue: 'Vol. 15',
    coverUrl:
        'https://images.unsplash.com/photo-1509423350716-97f9360b4e09'
        '?auto=format&fit=crop&w=600&q=80',
    tags: ['해외 도시', '주말 여행', '호텔'],
  ),
  Magazine(
    title: 'CORNER SHOP',
    tagline: 'Two blocks from the map',
    issue: 'Issue 13',
    coverUrl:
        'https://images.unsplash.com/photo-1516035069371-29a1b244cc32'
        '?auto=format&fit=crop&w=600&q=80',
    tags: ['동네 가게', '로컬 탐방', '골목 탐방'],
  ),
  Magazine(
    title: 'PAPER CUT',
    tagline: 'Drawings before words',
    issue: 'Issue 24',
    coverUrl:
        'https://images.unsplash.com/photo-1455390582262-044cdead277a'
        '?auto=format&fit=crop&w=600&q=80',
    tags: ['일러스트', '작업실', '공예'],
  ),
];
