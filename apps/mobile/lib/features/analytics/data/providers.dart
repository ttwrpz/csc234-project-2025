import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/usecases/compute_analytics_state.dart';

/// Use-case provider for [ComputeAnalyticsStateUseCase]. The use case is pure
/// Dart and stateless, but we expose it through Riverpod so tests can override
/// it the same way they override repositories elsewhere.
final computeAnalyticsStateUseCaseProvider =
    Provider<ComputeAnalyticsStateUseCase>(
      (ref) => const ComputeAnalyticsStateUseCase(),
    );
