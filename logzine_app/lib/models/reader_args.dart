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
    this.coverUrl,
    this.initialSaved = false,
  });

  final String category;
  final String title;
  final String publisher;
  final int minutes;

  /// 지정되면 이 매거진의 첫 아티클을 리더에 로드한다. null이면 데모 매거진(첫 매거진)으로 폴백.
  final String? magazineId;

  /// 지정되면(목차에서 진입) 이 아티클을 로드한다. null이면 매거진의 첫 아티클.
  final String? articleId;

  /// 매거진 표지 URL — Save 시 저장 목록 썸네일로 쓰인다. null이면 리더 기본 이미지.
  final String? coverUrl;

  /// Saved articles에서 진입한 경우 Reader가 원격 저장상태 조회 전에도
  /// 즉시 저장됨 상태를 표시할 수 있게 하는 초기값.
  final bool initialSaved;
}
