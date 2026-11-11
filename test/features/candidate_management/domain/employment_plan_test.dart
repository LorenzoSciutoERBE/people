import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:people/features/candidate_management/data/models/recruiting_data_model.dart';
import 'package:people/features/candidate_management/domain/entities/employment_plan.dart';
import 'package:people/features/candidate_management/domain/entities/recruiting_data.dart';
import 'package:people/features/candidate_management/domain/usecases/build_follow_up_calendar.dart';

void main() {
  test(
    'proposes calendar anniversaries with month-end and leap-year clamping',
    () {
      final plan = EmploymentPlan.propose(DateTime(2027, 1, 31));
      expect(plan.followUps.map((meeting) => meeting.scheduledAt), [
        DateTime(2027, 2, 28, 15),
        DateTime(2027, 4, 30, 15),
        DateTime(2027, 7, 31, 15),
        DateTime(2028, 1, 31, 15),
      ]);
      expect(
        EmploymentPlan.propose(DateTime(2028, 2, 29))
            .followUps
            .last
            .scheduledAt,
        DateTime(2029, 2, 28, 15),
      );
      expect(plan.isValid, isTrue);
    },
  );

  test('reminders include overdue meetings and the next seven days only', () {
    final plan = EmploymentPlan(
      hiredAt: DateTime(2026),
      followUps: [
        EmploymentFollowUp(
          monthsAfterHiring: 1,
          scheduledAt: DateTime(2026, 2),
        ),
        EmploymentFollowUp(
          monthsAfterHiring: 3,
          scheduledAt: DateTime(2026, 4, 7, 15),
        ),
        EmploymentFollowUp(
          monthsAfterHiring: 6,
          scheduledAt: DateTime(2026, 4, 9, 15),
        ),
        EmploymentFollowUp(
          monthsAfterHiring: 12,
          scheduledAt: DateTime(2026, 4),
          completed: true,
        ),
      ],
    );
    expect(
      plan
          .remindersAt(DateTime(2026, 4))
          .map((meeting) => meeting.monthsAfterHiring),
      [1, 3],
    );
    expect(
      EmploymentPlan(hiredAt: DateTime(2026), followUps: const []).isValid,
      isFalse,
    );
  });

  test(
    'exports stable event IDs, escaped text, folded UTF-8 lines and reminders',
    () {
      final proposed = EmploymentPlan.propose(DateTime(2026, 1, 31));
      final person = Candidate(
        id: 'employee-1',
        firstName: List.filled(50, 'É').join(),
        lastName: 'Test, Name;\nOther',
        stageId: 'hired',
        sourceId: 'other',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
        employmentPlan: EmploymentPlan(
          hiredAt: proposed.hiredAt,
          followUps: [
            proposed.followUps.first.copyWith(completed: true),
            ...proposed.followUps.skip(1),
          ],
        ),
      );
      String build(DateTime now) => const BuildFollowUpCalendar()(
        person: person,
        generatedAt: now,
        milestoneLabel: (months) => '$months-month review',
      );
      final calendar = build(DateTime.utc(2026));
      expect('BEGIN:VEVENT'.allMatches(calendar), hasLength(3));
      expect('BEGIN:VALARM'.allMatches(calendar), hasLength(6));
      expect(calendar, contains('UID:employee-1-3@people.local'));
      expect(
        build(DateTime.utc(2027)),
        contains('UID:employee-1-3@people.local'),
      );
      final unfolded = calendar.replaceAll('\r\n ', '');
      expect(unfolded, contains(r'Test\, Name\;\nOther'));
      expect(unfolded, contains('DTSTART:20260430T150000'));
      expect('DURATION:PT1H'.allMatches(calendar), hasLength(3));
      expect(calendar, contains('DTSTAMP:20260101T000000Z'));
      for (final line in calendar.split('\r\n')) {
        expect(utf8.encode(line).length, lessThanOrEqualTo(75));
      }
    },
  );

  test(
    'reads older vaults and rejects malformed review and schedule records',
    () {
      final initial = RecruitingData.initial();
      final person = Candidate(
        id: 'c1',
        firstName: 'Ada',
        lastName: 'Lovelace',
        stageId: 'hired',
        sourceId: 'other',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
      final json = RecruitingDataModel.encode(
        initial.copyWith(candidates: [person]),
      );
      final candidates = json['candidates']! as List<Object?>;
      final candidate = candidates.single! as Map<String, Object?>;
      candidate.remove('reviews');
      candidate.remove('employmentPlan');
      final decoded = RecruitingDataModel.decode(json).candidates.single;
      expect(decoded.reviews, isEmpty);
      expect(decoded.employmentPlan, isNull);
      candidate['reviews'] = [
        {'id': 'invalid'},
      ];
      expect(() => RecruitingDataModel.decode(json), throwsFormatException);
      candidate['reviews'] = <Object?>[];
      candidate['employmentPlan'] = {
        'hiredAt': '2026-01-01',
        'followUps': <Object?>[],
      };
      expect(() => RecruitingDataModel.decode(json), throwsFormatException);
    },
  );
}
