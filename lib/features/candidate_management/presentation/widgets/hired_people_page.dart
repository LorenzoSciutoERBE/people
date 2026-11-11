import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/recruiting_data.dart';
import '../providers/candidate_management_providers.dart';
import 'candidate_details_page.dart';
import 'candidate_dialog_support.dart';
import 'candidate_status_widgets.dart';
import 'employee_review_dialog.dart';
import 'employment_plan_dialog.dart';
import 'employment_reminders_banner.dart';

class HiredPeoplePage extends ConsumerStatefulWidget {
  const HiredPeoplePage({super.key});

  @override
  ConsumerState<HiredPeoplePage> createState() => _HiredPeoplePageState();
}

class _HiredPeoplePageState extends ConsumerState<HiredPeoplePage> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    final now =
        ref.watch(employmentReminderClockProvider).asData?.value ??
        DateTime.now();
    return ref
        .watch(candidateManagementControllerProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => CandidateErrorPanel(
            message: localization.candidateActionFailed,
            onRetry: () =>
                ref.invalidate(candidateManagementControllerProvider),
          ),
          data: (data) {
            final people = data.hiredPeople
                .where(
                  (person) =>
                      '${person.fullName} ${person.email} ${person.offer?.position ?? ''}'
                          .toLowerCase()
                          .contains(_search),
                )
                .toList(growable: false);
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    localization.hiredPeopleTitle,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(localization.hiredPeopleSubtitle),
                  const SizedBox(height: 20),
                  TextField(
                    key: const Key('hired-people-search'),
                    decoration: InputDecoration(
                      labelText: localization.hiredPeopleSearch,
                      prefixIcon: const Icon(Icons.search),
                    ),
                    onChanged: (value) =>
                        setState(() => _search = value.trim().toLowerCase()),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: people.isEmpty
                        ? Center(
                            child: Text(
                              data.hiredPeople.isEmpty
                                  ? localization.hiredPeopleEmpty
                                  : localization.candidatesNoResults,
                            ),
                          )
                        : ListView.separated(
                            itemCount: people.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final person = people[index];
                              final reminders =
                                  person.employmentPlan
                                      ?.remindersAt(now)
                                      .length ??
                                  0;
                              return Card(
                                child: ListTile(
                                  key: ValueKey('hired-person-${person.id}'),
                                  leading: CandidateAvatar(
                                    name: person.fullName,
                                  ),
                                  title: Text(person.fullName),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        person.offer?.position.isNotEmpty ==
                                                true
                                            ? person.offer!.position
                                            : person.headline,
                                      ),
                                      if (reminders > 0)
                                        Text(
                                          localization.employmentRemindersCount(
                                            reminders,
                                          ),
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .error,
                                          ),
                                        ),
                                    ],
                                  ),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () => showDialog<void>(
                                    context: context,
                                    builder: (_) => _EmployeeHistory(
                                      candidateId: person.id,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
  }
}

class _EmployeeHistory extends ConsumerWidget {
  const _EmployeeHistory({required this.candidateId});

  final String candidateId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localization = AppLocalizations.of(context);
    final visible = ref.watch(evaluationsVisibleProvider);
    final state = ref.watch(candidateManagementControllerProvider);
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: SizedBox(
        width: 900,
        height: MediaQuery.sizeOf(context).height * 0.85,
        child: state.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => CandidateErrorPanel(
            message: localization.candidateActionFailed,
            onRetry: () =>
                ref.invalidate(candidateManagementControllerProvider),
          ),
          data: (data) {
            final person = data.hiredPeople
                .where((person) => person.id == candidateId)
                .firstOrNull;
            if (person == null) {
              return Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(localization.candidateCancel),
                ),
              );
            }
            final reviews = [...person.reviews]
              ..sort((a, b) => b.reviewedAt.compareTo(a.reviewedAt));
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          person.fullName,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        key: const Key('employee-history-close'),
                        tooltip: MaterialLocalizations.of(context)
                            .closeButtonTooltip,
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        key: const Key('employee-meeting-plan'),
                        onPressed: () => showDialog<void>(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) =>
                              EmploymentPlanDialog(candidate: person),
                        ),
                        icon: const Icon(Icons.event_note_outlined),
                        label: Text(localization.employmentPlanEdit),
                      ),
                      if (person.employmentPlan != null)
                        OutlinedButton.icon(
                          key: const Key('employee-export-calendar'),
                          onPressed: () =>
                              exportEmploymentCalendar(context, person),
                          icon: const Icon(Icons.calendar_month_outlined),
                          label: Text(localization.employmentExportCalendar),
                        ),
                      FilledButton.icon(
                        key: const Key('employee-add-review'),
                        onPressed: () => _edit(context, person),
                        icon: const Icon(Icons.add),
                        label: Text(localization.employeeAddReview),
                      ),
                      OutlinedButton.icon(
                        key: const Key('employee-recruiting-history'),
                        onPressed: () =>
                            CandidateDetailsPage.open(context, person.id),
                        icon: const Icon(Icons.history),
                        label: Text(localization.employeeRecruitingHistory),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    localization.employeeReviewsTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView(
                      children: [
                        if (person.employmentPlan case final plan?) ...[
                          Text(
                            '${localization.employmentHiringDate}: ${MaterialLocalizations.of(context).formatMediumDate(plan.hiredAt)}',
                          ),
                          for (final meeting in plan.followUps)
                            ListTile(
                              leading: Icon(
                                meeting.completed
                                    ? Icons.check_circle_outline
                                    : Icons.event_outlined,
                              ),
                              title: Text(
                                localization.employmentMilestone(
                                  meeting.monthsAfterHiring,
                                ),
                              ),
                              subtitle: Text(
                                MaterialLocalizations.of(context)
                                    .formatMediumDate(meeting.scheduledAt),
                              ),
                              trailing: meeting.completed
                                  ? Text(
                                      localization.employmentMeetingCompleted,
                                    )
                                  : meeting.scheduledAt.isBefore(
                                      DateUtils.dateOnly(DateTime.now()),
                                    )
                                  ? Text(
                                      localization.employmentOverdue,
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .error,
                                      ),
                                    )
                                  : null,
                            ),
                          const Divider(),
                        ],
                        if (!visible)
                          Text(localization.employeeReviewsHidden)
                        else if (reviews.isEmpty)
                          Text(localization.employeeReviewsEmpty)
                        else
                          for (final review in reviews)
                            Card(
                              child: ExpansionTile(
                                key: ValueKey('employee-review-${review.id}'),
                                title: Text(review.title),
                                subtitle: Text(
                                  '${MaterialLocalizations.of(context).formatMediumDate(review.reviewedAt.toLocal())} · ${review.reviewer}',
                                ),
                                childrenPadding: const EdgeInsets.all(16),
                                expandedCrossAxisAlignment:
                                    CrossAxisAlignment.stretch,
                                children: [
                                  SelectableText(review.notes),
                                  if (review.goals.isNotEmpty) ...[
                                    const SizedBox(height: 16),
                                    Text(
                                      localization.employeeReviewGoals,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall,
                                    ),
                                    const SizedBox(height: 8),
                                    SelectableText(review.goals),
                                  ],
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton.icon(
                                      key: ValueKey(
                                        'employee-review-edit-${review.id}',
                                      ),
                                      onPressed: () =>
                                          _edit(context, person, review),
                                      icon: const Icon(Icons.edit_outlined),
                                      label: Text(
                                        localization.employeeEditReview,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _edit(
    BuildContext context,
    Candidate person, [
    EmployeeReview? review,
  ]) => showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => EmployeeReviewDialog(candidate: person, existing: review),
  );
}
