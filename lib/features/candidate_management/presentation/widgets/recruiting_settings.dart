import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/recruiting_data.dart';
import '../providers/candidate_management_providers.dart';

extension on TextEditingController {
  /// Defers disposal until the widgets using this controller are rebuilt.
  void disposeAfterFrame() =>
      WidgetsBinding.instance.addPostFrameCallback((_) => dispose());
}

class RecruitingSettings extends ConsumerStatefulWidget {
  const RecruitingSettings({super.key});

  @override
  ConsumerState<RecruitingSettings> createState() => _RecruitingSettingsState();
}

class _RecruitingSettingsState extends ConsumerState<RecruitingSettings> {
  final Map<String, TextEditingController> _sourceControllers = {};
  final Map<String, TextEditingController> _stageControllers = {};
  List<CandidateSource>? _sources;
  List<HiringStage>? _stages;
  bool _saving = false;

  @override
  void dispose() {
    for (final controller in _sourceControllers.values) {
      controller.dispose();
    }
    for (final controller in _stageControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    final state = ref.watch(candidateManagementControllerProvider);
    return state.when(
      data: (data) {
        _initializeIfNeeded(data, localization);
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1050),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _sourcesCard(localization),
                  const SizedBox(height: 18),
                  _stagesCard(localization),
                  const SizedBox(height: 18),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(localization.candidateSettingSave),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      error: (error, stackTrace) =>
          Center(child: Text(localization.candidateActionFailed)),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _sourcesCard(AppLocalizations localization) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  localization.candidateSourcesTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              TextButton.icon(
                onPressed: _addSource,
                icon: const Icon(Icons.add),
                label: Text(localization.candidateSourceAdd),
              ),
            ],
          ),
          for (final source in _sources ?? const <CandidateSource>[])
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _sourceControllers[source.id],
                      decoration: InputDecoration(
                        labelText: localization.candidateSettingName,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    tooltip: localization.candidateDelete,
                    onPressed: () => _removeSource(source.id),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
  );

  Widget _stagesCard(AppLocalizations localization) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  localization.candidateStagesTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              TextButton.icon(
                onPressed: _addStage,
                icon: const Icon(Icons.add),
                label: Text(localization.candidateStageAdd),
              ),
            ],
          ),
          for (var index = 0; index < (_stages?.length ?? 0); index++)
            _stageRow(localization, index),
        ],
      ),
    ),
  );

  Widget _stageRow(AppLocalizations localization, int index) {
    final stage = _stages![index];
    final isTerminal =
        stage.terminalOutcome != TerminalOutcome.active ||
        stage.isOfferStage ||
        stage.id == 'new';
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _stageControllers[stage.id],
              decoration: InputDecoration(
                labelText: localization.candidateSettingName,
              ),
            ),
          ),
          IconButton(
            tooltip: localization.candidateStageMoveUp,
            onPressed: index == 0 ? null : () => _moveStage(index, index - 1),
            icon: const Icon(Icons.arrow_upward),
          ),
          IconButton(
            tooltip: localization.candidateStageMoveDown,
            onPressed: index == _stages!.length - 1
                ? null
                : () => _moveStage(index, index + 1),
            icon: const Icon(Icons.arrow_downward),
          ),
          IconButton(
            tooltip: localization.candidateDelete,
            onPressed: isTerminal || stage.isOfferStage
                ? null
                : () => _removeStage(stage.id),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }

  void _initializeIfNeeded(RecruitingData data, AppLocalizations localization) {
    if (_sources != null && _stages != null) return;
    _sources = [...data.sources];
    _stages = [...data.stages]
      ..sort((first, second) => first.order.compareTo(second.order));
    for (final source in data.sources) {
      _sourceControllers[source.id] = TextEditingController(
        text: _localizedSourceName(localization, source),
      );
    }
    for (final stage in data.stages) {
      _stageControllers[stage.id] = TextEditingController(
        text: _localizedStageName(localization, stage),
      );
    }
  }

  String _localizedSourceName(
    AppLocalizations localization,
    CandidateSource source,
  ) {
    final defaultName = _defaultSourceName(source.id);
    return defaultName != null && source.name == defaultName
        ? _localizedSourceDefault(localization, source.id)
        : source.name;
  }

  String _localizedStageName(AppLocalizations localization, HiringStage stage) {
    final defaultName = _defaultStageName(stage.id);
    return defaultName != null && stage.name == defaultName
        ? _localizedStageDefault(localization, stage.id)
        : stage.name;
  }

  String _storedSourceName(
    String id,
    String editedName,
    AppLocalizations localization,
  ) => editedName == _localizedSourceDefault(localization, id)
      ? _defaultSourceName(id) ?? editedName
      : editedName;

  String _storedStageName(
    String id,
    String editedName,
    AppLocalizations localization,
  ) => editedName == _localizedStageDefault(localization, id)
      ? _defaultStageName(id) ?? editedName
      : editedName;

  String? _defaultSourceName(String id) => switch (id) {
    'grafton' => 'Grafton',
    'poli' => 'Poli',
    'github' => 'GitHub',
    'other' => 'Other',
    _ => null,
  };

  String _localizedSourceDefault(AppLocalizations localization, String id) =>
      switch (id) {
        'grafton' => localization.candidateDefaultGrafton,
        'poli' => localization.candidateDefaultPoli,
        'github' => localization.candidateDefaultGithub,
        'other' => localization.candidateDefaultOther,
        _ => '',
      };

  String? _defaultStageName(String id) => switch (id) {
    'new' => 'New',
    'cv_review' => 'CV review',
    'screening' => 'Screening interview',
    'technical' => 'Technical interview',
    'final' => 'Final interview',
    'offer' => 'Offer / pre-contract',
    'hired' => 'Hired',
    'rejected' => 'Rejected',
    _ => null,
  };

  String _localizedStageDefault(AppLocalizations localization, String id) =>
      switch (id) {
        'new' => localization.candidateDefaultNew,
        'cv_review' => localization.candidateDefaultCvReview,
        'screening' => localization.candidateDefaultScreening,
        'technical' => localization.candidateDefaultTechnical,
        'final' => localization.candidateDefaultFinal,
        'offer' => localization.candidateDefaultOffer,
        'hired' => localization.candidateDefaultHired,
        'rejected' => localization.candidateDefaultRejected,
        _ => '',
      };

  void _addSource() {
    final source = CandidateSource(id: const Uuid().v4(), name: '');
    setState(() {
      _sources = [...?_sources, source];
      _sourceControllers[source.id] = TextEditingController();
    });
  }

  void _removeSource(String id) {
    setState(() {
      _sources = _sources!.where((source) => source.id != id).toList();
      _sourceControllers.remove(id)?.disposeAfterFrame();
    });
  }

  void _addStage() {
    final currentStages = [...?_stages];
    final offerIndex = currentStages.indexWhere((stage) => stage.isOfferStage);
    final stage = HiringStage(id: const Uuid().v4(), name: '', order: 0);
    currentStages.insert(
      offerIndex < 0 ? currentStages.length : offerIndex,
      stage,
    );
    setState(() {
      _stages = currentStages;
      _stageControllers[stage.id] = TextEditingController();
      _reindexStages();
    });
  }

  void _removeStage(String id) {
    setState(() {
      _stages = _stages!.where((stage) => stage.id != id).toList();
      _stageControllers.remove(id)?.disposeAfterFrame();
      _reindexStages();
    });
  }

  void _moveStage(int from, int to) {
    setState(() {
      final stages = [...?_stages];
      final moved = stages.removeAt(from);
      stages.insert(to, moved);
      _stages = stages;
      _reindexStages();
    });
  }

  void _reindexStages() {
    _stages = <HiringStage>[
      for (var index = 0; index < _stages!.length; index++)
        HiringStage(
          id: _stages![index].id,
          name: _stages![index].name,
          order: index,
          isOfferStage: _stages![index].isOfferStage,
          terminalOutcome: _stages![index].terminalOutcome,
        ),
    ];
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final sources = <CandidateSource>[
      for (final source in _sources ?? const <CandidateSource>[])
        CandidateSource(
          id: source.id,
          name: _storedSourceName(
            source.id,
            _sourceControllers[source.id]!.text.trim(),
            AppLocalizations.of(context),
          ),
          isActive: source.isActive,
        ),
    ];
    final stages = <HiringStage>[
      for (final stage in _stages ?? const <HiringStage>[])
        HiringStage(
          id: stage.id,
          name: _storedStageName(
            stage.id,
            _stageControllers[stage.id]!.text.trim(),
            AppLocalizations.of(context),
          ),
          order: stage.order,
          isOfferStage: stage.isOfferStage,
          terminalOutcome: stage.terminalOutcome,
        ),
    ];
    try {
      final controller = ref.read(
        candidateManagementControllerProvider.notifier,
      );
      await controller.saveConfiguration(sources: sources, stages: stages);
      if (mounted) {
        for (final controller in _sourceControllers.values) {
          controller.disposeAfterFrame();
        }
        for (final controller in _stageControllers.values) {
          controller.disposeAfterFrame();
        }
        _sourceControllers.clear();
        _stageControllers.clear();
        setState(() {
          _sources = null;
          _stages = null;
        });
      }
    } on Object {
      if (mounted) _showError();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).candidateActionFailed),
      ),
    );
  }
}
