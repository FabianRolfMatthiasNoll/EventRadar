import 'package:event_radar/core/services/auth_service.dart';
import 'package:event_radar/views/profile/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProfileSettingsScreen extends StatelessWidget {
  const ProfileSettingsScreen({
    super.key,
    required this.name,
    required this.email,
  });

  final String? name;
  final String? email;

  void signOut(BuildContext context) async {
    await AuthService().signOut();
    if (context.mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        InkWell(
          onTap: () {},
          child: Container(
            padding: EdgeInsets.all(16),
            child: AvatarWithName(
              title: name ?? '<kein Name>',
              isEditable: true,
            ),
          ),
        ),
        ListTile(
          onTap: () {},
          leading: const Icon(Icons.mail),
          title: Text(email ?? '<keine Email>'),
        ),
        ListTile(
          onTap: () {},
          leading: const Icon(Icons.lock),
          title: Text('Passwort ändern'),
        ),
        ListTile(
          onTap: () => signOut(context),
          leading: Icon(Icons.logout),
          title: Text('Abmelden'),
        ),
        ListTile(
          textColor: Theme.of(context).colorScheme.error,
          iconColor: Theme.of(context).colorScheme.error,
          onTap: () {},
          leading: Icon(Icons.delete),
          title: Text('Account löschen'),
        ),
      ],
    );
  }
}

class AvatarWithName extends StatelessWidget {
  final String title;
  final String imageUrl;
  final bool isEditable;

  const AvatarWithName({
    super.key,
    required this.title,
    this.imageUrl = '',
    this.isEditable = false,
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
    return Row(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundImage:
              (imageUrl.isNotEmpty && imageUrl.startsWith('http'))
                  ? NetworkImage(imageUrl)
                  : null,
          child:
              (imageUrl.isEmpty || !imageUrl.startsWith('http'))
                  ? Text(getImagePlaceholder(title))
                  : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.edit),
          tooltip: 'Change name',
          onPressed: () {},
        ),
      ],
    );
  }
}
