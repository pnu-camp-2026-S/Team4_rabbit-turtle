import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// 발행사 모델. 스키마: DB_SCHEMA.md § publishers/{publisherId}
class Publisher {
  const Publisher({
    required this.id,
    required this.name,
    required this.logoUrl,
    required this.tagline,
  });

  final String id;
  final String name;
  final String logoUrl;
  final String tagline;
}

/// publishers 컬렉션 및 users/{uid}/follows 접근 서비스.
/// 스키마: DB_SCHEMA.md § publishers/{publisherId}, § users/{uid}/follows/{publisherId}
/// 비로그인 상태에서는 follows 관련 호출이 조용히 스킵된다.
class PublisherService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  DocumentReference<Map<String, dynamic>> _followRef(String uid, String publisherId) =>
      _db.collection('users').doc(uid).collection('follows').doc(publisherId);

  /// 발행사 전체 목록 (목록 순서대로)
  Future<List<Publisher>> fetchPublishers() async {
    final snapshot = await _db.collection('publishers').orderBy('order').get();
    return snapshot.docs.map(_fromDoc).toList();
  }

  Publisher _fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return Publisher(
      id: doc.id,
      name: data['name'] as String? ?? '',
      logoUrl: data['logoUrl'] as String? ?? '',
      tagline: data['tagline'] as String? ?? '',
    );
  }

  /// 팔로우 (문서 ID: publisherId). logoUrl은 팔로우 목록을 추가 조회 없이
  /// 그릴 수 있도록 비정규화(원본 복사)해서 함께 저장한다 — saved와 동일 패턴.
  Future<void> follow({
    required String publisherId,
    required String publisherName,
    required String logoUrl,
  }) async {
    final uid = _uid;
    if (uid == null) return;
    await _followRef(uid, publisherId).set({
      'publisherName': publisherName,
      'logoUrl': logoUrl,
      'followedAt': FieldValue.serverTimestamp(),
    });
  }

  /// 언팔로우
  Future<void> unfollow(String publisherId) async {
    final uid = _uid;
    if (uid == null) return;
    await _followRef(uid, publisherId).delete();
  }

  /// 팔로우 여부
  Future<bool> isFollowing(String publisherId) async {
    final uid = _uid;
    if (uid == null) return false;
    final snap = await _followRef(uid, publisherId).get();
    return snap.exists;
  }

  /// 팔로우 목록 1회 조회 (followedAt 내림차순). 비로그인 시 빈 리스트.
  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> fetchFollows({
    int limit = 50,
  }) async {
    final uid = _uid;
    if (uid == null) return const [];
    final snap = await _db
        .collection('users')
        .doc(uid)
        .collection('follows')
        .orderBy('followedAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs;
  }
}
