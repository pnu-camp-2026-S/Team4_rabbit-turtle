import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// 취향 여정 컨텍스트 — Why 페이지 인용용 (여정 질문 + 태그별 근거 문장).
class TasteJourneyContext {
  const TasteJourneyContext({
    required this.questions,
    required this.evidenceByTag,
  });

  /// 온보딩 여정에서 사진으로 답한 질문들 (답한 순서).
  final List<String> questions;

  /// 취향 태그 → AI가 사진에서 읽은 근거 문장.
  final Map<String, String> evidenceByTag;

  bool get isEmpty => questions.isEmpty && evidenceByTag.isEmpty;
}

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

  /// 저장된 취향 태그 읽기. 로그인 안 됨/문서 없음/실패 시 null.
  Future<List<String>?> fetchTasteTags() async {
    try {
      final snap = await _userRef.get();
      final raw = snap.data()?['tasteTags'];
      if (raw is List) return raw.cast<String>();
      return null;
    } catch (_) {
      return null; // 비로그인 등 — 호출부에서 폴백 처리
    }
  }

  /// 취향 여정 컨텍스트 저장 (전체 교체). 온보딩 AI 분석 완료 시 호출 —
  /// Why 페이지가 "이 질문에 고른 사진 때문에" 인용을 만들 때 쓴다.
  Future<void> saveTasteJourney({
    required List<String> questions,
    required Map<String, String> evidenceByTag,
  }) {
    return _userRef.update({
      'journeyQuestions': questions,
      'tasteEvidence': evidenceByTag,
    });
  }

  /// 저장된 취향 여정 컨텍스트. 로그인 안 됨/없음/실패 시 null.
  Future<TasteJourneyContext?> fetchTasteJourney() async {
    try {
      final data = (await _userRef.get()).data();
      if (data == null) return null;
      final rawQuestions = data['journeyQuestions'];
      final rawEvidence = data['tasteEvidence'];
      return TasteJourneyContext(
        questions: rawQuestions is List ? rawQuestions.cast<String>() : const [],
        evidenceByTag: rawEvidence is Map
            ? rawEvidence.map(
                (key, value) => MapEntry(key.toString(), value.toString()),
              )
            : const {},
      );
    } catch (_) {
      return null; // 비로그인 등 — 호출부에서 폴백 처리
    }
  }

  /// "Not for me" — 이 매거진을 추천에서 제외 목록에 추가.
  Future<void> excludeMagazine(String magazineId) {
    return _userRef.update({
      'excludedMagazines': FieldValue.arrayUnion([magazineId]),
      'negativeFeedback': FieldValue.arrayUnion([
        {
          'magazineId': magazineId,
          'reason': 'not_for_me',
          'createdAt': Timestamp.now(),
        },
      ]),
    });
  }

  /// 숨긴 매거진 하나를 추천 제외 목록에서 제거.
  Future<void> unhideMagazine(String magazineId) {
    return _userRef.update({
      'excludedMagazines': FieldValue.arrayRemove([magazineId]),
    });
  }

  /// "Not for me"로 숨긴 매거진 목록과 관련 피드백을 초기화.
  Future<void> resetExcludedMagazines() {
    return _userRef.update({
      'excludedMagazines': <String>[],
      'negativeFeedback': <Map<String, dynamic>>[],
    });
  }

  /// 추천 제외 매거진 ID 목록. 로그인 안 됨/없음이면 빈 목록.
  Future<List<String>> fetchExcludedMagazineIds() async {
    try {
      final snap = await _userRef.get();
      final raw = snap.data()?['excludedMagazines'];
      if (raw is List) return raw.cast<String>();
      return const [];
    } catch (_) {
      return const [];
    }
  }

  /// Settings 관리 화면용. 실패를 빈 목록으로 숨기지 않고 호출부에서 처리한다.
  Future<List<String>> fetchExcludedMagazineIdsStrict() async {
    final snap = await _userRef.get();
    final data = snap.data();
    final raw = data?['excludedMagazines'];
    if (raw is List) return raw.cast<String>();
    return const [];
  }

  /// Settings 관리 화면용. 최근 "Not for me" 피드백 순으로 숨긴 매거진 ID를 반환.
  Future<List<String>> fetchExcludedMagazineIdsByRecentStrict() async {
    final snap = await _userRef.get();
    final data = snap.data();
    final rawExcluded = data?['excludedMagazines'];
    if (rawExcluded is! List) return const [];

    final excluded = rawExcluded.cast<String>();
    final latestFeedbackAt = <String, Timestamp>{};
    final rawFeedback = data?['negativeFeedback'];
    if (rawFeedback is List) {
      for (final entry in rawFeedback) {
        if (entry is! Map) continue;
        if (entry['reason'] != 'not_for_me') continue;
        final magazineId = entry['magazineId'];
        final createdAt = entry['createdAt'];
        if (magazineId is! String || createdAt is! Timestamp) continue;
        final previous = latestFeedbackAt[magazineId];
        if (previous == null ||
            createdAt.millisecondsSinceEpoch >
                previous.millisecondsSinceEpoch) {
          latestFeedbackAt[magazineId] = createdAt;
        }
      }
    }

    final indexed = excluded.asMap().entries.toList();
    indexed.sort((a, b) {
      final aTime = latestFeedbackAt[a.value]?.millisecondsSinceEpoch;
      final bTime = latestFeedbackAt[b.value]?.millisecondsSinceEpoch;
      if (aTime != null && bTime != null && aTime != bTime) {
        return bTime.compareTo(aTime);
      }
      if (aTime != null) return -1;
      if (bTime != null) return 1;
      return b.key.compareTo(a.key);
    });
    return [for (final entry in indexed) entry.value];
  }
}
