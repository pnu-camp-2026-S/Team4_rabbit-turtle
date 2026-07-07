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
}