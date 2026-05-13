import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart' show firestoreProvider;
import '../../auth/data/providers.dart' show currentUserStreamProvider;
import '../../mood/data/providers.dart' show firebaseFunctionsProvider;
import '../domain/repositories/ai_quote_repository.dart';
import '../domain/repositories/intervention_repository.dart';
import '../domain/repositories/quote_library.dart';
import '../domain/services/quote_safety_filter.dart';
import 'ai_quote_repository_impl.dart';
import 'datasources/interventions_firestore_datasource.dart';
import 'datasources/suggest_quote_functions_datasource.dart';
import 'quote_library_impl.dart';
import 'quote_safety_filter_impl.dart';
import 'repositories/intervention_repository_impl.dart';

/// Riverpod providers for the Day-2 quote infrastructure. Consumed by the
/// Day-3 dispatcher-wire-up step; co-located with the `_impl` files so
/// presentation never reaches into `data/` for a concrete type — it asks
/// for the abstract via these providers.
///
/// All four providers return the abstract type (e.g. [QuoteLibrary], not
/// [QuoteLibraryImpl]) so overrides in tests can swap in fakes without
/// touching the public surface.

/// The deterministic curated phrase library. Stateless and cheap to
/// construct, so no `keepAlive` need.
final quoteLibraryProvider = Provider<QuoteLibrary>(
  (_) => const QuoteLibraryImpl(),
);

/// The fail-closed allow-list filter for AI-suggested quote text. Pure
/// algorithm; safe to share across the tree.
final quoteSafetyFilterProvider = Provider<QuoteSafetyFilter>(
  (_) => const QuoteSafetyFilterImpl(),
);

/// Datasource that wraps `FirebaseFunctions.httpsCallable('suggestQuote')`.
/// Reuses the shared [firebaseFunctionsProvider] from `features/mood/data/`
/// so region pinning (`asia-southeast1`) stays in one place.
final suggestQuoteFunctionsDatasourceProvider =
    Provider<SuggestQuoteFunctionsDatasource>(
      (ref) =>
          SuggestQuoteFunctionsDatasource(ref.watch(firebaseFunctionsProvider)),
    );

/// The hybrid AI suggestion gateway. The dispatcher composes this with the
/// safety filter; failures here fall back to curated.
final aiQuoteRepositoryProvider = Provider<AIQuoteRepository>(
  (ref) => AIQuoteRepositoryImpl(
    datasource: ref.watch(suggestQuoteFunctionsDatasourceProvider),
  ),
);

/// Thin Firestore datasource for the
/// `users/{uid}/interventions/{dispatchId}` audit-log collection. Pulled
/// out so tests can override the cloud surface without spinning up a real
/// `FirebaseFirestore`.
final interventionsFirestoreDatasourceProvider =
    Provider<InterventionsFirestoreDatasource>(
      (ref) => InterventionsFirestoreDatasource(ref.watch(firestoreProvider)),
    );

/// Firestore-backed [InterventionRepository]. Writes are append-only at
/// the rule level (`optedOut` is the only mutable field). The controller
/// invokes [InterventionRepository.writeRecord] AFTER the dispatcher
/// returns Ok; [markOptedOut] is called when the user taps "I'm okay".
final interventionRepositoryProvider = Provider<InterventionRepository>(
  (ref) => InterventionRepositoryImpl(
    datasource: ref.watch(interventionsFirestoreDatasourceProvider),
    uidGetter: () => ref.read(currentUserStreamProvider).value?.uid,
  ),
);
