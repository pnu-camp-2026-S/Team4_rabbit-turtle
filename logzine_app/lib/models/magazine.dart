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
const List<Magazine> kMagazines = [
  Magazine(
    title: 'CEREAL',
    tagline: 'Focus on the essentials',
    issue: 'Vol. 34',
    coverUrl: 'https://images.unsplash.com/photo-1519710164239-da123dc03ef4'
        '?auto=format&fit=crop&w=600&q=80',
    tags: ['미니멀', '도시 여행', '사진'],
  ),
  Magazine(
    title: 'KINFOLK',
    tagline: 'Soft light, slow living',
    issue: 'Vol. 45',
    coverUrl: 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267'
        '?auto=format&fit=crop&w=600&q=80',
    tags: ['인테리어', '집밥', '산책'],
  ),
  Magazine(
    title: 'ROOM NOTE',
    tagline: 'A quiet life with things that last',
    issue: 'Issue 28',
    coverUrl: 'https://images.unsplash.com/photo-1493663284031-b7e3aefcae8e'
        '?auto=format&fit=crop&w=600&q=80',
    tags: ['인테리어', '가구', '공예'],
  ),
  Magazine(
    title: 'ARK JOURNAL',
    tagline: 'Architecture in everyday life',
    issue: 'Issue 16',
    coverUrl: 'https://images.unsplash.com/photo-1502005229762-cf1b2da7c5d6'
        '?auto=format&fit=crop&w=600&q=80',
    tags: ['디자인', '인테리어', '전시 공간'],
  ),
  Magazine(
    title: 'apartamento',
    tagline: 'Life in small spaces',
    issue: 'Issue 33',
    coverUrl: 'https://images.unsplash.com/photo-1484154218962-a197022b5858'
        '?auto=format&fit=crop&w=600&q=80',
    tags: ['인테리어', '빈티지', '집밥'],
  ),
  Magazine(
    title: 'Drift',
    tagline: 'Coffee, one city at a time',
    issue: 'Vol. 12',
    coverUrl: 'https://images.unsplash.com/photo-1504754524776-8f4f37790ca0'
        '?auto=format&fit=crop&w=600&q=80',
    tags: ['카페', '도시 여행', '로컬 맛집'],
  ),
  Magazine(
    title: 'The Gourmand',
    tagline: 'Food, art, and everything between',
    issue: 'Issue 21',
    coverUrl: 'https://images.unsplash.com/photo-1485955900006-10f4d324d411'
        '?auto=format&fit=crop&w=600&q=80',
    tags: ['디저트', '파인다이닝', '현대미술'],
  ),
  Magazine(
    title: 'Fantastic Man',
    tagline: 'Style for the quietly confident',
    issue: 'Issue 38',
    coverUrl: 'https://images.unsplash.com/photo-1483985988355-763728e1935b'
        '?auto=format&fit=crop&w=600&q=80',
    tags: ['데일리룩', '디자이너 브랜드', '미니멀', '클래식'],
  ),
  Magazine(
    title: 'Wax Poetics',
    tagline: 'Records worth returning to',
    issue: 'Issue 72',
    coverUrl: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745'
        '?auto=format&fit=crop&w=600&q=80',
    tags: ['바이닐', '재즈', '인디'],
  ),
  Magazine(
    title: 'Openhouse',
    tagline: 'Homes and the people who open them',
    issue: 'Issue 19',
    coverUrl: 'https://images.unsplash.com/photo-1503602642458-232111445657'
        '?auto=format&fit=crop&w=600&q=80',
    tags: ['전시 공간', '동네 가게', '작업실'],
  ),
  Magazine(
    title: 'Frieze',
    tagline: 'Contemporary art and culture',
    issue: 'Issue 240',
    coverUrl: 'https://images.unsplash.com/photo-1531913764164-f85c52e6e654'
        '?auto=format&fit=crop&w=600&q=80',
    tags: ['전시', '현대미술', '디자인'],
  ),
  Magazine(
    title: 'SUITCASE',
    tagline: 'Travel slowly, stay curious',
    issue: 'Vol. 27',
    coverUrl: 'https://images.unsplash.com/photo-1488646953014-85cb44e25828'
        '?auto=format&fit=crop&w=600&q=80',
    tags: ['도시 여행', '숙소', '주말 여행'],
  ),
  Magazine(
    title: 'PITCH SIDE',
    tagline: 'Ninety minutes, one city',
    issue: 'Issue 07',
    coverUrl: 'https://images.unsplash.com/photo-1431324155629-1a6deb1dec8d'
        '?auto=format&fit=crop&w=600&q=80',
    tags: ['축구', '야구', '스포츠 관람', '경기장 투어'],
  ),
  Magazine(
    title: 'FULL COURT',
    tagline: 'Games measured in heartbeats',
    issue: 'Issue 04',
    coverUrl: 'https://images.unsplash.com/photo-1474224017046-182ece80b263'
        '?auto=format&fit=crop&w=600&q=80',
    tags: ['농구', '배구', '테니스'],
  ),
  Magazine(
    title: 'MILEAGE',
    tagline: 'The long way round',
    issue: 'Issue 11',
    coverUrl: 'https://images.unsplash.com/photo-1480179087180-d9f0ec044897'
        '?auto=format&fit=crop&w=600&q=80',
    tags: ['러닝', '스포츠웨어', '작업 루틴'],
  ),
  Magazine(
    title: 'STILL BODY',
    tagline: 'Breathe, then begin',
    issue: 'Vol. 09',
    coverUrl: 'https://images.unsplash.com/photo-1447452001602-7090c7ab2db3'
        '?auto=format&fit=crop&w=600&q=80',
    tags: ['요가', '웰니스', '조용한 휴식'],
  ),
  Magazine(
    title: 'HOLD',
    tagline: 'Grip, trust, move',
    issue: 'Issue 05',
    coverUrl: 'https://images.unsplash.com/photo-1502126324834-38f8e02d7160'
        '?auto=format&fit=crop&w=600&q=80',
    tags: ['클라이밍', '스포츠웨어', '자연'],
  ),
  Magazine(
    title: 'TRAILHEAD',
    tagline: 'Where the path starts',
    issue: 'Issue 14',
    coverUrl: 'https://images.unsplash.com/photo-1476611338391-6f395a0ebc7b'
        '?auto=format&fit=crop&w=600&q=80',
    tags: ['등산', '산책', '자연'],
  ),
  Magazine(
    title: 'GOOD BOY',
    tagline: 'Life at the end of a leash',
    issue: 'Issue 03',
    coverUrl: 'https://images.unsplash.com/photo-1503256207526-0d5d80fa2f47'
        '?auto=format&fit=crop&w=600&q=80',
    tags: ['강아지', '반려 산책', '반려 용품'],
  ),
  Magazine(
    title: 'NINE LIVES',
    tagline: 'Quiet company, loud opinions',
    issue: 'Issue 06',
    coverUrl: 'https://images.unsplash.com/photo-1472491235688-bdc81a63246e'
        '?auto=format&fit=crop&w=600&q=80',
    tags: ['고양이', '홈라이프', '반려 용품'],
  ),
  Magazine(
    title: 'BOOM BAP',
    tagline: 'Rhythm as a first language',
    issue: 'Issue 18',
    coverUrl: 'https://images.unsplash.com/photo-1415886541506-6efc5e4b1786'
        '?auto=format&fit=crop&w=600&q=80',
    tags: ['힙합', 'R&B', '일렉트로닉'],
  ),
  Magazine(
    title: 'FEEDBACK',
    tagline: 'Loud rooms, long nights',
    issue: 'Issue 22',
    coverUrl: 'https://images.unsplash.com/photo-1429962714451-bb934ecdc4ec'
        '?auto=format&fit=crop&w=600&q=80',
    tags: ['락', '라이브 공연', '페스티벌'],
  ),
  Magazine(
    title: 'RESONANCE',
    tagline: 'Scores for ordinary days',
    issue: 'Vol. 31',
    coverUrl: 'https://images.unsplash.com/photo-1465847899084-d164df4dedc6'
        '?auto=format&fit=crop&w=600&q=80',
    tags: ['클래식 음악', '사운드트랙', '플레이리스트'],
  ),
  Magazine(
    title: 'CELLAR',
    tagline: 'Bottles worth the wait',
    issue: 'Issue 09',
    coverUrl: 'https://images.unsplash.com/photo-1472352327492-9765783b74e1'
        '?auto=format&fit=crop&w=600&q=80',
    tags: ['와인', '파인다이닝', '미식 여행'],
  ),
  Magazine(
    title: 'SLOW LEAF',
    tagline: 'Tea, and the time it takes',
    issue: 'Issue 12',
    coverUrl: 'https://images.unsplash.com/photo-1433891248364-3ce993ff0e92'
        '?auto=format&fit=crop&w=600&q=80',
    tags: ['전통차', '한옥', '조용한 휴식'],
  ),
  Magazine(
    title: 'MORNING SET',
    tagline: 'Bread, coffee, no rush',
    issue: 'Issue 08',
    coverUrl: 'https://images.unsplash.com/photo-1512820790803-83ca734da794'
        '?auto=format&fit=crop&w=600&q=80',
    tags: ['커피', '베이커리', '브런치'],
  ),
  Magazine(
    title: 'STACKS',
    tagline: 'Shelves that keep secrets',
    issue: 'Issue 17',
    coverUrl: 'https://images.unsplash.com/photo-1457369804613-52c61a468e7d'
        '?auto=format&fit=crop&w=600&q=80',
    tags: ['서점', '독서', '취미 수집'],
  ),
  Magazine(
    title: 'GREENHOUSE',
    tagline: 'Rooms that grow',
    issue: 'Issue 10',
    coverUrl: 'https://images.unsplash.com/photo-1515150144380-bca9f1650ed9'
        '?auto=format&fit=crop&w=600&q=80',
    tags: ['정원', '자연', '홈라이프'],
  ),
  Magazine(
    title: 'NIGHT DESK',
    tagline: 'Checked in, somewhere else',
    issue: 'Vol. 15',
    coverUrl: 'https://images.unsplash.com/photo-1509423350716-97f9360b4e09'
        '?auto=format&fit=crop&w=600&q=80',
    tags: ['호텔', '숙소', '해외 도시'],
  ),
  Magazine(
    title: 'THE COMPLEX',
    tagline: 'Buildings that hold a city',
    issue: 'Issue 26',
    coverUrl: 'https://images.unsplash.com/photo-1431576901776-e539bd916ba2'
        '?auto=format&fit=crop&w=600&q=80',
    tags: ['복합문화공간', '건축', '전시 공간'],
  ),
  Magazine(
    title: 'SIDE STREETS',
    tagline: 'Two blocks from the map',
    issue: 'Issue 13',
    coverUrl: 'https://images.unsplash.com/photo-1516035069371-29a1b244cc32'
        '?auto=format&fit=crop&w=600&q=80',
    tags: ['골목 탐방', '로컬 탐방', '동네 가게'],
  ),
  Magazine(
    title: 'AWAY DAYS',
    tagline: 'Travel with a fixture list',
    issue: 'Issue 02',
    coverUrl: 'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085'
        '?auto=format&fit=crop&w=600&q=80',
    tags: ['스포츠 여행', '랜드마크', '경기장 투어'],
  ),
  Magazine(
    title: 'CONCRETE FIT',
    tagline: 'Streetwear, plainly',
    issue: 'Issue 20',
    coverUrl: 'https://images.unsplash.com/photo-1508216310976-c518daae0cdc'
        '?auto=format&fit=crop&w=600&q=80',
    tags: ['스트릿', '스포츠웨어', '액세서리'],
  ),
  Magazine(
    title: 'PAPER CUT',
    tagline: 'Drawings before words',
    issue: 'Issue 24',
    coverUrl: 'https://images.unsplash.com/photo-1455390582262-044cdead277a'
        '?auto=format&fit=crop&w=600&q=80',
    tags: ['일러스트', '아트페어', '공예'],
  ),
];
