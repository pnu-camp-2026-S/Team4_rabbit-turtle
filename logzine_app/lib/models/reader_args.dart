/// 리더 진입 시 전달하는 매거진/아티클 정보.
/// 진입 지점(추천·서재·저장 목록)마다 리더 헤더가 그에 맞게 표시된다.
class ReaderArgs {
  const ReaderArgs({
    this.category = 'Design Anthropology',
    this.title = 'Quiet Materials',
    this.publisher = 'Studio Log',
    this.minutes = 18,
  });

  final String category;
  final String title;
  final String publisher;
  final int minutes;
}
