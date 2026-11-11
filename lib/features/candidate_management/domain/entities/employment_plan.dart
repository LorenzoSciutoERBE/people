class EmploymentFollowUp {
  const EmploymentFollowUp({
    required this.monthsAfterHiring,
    required this.scheduledAt,
    this.completed = false,
  });

  final int monthsAfterHiring;
  final DateTime scheduledAt;
  final bool completed;

  EmploymentFollowUp copyWith({DateTime? scheduledAt, bool? completed}) =>
      EmploymentFollowUp(
        monthsAfterHiring: monthsAfterHiring,
        scheduledAt: scheduledAt ?? this.scheduledAt,
        completed: completed ?? this.completed,
      );
}

class EmploymentPlan {
  const EmploymentPlan({required this.hiredAt, required this.followUps});

  static const milestones = [1, 3, 6, 12];

  final DateTime hiredAt;
  final List<EmploymentFollowUp> followUps;

  factory EmploymentPlan.propose(DateTime hiringDate) {
    final date = DateTime(hiringDate.year, hiringDate.month, hiringDate.day);
    return EmploymentPlan(
      hiredAt: date,
      followUps: [
        for (final months in milestones)
          EmploymentFollowUp(
            monthsAfterHiring: months,
            scheduledAt: _addMonths(date, months),
          ),
      ],
    );
  }

  /// Clamp month-end anniversaries to the last day of the target month.
  static DateTime _addMonths(DateTime date, int months) {
    final lastDay = DateTime(date.year, date.month + months + 1, 0).day;
    return DateTime(
      date.year,
      date.month + months,
      date.day > lastDay ? lastDay : date.day,
      15,
    );
  }

  bool get isValid =>
      followUps.length == milestones.length &&
      followUps
          .map((meeting) => meeting.monthsAfterHiring)
          .toSet()
          .containsAll(milestones) &&
      followUps.every((meeting) => !meeting.scheduledAt.isBefore(hiredAt));

  List<EmploymentFollowUp> remindersAt(DateTime now) {
    final cutoff = DateTime(now.year, now.month, now.day + 8);
    return followUps
        .where(
          (meeting) =>
              !meeting.completed && meeting.scheduledAt.isBefore(cutoff),
        )
        .toList(growable: false);
  }
}
