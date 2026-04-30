import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/usecases/compute_calendar_state.dart';

/// Riverpod handle for the pure-Dart calendar aggregation use case. Domain
/// classes are framework-free; only the provider lives in `data/`.
final computeCalendarStateUseCaseProvider =
    Provider<ComputeCalendarStateUseCase>((ref) {
      return const ComputeCalendarStateUseCase();
    });
