/// 리더 진입 시 전달하는 매거진/아티클 정보.
/// 진입 지점(추천·서재·저장 목록)마다 리더 헤더가 그에 맞게 표시된다.
class ReaderArgs {
  const ReaderArgs({
    this.category = 'Design Anthropology',
    this.title = 'Quiet Materials',
    this.publisher = 'Studio Log',
    this.minutes = 18,
    this.magazineId,
    this.articleId,
  });

  final String category;
  final String title;
  final String publisher;
  final int minutes;

  /// 지정되면 이 매거진의 첫 아티클을 리더에 로드한다. null이면 데모 매거진(첫 매거진)으로 폴백.
  final String? magazineId;

  /// 지정되면(목차에서 진입) 이 아티클을 로드한다. null이면 매거진의 첫 아티클.
  final String? articleId;
}
