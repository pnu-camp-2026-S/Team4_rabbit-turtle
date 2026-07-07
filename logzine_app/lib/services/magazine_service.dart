import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/magazine.dart';

/// 매거진 데이터 접근 서비스.
/// 화면은 Firestore를 직접 만지지 말고 이 클래스만 사용할 것.
/// 스키마: DB_SCHEMA.md 참고.
class MagazineService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// 매거진 전체 목록 (선반 순서대로)
  Future<List<Magazine>> fetchMagazines() async {
    final snapshot = await _db
        .collection('magazines')
        .orderBy('order')
        .get();
    return snapshot.docs.map(_fromDoc).toList();
  }

  Magazine _fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return Magazine(
      id: doc.id,
      title: data['title'] as String? ?? '',
      tagline: data['tagline'] as String? ?? '',
      issue: data['issue'] as String? ?? '',
      coverUrl: data['coverUrl'] as String? ?? '',
    );
  }

  /// [시드] kMagazines 데모 데이터를 Firestore에 1회 입력.
  /// magazines 컬렉션이 비어 있을 때만 동작 (중복 방지).
  Future<void> seedIfEmpty() async {
    final existing = await _db.collection('magazines').limit(1).get();
    if (existing.docs.isNotEmpty) return;

    final batch = _db.batch();
    for (var i = 0; i < kMagazines.length; i++) {
      final m = kMagazines[i];
      final ref = _db.collection('magazines').doc();
      batch.set(ref, {
        'title': m.title,
        'tagline': m.tagline,
        'issue': m.issue,
        'coverUrl': m.coverUrl,
        'tags': <String>[],
        'order': i,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  /// 아티클 본문 문단 조회. 각 원소는 문장 조각(segment) 리스트.
  /// 마크의 좌표(paragraphIdx, segmentIdx)로 인용문을 찾을 때 사용.
  /// 스키마: magazines/{magazineId}/articles/{articleId}.paragraphs
  Future<List<List<String>>?> fetchArticleParagraphs({
    required String magazineId,
    required String articleId,
  }) async {
    final doc = await _db
        .collection('magazines')
        .doc(magazineId)
        .collection('articles')
        .doc(articleId)
        .get();
    final List<dynamic>? paragraphs = doc.data()?['paragraphs'] as List<dynamic>?;
    if (paragraphs == null) return null;
    return paragraphs.map((p) {
      final segments = (p as Map<String, dynamic>)['segments'] as List<dynamic>?;
      return List<String>.from(segments ?? const []);
    }).toList();
  }

  /// [임시] 리더 데모 아티클의 ID — 첫 매거진의 첫 아티클.
  /// 리더 콘텐츠 동적화(로드맵) 전까지 marks/progress의 대상 지정용.
  Future<({String magazineId, String articleId})?> fetchDemoArticleIds() async {
    final mag =
        await _db.collection('magazines').orderBy('order').limit(1).get();
    if (mag.docs.isEmpty) return null;
    final String magId = mag.docs.first.id;
    final art = await _db
        .collection('magazines')
        .doc(magId)
        .collection('articles')
        .orderBy('order')
        .limit(1)
        .get();
    if (art.docs.isEmpty) return null;
    return (magazineId: magId, articleId: art.docs.first.id);
  }

  /// [시드] 첫 매거진에 데모 아티클 1편 입력 (비어 있을 때만).
  /// ⚠️ 본문은 reader_page.dart의 _paragraphs와 반드시 동일해야
  /// (paragraphIdx, segmentIdx) 좌표가 성립한다.
  Future<void> seedDemoArticleIfEmpty() async {
    final mag =
        await _db.collection('magazines').orderBy('order').limit(1).get();
    if (mag.docs.isEmpty) return;
    final articles =
        mag.docs.first.reference.collection('articles');
    final existing = await articles.limit(1).get();
    if (existing.docs.isNotEmpty) return;

    await articles.add({
      'title': 'Quiet Materials',
      'order': 0,
      'pageCount': 12,
      'paragraphs': [
        {
          'segments': [
            'Materials shape the mood of a space.',
            'When light, texture, and proportion align, '
                'the quiet becomes a language.',
          ],
        },
        {
          'segments': [
            'Wood, stone, linen—honest materials',
            'that age beautifully and hold meaning over time.',
          ],
        },
        {
          'segments': [
            'In a world that moves fast, slow spaces',
            'remind us to notice the small things.',
          ],
        },
      ],
    });
  }
}