import 'magazine.dart';

class WhyIssueArgs {
  const WhyIssueArgs({
    required this.magazine,
    this.tasteBasis = const <String>[],
  });

  final Magazine magazine;
  final List<String> tasteBasis;
}

class StandPageArgs {
  const StandPageArgs({this.viewAll = false, this.selectedTaste});

  final bool viewAll;
  final String? selectedTaste;
}
