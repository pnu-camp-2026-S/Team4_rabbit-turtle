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
    tags: ['데일리룩', '디자이너 브랜드', '미니멀'],
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
];
