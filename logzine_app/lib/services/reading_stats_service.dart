import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// users/{uid}/readingStats 문서 1건. 스키마: DB_SCHEMA.md § users/{uid}/readingStats
class ReadingStatRecord {
  const ReadingStatRecord({required this.date, required this.secondsRead});

  /// 문서 ID이자 날짜 (yyyyMMdd)
  final String date;
  final int secondsRead;
}

/// 월간 달력 조회 1건 — 날짜별로 매핑하기 쉽도록 date를 DateTime으로 반환한다
/// (ReadingStatRecord는 문서ID 문자열 그대로라 요일 계산 등에 재파싱이 필요해
/// 주간 뷰의 기존 소비처를 건드리지 않기 위해 월간 전용으로 별도 타입을 둔다).
class MonthlyReadingRecord {
  const MonthlyReadingRecord({required this.date, required this.secondsRead});

  final DateTime date;
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

  /// 이번 주 월~일 고정 통계 — 날짜 오름차순(Mon→Sun), 문서가 없는 날(과거
  /// 미기록일·오늘 이후 미래 요일 포함)은 0으로 채워 항상 7개를 반환한다.
  /// 비로그인 시 7개 전부 0.
  Future<List<ReadingStatRecord>> fetchWeeklyStats() async {
    final DateTime monday = _mondayOfThisWeek();
    final List<DateTime> days =
        List<DateTime>.generate(7, (i) => monday.add(Duration(days: i)));

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

  /// 오늘이 속한 주의 월요일 (자정, 시각 제거) — DateTime.weekday는
  /// 월요일=1 ~ 일요일=7이므로 (weekday - 1)일을 빼면 그 주의 월요일이 된다.
  static DateTime _mondayOfThisWeek() {
    final DateTime today = DateTime.now();
    final DateTime todayDateOnly = DateTime(today.year, today.month, today.day);
    return todayDateOnly.subtract(Duration(days: todayDateOnly.weekday - 1));
  }

  /// 이번 달 1일~말일 통계 — 날짜 오름차순, 문서가 없는 날은 0으로 채워
  /// 그 달의 일수만큼 반환한다. 비로그인 시 전부 0.
  Future<List<MonthlyReadingRecord>> fetchMonthlyStats() async {
    final DateTime now = DateTime.now();
    final DateTime firstDay = DateTime(now.year, now.month, 1);
    final DateTime lastDay = DateTime(now.year, now.month + 1, 0);
    final List<DateTime> days = List<DateTime>.generate(
      lastDay.day,
      (i) => DateTime(now.year, now.month, i + 1),
    );

    final uid = _uid;
    if (uid == null) {
      return [
        for (final d in days) MonthlyReadingRecord(date: d, secondsRead: 0),
      ];
    }

    final snap = await _statsRef(uid)
        .where(FieldPath.documentId, isGreaterThanOrEqualTo: _docIdFor(firstDay))
        .where(FieldPath.documentId, isLessThanOrEqualTo: _docIdFor(lastDay))
        .get();
    final Map<String, int> secondsById = {
      for (final doc in snap.docs)
        doc.id: (doc.data()['secondsRead'] as num?)?.toInt() ?? 0,
    };

    return [
      for (final d in days)
        MonthlyReadingRecord(
          date: d,
          secondsRead: secondsById[_docIdFor(d)] ?? 0,
        ),
    ];
  }
}
