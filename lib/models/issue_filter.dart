import 'package:zelo/models/issue.dart';

class IssueFilter {
  final Set<String> categories;
  final Set<String> severities;
  final bool onlySupported;
  final bool onlyNotice;

  const IssueFilter({
    this.categories = const {},
    this.severities = const {},
    this.onlySupported = false,
    this.onlyNotice = false,
  });

  int get activeCount =>
      categories.length + severities.length + (onlySupported ? 1 : 0) + (onlyNotice ? 1 : 0);

  bool get isEmpty => activeCount == 0;

  bool matches(Issue issue) =>
      (categories.isEmpty || categories.contains(issue.category)) &&
      (severities.isEmpty || severities.contains(issue.severity)) &&
      (!onlySupported || issue.supportedByMe) &&
      (!onlyNotice || issue.hasNotice);

  IssueFilter copyWith({
    Set<String>? categories,
    Set<String>? severities,
    bool? onlySupported,
    bool? onlyNotice,
  }) {
    return IssueFilter(
      categories: categories ?? this.categories,
      severities: severities ?? this.severities,
      onlySupported: onlySupported ?? this.onlySupported,
      onlyNotice: onlyNotice ?? this.onlyNotice,
    );
  }

  IssueFilter toggleCategory(String category) {
    final next = Set<String>.of(categories);
    if (!next.remove(category)) next.add(category);
    return copyWith(categories: next);
  }

  IssueFilter toggleSeverity(String severity) {
    final next = Set<String>.of(severities);
    if (!next.remove(severity)) next.add(severity);
    return copyWith(severities: next);
  }
}