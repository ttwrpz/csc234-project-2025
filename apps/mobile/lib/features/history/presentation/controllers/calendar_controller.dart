import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../mood/data/providers.dart';
import '../../data/providers.dart';
import '../../domain/entities/calendar_state.dart';

part 'calendar_controller.g.dart';

/// Future-derived [CalendarState] for the requested `month`. The `family`
/// parameter caches one state per month so prev/next navigation stays
/// snappy.
///
/// `ref.watch(myMoodsStreamProvider.future)` re-runs `build` whenever the
/// underlying mood stream emits, so the calendar stays live without us
/// touching the deprecated `.stream` accessor.
@riverpod
class CalendarController extends _$CalendarController {
  @override
  Future<CalendarState> build(DateTime month) async {
    final useCase = ref.watch(computeCalendarStateUseCaseProvider);
    final entries = await ref.watch(myMoodsStreamProvider.future);
    return useCase(entries: entries, month: month);
  }
}
