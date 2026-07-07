/// 매거진 정보 (선반 캐러셀 · 상세 · 홈 공용 모델).
class Magazine {
  const Magazine({
    this.id = '',
    required this.title,
    required this.tagline,
    required this.issue,
    required this.coverUrl,
  });

  /// Firestore 문서 ID. 데모 상수(kMagazines)는 빈 문자열.
  final String id;
  final String title;
  final String tagline;
  final String issue;
  final String coverUrl;
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
  ),
  Magazine(
    title: 'KINFOLK',
    tagline: 'Soft light, slow living',
    issue: 'Vol. 45',
    coverUrl: 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267'
        '?auto=format&fit=crop&w=600&q=80',
  ),
  Magazine(
    title: 'ROOM NOTE',
    tagline: 'A quiet life with things that last',
    issue: 'Issue 28',
    coverUrl: 'https://images.unsplash.com/photo-1493663284031-b7e3aefcae8e'
        '?auto=format&fit=crop&w=600&q=80',
  ),
  Magazine(
    title: 'ARK JOURNAL',
    tagline: 'Architecture in everyday life',
    issue: 'Issue 16',
    coverUrl: 'https://images.unsplash.com/photo-1502005229762-cf1b2da7c5d6'
        '?auto=format&fit=crop&w=600&q=80',
  ),
  Magazine(
    title: 'apartamento',
    tagline: 'Life in small spaces',
    issue: 'Issue 33',
    coverUrl: 'https://images.unsplash.com/photo-1484154218962-a197022b5858'
        '?auto=format&fit=crop&w=600&q=80',
  ),
];
