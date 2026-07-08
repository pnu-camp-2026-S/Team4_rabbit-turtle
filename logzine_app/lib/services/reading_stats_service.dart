import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// users/{uid}/readingStats 문서 1건. 스키마: DB_SCHEMA.md § users/{uid}/readingStats
class ReadingStatRecord {
  const ReadingStatRecord({required this.date, required this.secondsRead});

  /// 문서 ID이자 날짜 (yyyyMMdd)
  final String date;
  final int secondsRead;
}

/// users/{uid}/readingStats 접근 서비스. 스키마: DB_SCHEMA.md § users/{uid}/readingStats/{date}
/// 비로그인 상태에서는 모든 호출이 조용히 스킵/0 반환된다 (mark_service와 동일 정책).
class ReadingStatsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> _statsRef(String uid) =>
      _db.collection('users').doc(uid).collection('readingStats');

  /// 문서 ID 규칙: yyyyMMdd — 날짜순 정렬/범위조회를 문서 ID만으로 가능하게 함
  static String _docIdFor(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}'
      '${date.month.toString().padLeft(2, '0')}'
      '${date.day.toString().padLeft(2, '0')}';

  /// 오늘 날짜 문서에 읽은 시간(초)을 누적. 호출 여부(3초 미만 필터링)는
  /// 호출부(리더)의 책임 — 여기선 받은 값을 그대로 반영한다.
  Future<void> addReadingSeconds(int seconds) async {
    final uid = _uid;
    if (uid == null) return;
    final id = _docIdFor(DateTime.now());
    await _statsRef(uid).doc(id).set({
      'secondsRead': FieldValue.increment(seconds),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// 오늘 누적 읽기 시간(초). 문서 없음/비로그인 시 0.
  Future<int> fetchTodaySeconds() async {
    final uid = _uid;
    if (uid == null) return 0;
    final id = _docIdFor(DateTime.now());
    final snap = await _statsRef(uid).doc(id).get();
    return (snap.data()?['secondsRead'] as num?)?.toInt() ?? 0;
  }

  /// 최근 7일(오늘 포함) 통계 — 날짜 오름차순, 문서가 없는 날은 0으로 채워
  /// 항상 7개를 반환한다. 비로그인 시 7개 전부 0.
  Future<List<ReadingStatRecord>> fetchWeeklyStats() async {
    final DateTime today = DateTime.now();
    final List<DateTime> days = List<DateTime>.generate(
      7,
      (i) => today.subtract(Duration(days: 6 - i)),
    );

    final uid = _uid;
    if (uid == null) {
      return [
        for (final d in days) ReadingStatRecord(date: _docIdFor(d), secondsRead: 0),
      ];
    }

    final snap = await _statsRef(uid)
        .where(FieldPath.documentId, isGreaterThanOrEqualTo: _docIdFor(days.first))
        .where(FieldPath.documentId, isLessThanOrEqualTo: _docIdFor(days.last))
        .get();
    final Map<String, int> secondsById = {
      for (final doc in snap.docs)
        doc.id: (doc.data()['secondsRead'] as num?)?.toInt() ?? 0,
    };

    return [
      for (final d in days)
        ReadingStatRecord(
          date: _docIdFor(d),
          secondsRead: secondsById[_docIdFor(d)] ?? 0,
        ),
    ];
  }
}
