import 'package:flutter_test/flutter_test.dart';
import 'package:people/features/candidate_management/domain/usecases/parse_resume_contact.dart';

void main() {
  const parse = ParseResumeContact();

  test('extracts name and email only, normalizing all-caps names', () {
    final contact = parse('''
CURRICULUM VITAE
MARTA CAMPOLATTANO
Via Roma 1, Milano
+39 338 885 2670
martacamp @ Live.it
Software Engineer
''');
    expect(contact.firstName, 'Marta');
    expect(contact.lastName, 'Campolattano');
    expect(contact.email, 'martacamp@live.it');
  });

  test('understands labelled names and ignores section headings', () {
    final contact = parse('Profilo Personale\nNome: Luca De-Rossi\nlu@ca.dev');
    expect(contact.firstName, 'Luca');
    expect(contact.lastName, 'De-Rossi');
    expect(contact.email, 'lu@ca.dev');
  });

  test('returns empty values when nothing is recognized', () {
    final contact = parse('12345\nexperience 2020');
    expect(contact.firstName, isEmpty);
    expect(contact.lastName, isEmpty);
    expect(contact.email, isEmpty);
  });
}
