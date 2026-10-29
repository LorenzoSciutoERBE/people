import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/candidate_list_filter.dart';

final candidateListFilterProvider =
    NotifierProvider<CandidateListFilterNotifier, CandidateListFilter>(
      CandidateListFilterNotifier.new,
    );

class CandidateListFilterNotifier extends Notifier<CandidateListFilter> {
  @override
  CandidateListFilter build() => const CandidateListFilter();

  void update(CandidateListFilter Function(CandidateListFilter) change) =>
      state = change(state);

  void reset() => state = CandidateListFilter(sort: state.sort);
}
