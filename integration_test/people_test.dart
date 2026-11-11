import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'suites/candidate_workflows.dart';
import 'suites/resume_ocr.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Keep one entrypoint so Windows does not relaunch the app between suites.
  // Groups isolate candidate fixtures from the native OCR tests.
  group('Candidate workflows', registerCandidateWorkflowTests);
  group('Resume OCR', registerResumeOcrTests);
}
