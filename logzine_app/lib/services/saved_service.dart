import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// users/{uid}/saved 접근 서비스. 스키마: DB_SCHEMA.md § users/{uid}/saved
/// 비로그인 상태에서는 모든 호출이 조용히 스킵된다.
class SavedService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  DocumentReference<Map<String, dynamic>> _ref(String uid, String articleId) =>
      _db.collection('users').doc(uid).collection('saved').doc(articleId);

  /// 저장 (문서 ID: articleId)
  Future<void> save(String articleId, String magazineId) async {
    final uid = _uid;
    if (uid == null) return;
    await _ref(uid, articleId).set({
      'magazineId': magazineId,
      'savedAt': FieldValue.serverTimestamp(),
    });
  }

  /// 저장 해제
  Future<void> unsave(String articleId) async {
    final uid = _uid;
    if (uid == null) return;
    await _ref(uid, articleId).delete();
  }

  /// 저장 여부
  Future<bool> isSaved(String articleId) async {
    final uid = _uid;
    if (uid == null) return false;
    final snap = await _ref(uid, articleId).get();
    return snap.exists;
  }

  /// 저장 목록 스트림 (Saved 탭 화면용 — UI 작업에서 소비)
  Stream<QuerySnapshot<Map<String, dynamic>>> watchSaved() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();
    return _db
        .collection('users')
        .doc(uid)
        .collection('saved')
        .orderBy('savedAt', descending: true)
        .snapshots();
  }
}