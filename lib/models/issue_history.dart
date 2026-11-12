import 'issue.dart';

enum HistoryKind { created, goalReached, noticeGenerated, decision }

/// done = concluída | pending = ainda não chegou | awaiting = etapa atual (aguardando)
/// accepted = solicitação aceita pela prefeitura
enum HistoryStatus { done, pending, awaiting, accepted }

class HistoryStep {
  final HistoryKind kind;
  final HistoryStatus status;
  final String title;
  final String subtitle;
  final DateTime? date;

  const HistoryStep({
    required this.kind,
    required this.status,
    required this.title,
    required this.subtitle,
    this.date,
  });
}

class IssueHistory {
  static List<HistoryStep> build(Issue issue) {
    final threshold = (Issue.thresholdRatio * 100).round();
    final reached = issue.reachedAt != null;
    final hasNotice = issue.hasNotice;

    final decisionStep = issue.decision == IssueDecision.accepted
        ? HistoryStep(
            kind: HistoryKind.decision,
            status: HistoryStatus.accepted,
            title: 'Solicitação aceita pela prefeitura',
            subtitle: 'A prefeitura aceitou a solicitação.',
            date: issue.decisionAt,
          )
        : hasNotice
            ? const HistoryStep(
                kind: HistoryKind.decision,
                status: HistoryStatus.awaiting,
                title: 'Aguardando resposta da prefeitura',
                subtitle: 'O ofício aguarda análise.',
              )
            : const HistoryStep(
                kind: HistoryKind.decision,
                status: HistoryStatus.pending,
                title: 'Resposta da prefeitura',
                subtitle: 'Disponível após a emissão do ofício.',
              );

    return [
      HistoryStep(
        kind: HistoryKind.created,
        status: HistoryStatus.done,
        title: 'Ocorrência registrada',
        subtitle: 'Publicada na plataforma.',
        date: issue.createdAt,
      ),
      HistoryStep(
        kind: HistoryKind.goalReached,
        status: reached ? HistoryStatus.done : HistoryStatus.pending,
        title: reached
            ? 'Meta de $threshold% atingida'
            : 'Meta de $threshold% de apoio',
        subtitle: reached
            ? 'Apoio mínimo da comunidade local alcançado.'
            : 'Faltam ${issue.supportsMissing} apoios para a meta.',
        date: issue.reachedAt,
      ),
      HistoryStep(
        kind: HistoryKind.noticeGenerated,
        status: hasNotice ? HistoryStatus.done : HistoryStatus.pending,
        title: hasNotice ? 'Ofício gerado e disponível' : 'Ofício formal',
        subtitle: hasNotice
            ? 'Documento pronto para visualizar e baixar.'
            : 'Gerado automaticamente ao atingir a meta.',
        date: issue.noticeGeneratedAt,
      ),
      decisionStep,
    ];
  }
}
