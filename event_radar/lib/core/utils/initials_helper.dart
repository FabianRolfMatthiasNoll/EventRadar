String getInitials(String title) {
  final words = title.split(' ');
  String initials = '';
  for (var word in words) {
    if (word.isNotEmpty) {
      initials += word[0].toUpperCase();
    }
  }
  return initials;
}
