import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/recruiting_data.dart';
import '../providers/candidate_management_providers.dart';
import 'candidate_dialog_support.dart';
import 'candidate_status_widgets.dart';

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
      error: (error, stackTrace) => CandidateErrorPanel(
        message: localization.candidateActionFailed,
        onRetry: () => ref.invalidate(candidateManagementControllerProvider),
      ),
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
    final accent = stageAccentColor(context, stage);
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Text(
              '${index + 1}',
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(color: accent, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _stageControllers[stage.id],
              decoration: InputDecoration(
                labelText: localization.candidateSettingName,
                suffixIcon: Icon(
                  Icons.lock_outline,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _initializeIfNeeded(RecruitingData data, AppLocalizations localization) {
    if (_sources != null && _stages != null) return;
    _sources = [...data.sources];
    _stages = data.orderedStages;
    for (final source in data.sources) {
      _sourceControllers[source.id] = TextEditingController(
        text: localizedSourceName(localization, source),
      );
    }
    for (final stage in data.stages) {
      _stageControllers[stage.id] = TextEditingController(
        text: localizedStageName(localization, stage),
      );
    }
  }

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

  Future<void> _save() async {
    final localization = AppLocalizations.of(context);
    setState(() => _saving = true);
    final sources = <CandidateSource>[
      for (final source in _sources ?? const <CandidateSource>[])
        CandidateSource(
          id: source.id,
          name: storedSourceName(
            source.id,
            _sourceControllers[source.id]!.text.trim(),
            localization,
          ),
          isActive: source.isActive,
        ),
    ];
    final stages = <HiringStage>[
      for (final stage in _stages ?? const <HiringStage>[])
        HiringStage(
          id: stage.id,
          name: storedStageName(
            stage.id,
            _stageControllers[stage.id]!.text.trim(),
            localization,
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
      if (mounted) showCandidateActionError(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
