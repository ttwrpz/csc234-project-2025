import '../entities/daily_insight.dart';
import '../entities/insight_window.dart';
import '../repositories/insights_repository.dart';

/// Thin orchestration around [InsightsRepository.watchInsights]. The
/// repository already does the heavy lifting (join + gap-fill); the use
/// case exists so controllers depend on a single-method abstraction
/// instead of the wider repository contract.
///
/// Pure-Dart class - imports only sibling domain types. Domain-purity rule
/// per CLAUDE.md.
class LoadInsightsUseCase {
  const LoadInsightsUseCase({required InsightsRepository repository})
    : _repository = repository;

  final InsightsRepository _repository;

  Stream<List<DailyInsight>> call({
    required String userId,
    required InsightWindow window,
  }) {
    return _repository.watchInsights(userId: userId, window: window);
  }
}
