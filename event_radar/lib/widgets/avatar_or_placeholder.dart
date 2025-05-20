import 'package:flutter/material.dart';

/// Creates a circle Avatar with the provided imageUrl or creates a placeholder
class AvatarOrPlaceholder extends StatelessWidget {
  final String imageUrl;
  final String name;
  final double? radius;

  const AvatarOrPlaceholder({
    super.key,
    required this.imageUrl,
    required this.name,
    this.radius,
  });

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

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundImage:
          imageUrl.startsWith('http') ? NetworkImage(imageUrl) : null,
      child:
          !imageUrl.startsWith('http') ? Text(getImagePlaceholder(name)) : null,
    );
  }
}
