import 'dart:convert';

import '../entities/recruiting_data.dart';

/// Serializes proposed meetings using RFC 5545 floating local times.
class BuildFollowUpCalendar {
  const BuildFollowUpCalendar();

  String call({
    required Candidate person,
    required DateTime generatedAt,
    required String Function(int months) milestoneLabel,
  }) {
    final lines = <String>[
      'BEGIN:VCALENDAR',
      'VERSION:2.0',
      'PRODID:-//People//Employment Follow-ups//EN',
      'CALSCALE:GREGORIAN',
    ];
    for (final meeting in person.employmentPlan?.followUps ?? []) {
      if (meeting.completed) continue;
      final summary =
          '${milestoneLabel(meeting.monthsAfterHiring)} - ${person.fullName}';
      lines.addAll([
        'BEGIN:VEVENT',
        'UID:${_text(person.id)}-${meeting.monthsAfterHiring}@people.local',
        'DTSTAMP:${_dateTime(generatedAt.toUtc())}Z',
        'DTSTART:${_dateTime(meeting.scheduledAt)}',
        'DURATION:PT1H',
        'SUMMARY:${_text(summary)}',
        'STATUS:TENTATIVE',
        for (final trigger in ['-P1D', '-PT15M']) ...[
          'BEGIN:VALARM',
          'ACTION:DISPLAY',
          'TRIGGER:$trigger',
          'DESCRIPTION:${_text(summary)}',
          'END:VALARM',
        ],
        'END:VEVENT',
      ]);
    }
    lines.add('END:VCALENDAR');
    return '${lines.map(_fold).join('\r\n')}\r\n';
  }

  static String _dateTime(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}'
      '${_two(date.month)}${_two(date.day)}T'
      '${_two(date.hour)}${_two(date.minute)}${_two(date.second)}';

  static String _two(int value) => value.toString().padLeft(2, '0');

  static String _text(String value) => value
      .replaceAll('\\', '\\\\')
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .replaceAll('\n', r'\n')
      .replaceAll(';', r'\;')
      .replaceAll(',', r'\,');

  static String _fold(String line) {
    final output = StringBuffer();
    var octets = 0;
    for (final rune in line.runes) {
      final character = String.fromCharCode(rune);
      final length = utf8.encode(character).length;
      if (octets + length > 75) {
        output.write('\r\n ');
        octets = 1;
      }
      output.write(character);
      octets += length;
    }
    return output.toString();
  }
}
