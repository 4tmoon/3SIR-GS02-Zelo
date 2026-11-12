import 'issue.dart';

class IssueStats {
  final int total;
  final int reached;
  final int withNotice;
  final int accepted;
  final int totalSupports;
  final Map<String, int> byCategory;
  final Map<String, int> bySeverity;

  const IssueStats({
    required this.total,
    required this.reached,
    required this.withNotice,
    required this.accepted,
    required this.totalSupports,
    required this.byCategory,
    required this.bySeverity,
  });

  int get awaiting => withNotice - accepted;

  factory IssueStats.fromIssues(List<Issue> issues) {
    final byCategory = <String, int>{for (final c in IssueCategory.all) c: 0};
    final bySeverity = <String, int>{for (final s in IssueSeverity.all) s: 0};
    var reached = 0;
    var withNotice = 0;
    var accepted = 0;
    var supports = 0;

    for (final issue in issues) {
      byCategory[issue.category] = (byCategory[issue.category] ?? 0) + 1;
      bySeverity[issue.severity] = (bySeverity[issue.severity] ?? 0) + 1;
      supports += issue.likes;
      if (issue.reachedAt != null) reached++;
      if (issue.hasNotice) withNotice++;
      if (issue.decision == IssueDecision.accepted) accepted++;
    }

    return IssueStats(
      total: issues.length,
      reached: reached,
      withNotice: withNotice,
      accepted: accepted,
      totalSupports: supports,
      byCategory: byCategory,
      bySeverity: bySeverity,
    );
  }
}