abstract interface class ResumeTextExtractor {
  Future<String> extractText(List<int> bytes, String fileName);
}
