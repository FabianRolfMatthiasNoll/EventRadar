import 'package:event_radar/core/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  Future<void> showChangeEmailDialog(BuildContext context) async {
    final emailController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('E-Mail ändern'),
        content: TextField(
          controller: emailController,
          decoration: const InputDecoration(
            labelText: 'Neue E-Mail',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseAuth.instance.currentUser
                    ?.verifyBeforeUpdateEmail(emailController.text.trim());
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('E-Mail erfolgreich geändert.')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Fehler: ${e.toString()}')),
                );
              }
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }

  Future<void> showChangePasswordDialog(BuildContext context) async {
    final passwordController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Passwort ändern'),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Neues Passwort',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseAuth.instance.currentUser
                    ?.updatePassword(passwordController.text.trim());
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Passwort erfolgreich geändert.')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Fehler: ${e.toString()}')),
                );
              }
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }

  Future<void> showDeleteAccountDialog(BuildContext context) async {
    final confirmationController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Account löschen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Geben Sie "Bestätigen" ein, um Ihren Account dauerhaft zu löschen.',
            ),
            TextField(
              controller: confirmationController,
              decoration: const InputDecoration(
                labelText: 'Bestätigen',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (confirmationController.text.trim().toLowerCase() ==
                  'bestätigen') {
                try {
                  await FirebaseAuth.instance.currentUser?.delete();
                  Navigator.of(context).pop();
                  context.go('/login');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Account wurde erfolgreich gelöscht.')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Fehler: ${e.toString()}')),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Bestätigung fehlgeschlagen.')),
                );
              }
            },
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        InkWell(
          onTap: () {},
          child: Container(
            padding: const EdgeInsets.all(16),
            child: AvatarWithName(
              title: name ?? '<kein Name>',
              isEditable: true,
            ),
          ),
        ),
        ListTile(
          onTap: () => showChangeEmailDialog(context),
          leading: const Icon(Icons.mail),
          title: Text(email ?? '<keine Email>'),
        ),
        ListTile(
          onTap: () => showChangePasswordDialog(context),
          leading: const Icon(Icons.lock),
          title: const Text('Passwort ändern'),
        ),
        ListTile(
          onTap: () => signOut(context),
          leading: const Icon(Icons.logout),
          title: const Text('Abmelden'),
        ),
        ListTile(
          textColor: Theme.of(context).colorScheme.error,
          iconColor: Theme.of(context).colorScheme.error,
          onTap: () => showDeleteAccountDialog(context),
          leading: const Icon(Icons.delete),
          title: const Text('Account löschen'),
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
