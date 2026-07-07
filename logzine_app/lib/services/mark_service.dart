import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// users/{uid}/marks 문서 1건. 스키마: DB_SCHEMA.md § users/{uid}/marks
class MarkRecord {
  const MarkRecord({
    required this.paragraphIdx,
    required this.segmentIdx,
    required this.type,
    this.color,
    this.memoText,
  });

  final int paragraphIdx;
  final int segmentIdx;
  final String type; // "highlight" | "underline" | "memo"
  final String? color;
  final String? memoText;

  factory MarkRecord.fromMap(Map<String, dynamic> data) => MarkRecord(
        paragraphIdx: (data['paragraphIdx'] as num?)?.toInt() ?? 0,
        segmentIdx: (data['segmentIdx'] as num?)?.toInt() ?? 0,
        type: data['type'] as String? ?? 'highlight',
        color: data['color'] as String?,
        memoText: data['memoText'] as String?,
      );
}

/// users/{uid}/marks·progress 접근 서비스.
/// 비로그인 상태에서는 모든 호출이 조용히 스킵된다 (Browse without login 경로).
class MarkService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  /// 마크 저장/갱신. 문서 ID: {articleId}_{paragraphIdx}_{segmentIdx}
  Future<void> saveMark({
    required String articleId,
    required String magazineId,
    required int paragraphIdx,
    required int segmentIdx,
    required String type,
    String? colorHex,
    String? memoText,
  }) async {
    final uid = _uid;
    if (uid == null) return;
    final id = '${articleId}_${paragraphIdx}_$segmentIdx';
    await _db.collection('users').doc(uid).collection('marks').doc(id).set({
      'articleId': articleId,
      'magazineId': magazineId,
      'paragraphIdx': paragraphIdx,
      'segmentIdx': segmentIdx,
      'type': type,
      'color': colorHex,
      'memoText': memoText,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteMark(
      String articleId, int paragraphIdx, int segmentIdx) async {
    final uid = _uid;
    if (uid == null) return;
    final id = '${articleId}_${paragraphIdx}_$segmentIdx';
    await _db.collection('users').doc(uid).collection('marks').doc(id).delete();
  }

  /// 아티클 하나의 저장된 마크 전체
  Future<List<MarkRecord>> fetchMarks(String articleId) async {
    final uid = _uid;
    if (uid == null) return const [];
    final snap = await _db
        .collection('users')
        .doc(uid)
        .collection('marks')
        .where('articleId', isEqualTo: articleId)
        .get();
    return snap.docs.map((d) => MarkRecord.fromMap(d.data())).toList();
  }

  /// 읽기 진행률 저장. 스키마: users/{uid}/progress/{articleId}
  Future<void> saveProgress({
    required String articleId,
    required String magazineId,
    required int percent,
    required int lastPage,
  }) async {
    final uid = _uid;
    if (uid == null) return;
    await _db
        .collection('users')
        .doc(uid)
        .collection('progress')
        .doc(articleId)
        .set({
      'magazineId': magazineId,
      'percent': percent,
      'lastPage': lastPage,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// 저장된 마지막 페이지 (없으면 null)
  Future<int?> fetchLastPage(String articleId) async {
    final uid = _uid;
    if (uid == null) return null;
    final snap = await _db
        .collection('users')
        .doc(uid)
        .collection('progress')
        .doc(articleId)
        .get();
    return (snap.data()?['lastPage'] as num?)?.toInt();
  }
}