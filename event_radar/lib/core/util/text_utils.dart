String cleanString(String s) {
  s.trim();
  bool foundMatch = true;
  while (foundMatch) {
    foundMatch = false;
    s = s.replaceFirstMapped(RegExp(r'\n\s*\n\s*\n'), (match) {
      foundMatch = true;
      return '\n\n';
    });
  }
  return s;
}
