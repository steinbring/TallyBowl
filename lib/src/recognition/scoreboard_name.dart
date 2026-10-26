/// Keep multi-letter names (including F/X) separate from scoring metadata.
bool isBowlerNameCandidate(String text) {
  if (!RegExp(r'[A-Z]{2,}', caseSensitive: false).hasMatch(text)) return false;
  final normalized = text.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  return !RegExp(r'^(FR\d*|TOT|TOTAL|PLAYER|MPH)$').hasMatch(normalized);
}
