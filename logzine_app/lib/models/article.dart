/// magazines/{magazineId}/articles/{articleId} 문서 1건.
/// 스키마: DB_SCHEMA.md § magazines/{magazineId}/articles/{articleId}
class Article {
  const Article({
    required this.id,
    required this.magazineId,
    required this.title,
    required this.pageCount,
    required this.paragraphs,
  });

  final String id;
  final String magazineId;
  final String title;
  final int pageCount;

  /// 문단 → 문장 조각(segment) 리스트. reader_page.dart의 (paragraphIdx, segmentIdx)
  /// 좌표가 이 구조와 1:1로 맞아야 하이라이트/메모 복원이 성립한다.
  final List<List<String>> paragraphs;

  factory Article.fromFirestore(
    String id,
    Map<String, dynamic> data, {
    required String magazineId,
  }) {
    final List<dynamic> rawParagraphs =
        data['paragraphs'] as List<dynamic>? ?? const [];
    return Article(
      id: id,
      magazineId: magazineId,
      title: data['title'] as String? ?? '',
      pageCount: (data['pageCount'] as num?)?.toInt() ?? 0,
      paragraphs: rawParagraphs.map((p) {
        final segments = (p as Map<String, dynamic>)['segments'] as List<dynamic>?;
        return List<String>.from(segments ?? const []);
      }).toList(),
    );
  }
}
