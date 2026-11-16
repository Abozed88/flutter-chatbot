class Gemini {
  static String get key {
    const apiKey = String.fromEnvironment('GEMINI_API_KEY');
    if (apiKey.isEmpty) {
      throw StateError(
        'GEMINI_API_KEY is not configured. '
        'Run Flutter with --dart-define=GEMINI_API_KEY=your-key.',
      );
    }
    return apiKey;
  }
}