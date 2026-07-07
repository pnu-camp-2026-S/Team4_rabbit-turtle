import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// users/{uid} 문서 관련 로직. 스키마: DB_SCHEMA.md § users/{uid}
class UserService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  DocumentReference<Map<String, dynamic>> get _userRef {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('로그인 상태에서만 호출할 수 있습니다.');
    }
    return _db.collection('users').doc(uid);
  }

  /// users/{uid} 문서가 없으면 생성 (멱등). 로그인/가입 성공 직후 호출.
  Future<void> ensureUserDoc() async {
    final ref = _userRef;
    final snap = await ref.get();
    if (snap.exists) return;
    await ref.set({
      'email': _auth.currentUser?.email,
      'tasteTags': <String>[],
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// 온보딩 취향 태그 저장 (전체 교체)
  Future<void> saveTasteTags(List<String> tags) {
    return _userRef.update({'tasteTags': tags});
  }
}