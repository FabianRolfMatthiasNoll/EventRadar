String getImagePlaceholder(String name) {
  final words = name.split(' ').take(2);
  String initials = '';
  for (var word in words) {
    if (word.isNotEmpty) {
      initials += word[0].toUpperCase();
    }
  }
  return initials;
}