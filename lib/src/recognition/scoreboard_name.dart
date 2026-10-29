/// OCR sometimes mixes Latin text with visually identical Greek/Cyrillic
/// capitals. Canonicalize names only; never run delivery or score text through
/// this function, and never substitute digits for letters.
String normalizedBowlerName(String text) {
  const lookalikes = {
    'А': 'A',
    'В': 'B',
    'Е': 'E',
    'К': 'K',
    'М': 'M',
    'Н': 'H',
    'О': 'O',
    'Р': 'P',
    'С': 'C',
    'Т': 'T',
    'Х': 'X',
    'Α': 'A',
    'Β': 'B',
    'Ε': 'E',
    'Η': 'H',
    'Ι': 'I',
    'Κ': 'K',
    'Μ': 'M',
    'Ν': 'N',
    'Ο': 'O',
    'Ρ': 'P',
    'Τ': 'T',
    'Υ': 'Y',
    'Χ': 'X',
  };
  return text
      .toUpperCase()
      .split('')
      .map((c) => lookalikes[c] ?? c)
      .join()
      .replaceAll(RegExp(r'[^A-Z0-9]'), '');
}

/// Keep multi-letter names (including F/X) separate from scoring metadata.
bool isBowlerNameCandidate(String text) {
  final normalized = normalizedBowlerName(text);
  if (!RegExp(r'[A-Z]{2,}').hasMatch(normalized)) return false;
  return !RegExp(r'^(FR\d*|TOT|TOTAL|PLAYER|MPH)$').hasMatch(normalized);
}
