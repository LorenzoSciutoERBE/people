import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../providers/candidate_management_providers.dart';

final employmentReminderClockProvider = StreamProvider.autoDispose<DateTime>((
  ref,
) async* {
  yield DateTime.now();
  yield* Stream<DateTime>.periodic(
    const Duration(minutes: 1),
    (_) => DateTime.now(),
  );
});

class EmploymentRemindersBanner extends ConsumerWidget {
  const EmploymentRemindersBanner({super.key, required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now =
        ref.watch(employmentReminderClockProvider).asData?.value ??
        DateTime.now();
    final people = ref
        .watch(candidateManagementControllerProvider)
        .asData
        ?.value
        .hiredPeople;
    final count =
        people?.fold<int>(
          0,
          (total, person) =>
              total + (person.employmentPlan?.remindersAt(now).length ?? 0),
        ) ??
        0;
    if (count == 0) return const SizedBox.shrink();
    final localization = AppLocalizations.of(context);
    return Material(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.notifications_active_outlined),
            const SizedBox(width: 12),
            Expanded(child: Text(localization.employmentRemindersCount(count))),
            TextButton(
              key: const Key('employment-reminders-open'),
              onPressed: onOpen,
              child: Text(localization.hiredPeopleTitle),
            ),
          ],
        ),
      ),
    );
  }
}
