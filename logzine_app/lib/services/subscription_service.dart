import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// users/{uid}/subscriptions 접근 서비스. 스키마: DB_SCHEMA.md § users/{uid}/subscriptions
/// 비로그인 상태에서는 모든 호출이 조용히 스킵된다.
class SubscriptionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  DocumentReference<Map<String, dynamic>> _ref(String uid, String magazineId) =>
      _db
          .collection('users')
          .doc(uid)
          .collection('subscriptions')
          .doc(magazineId);

  /// 구독 (문서 ID: magazineId)
  Future<void> subscribe({
    required String magazineId,
    required String magazineTitle,
    required String coverUrl,
  }) async {
    final uid = _uid;
    if (uid == null) return;
    await _ref(uid, magazineId).set({
      'magazineTitle': magazineTitle,
      'coverUrl': coverUrl,
      'subscribedAt': FieldValue.serverTimestamp(),
    });
  }

  /// 구독 해제
  Future<void> unsubscribe(String magazineId) async {
    final uid = _uid;
    if (uid == null) return;
    await _ref(uid, magazineId).delete();
  }

  /// 구독 여부
  Future<bool> isSubscribed(String magazineId) async {
    final uid = _uid;
    if (uid == null) return false;
    final snap = await _ref(uid, magazineId).get();
    return snap.exists;
  }

  /// 구독 목록 1회 조회 (subscribedAt 내림차순). 비로그인 시 빈 리스트.
  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> fetchSubscriptions({
    int limit = 50,
  }) async {
    final uid = _uid;
    if (uid == null) return const [];
    final snap = await _db
        .collection('users')
        .doc(uid)
        .collection('subscriptions')
        .orderBy('subscribedAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs;
  }
}
