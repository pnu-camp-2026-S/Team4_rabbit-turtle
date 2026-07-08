/// 매거진 title → 발행사 매핑 (스키마 v5, MagazineService.syncPublishers 전용).
/// id는 library_page.dart의 _publishers 슬러그와 반드시 동일해야 팔로우 문서 ID가
/// 일치한다. title로 매칭하므로 magazines 문서의 title 철자가 여기와 정확히
/// 같아야 한다 — 매칭 실패 시 syncPublishers()가 debugPrint로 보고한다.
class PublisherMapping {
  const PublisherMapping({required this.id, required this.name});

  final String id;
  final String name;
}

const Map<String, PublisherMapping> kPublisherByMagazineTitle = {
  // studio-log / Studio Log
  'KINDRED ROOMS': PublisherMapping(id: 'studio-log', name: 'Studio Log'),
  'apartamento': PublisherMapping(id: 'studio-log', name: 'Studio Log'),
  'KINFOLK': PublisherMapping(id: 'studio-log', name: 'Studio Log'),
  'ARK JOURNAL': PublisherMapping(id: 'studio-log', name: 'Studio Log'),

  // room-note / Room Note
  'ROOM NOTE': PublisherMapping(id: 'room-note', name: 'Room Note'),
  'Hanok Life': PublisherMapping(id: 'room-note', name: 'Room Note'),
  'Hotel Note': PublisherMapping(id: 'room-note', name: 'Room Note'),
  'Garden Edit': PublisherMapping(id: 'room-note', name: 'Room Note'),

  // oak-paper / Oak Paper
  'Craft Index': PublisherMapping(id: 'oak-paper', name: 'Oak Paper'),
  'Bookshop Map': PublisherMapping(id: 'oak-paper', name: 'Oak Paper'),
  'Frieze': PublisherMapping(id: 'oak-paper', name: 'Oak Paper'),
  'Artfair Week': PublisherMapping(id: 'oak-paper', name: 'Oak Paper'),

  // still-life / Still Life
  'CEREAL': PublisherMapping(id: 'still-life', name: 'Still Life'),
  'SUITCASE': PublisherMapping(id: 'still-life', name: 'Still Life'),
  'City Walks': PublisherMapping(id: 'still-life', name: 'Still Life'),
  'Openhouse': PublisherMapping(id: 'still-life', name: 'Still Life'),

  // the-pantry / The Pantry
  'The Gourmand': PublisherMapping(id: 'the-pantry', name: 'The Pantry'),
  'Drift': PublisherMapping(id: 'the-pantry', name: 'The Pantry'),
  'Bakery Letters': PublisherMapping(id: 'the-pantry', name: 'The Pantry'),
  'Local Table': PublisherMapping(id: 'the-pantry', name: 'The Pantry'),

  // night-index / Night Index
  'Fantastic Man': PublisherMapping(id: 'night-index', name: 'Night Index'),
  'Vinyl Night': PublisherMapping(id: 'night-index', name: 'Night Index'),
  'Wax Poetics': PublisherMapping(id: 'night-index', name: 'Night Index'),

  // field-notes / Field Notes
  'Run Log': PublisherMapping(id: 'field-notes', name: 'Field Notes'),
  'Stadium Field': PublisherMapping(id: 'field-notes', name: 'Field Notes'),
  'Yoga Paper': PublisherMapping(id: 'field-notes', name: 'Field Notes'),
};

/// 발행사 아바타 이미지 — publisherId → Unsplash 사진 URL.
/// library_page.dart의 _publishers 데모 목록과 reader_page.dart의 발행사
/// 팔로우(_showPublisher)가 공유하는 단일 소스 — 어느 한쪽만 고쳐서 둘이
/// 어긋나는 일이 없도록 여기서만 관리한다.
const Map<String, String> kPublisherImageUrlById = {
  'studio-log':
      'https://images.unsplash.com/photo-1493663284031-b7e3aefcae8e?auto=format&fit=crop&w=400&q=80',
  'room-note':
      'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&w=400&q=80',
  'oak-paper':
      'https://images.unsplash.com/photo-1509423350716-97f9360b4e09?auto=format&fit=crop&w=400&q=80',
  'still-life':
      'https://images.unsplash.com/photo-1519710164239-da123dc03ef4?auto=format&fit=crop&w=400&q=80',
  'the-pantry':
      'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?auto=format&fit=crop&w=400&q=80',
  'night-index':
      'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?auto=format&fit=crop&w=400&q=80',
  'field-notes':
      'https://images.unsplash.com/photo-1517649763962-0c623066013b?auto=format&fit=crop&w=400&q=80',
};
