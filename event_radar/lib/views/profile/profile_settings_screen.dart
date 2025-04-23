import 'package:event_radar/core/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/password_form_field.dart';

class ProfileSettingsScreen extends StatelessWidget {
  const ProfileSettingsScreen({
    super.key,
    required this.name,
    required this.email,
  });

  final String? name;
  final String? email;

  void signOut(BuildContext context) async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Abmelden'),
          content: const Text('Möchten Sie sich wirklich abmelden?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // Cancel
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true), // Submit
              style: ElevatedButton.styleFrom(
                foregroundColor:
                    Theme.of(context).colorScheme.error, // Red Sign Out
              ),
              child: const Text('Abmelden'),
            ),
          ],
        );
      },
    );

    if (shouldSignOut == true) {
      await AuthService().signOut();
      if (context.mounted) {
        context.go('/login');
      }
    }
  }

  Future<void> showChangePasswordDialog(BuildContext context) async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isCurrentPasswordVerified = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                isCurrentPasswordVerified
                    ? 'Neues Passwort festlegen'
                    : 'Passwort ändern',
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children:
                    isCurrentPasswordVerified
                        ? [
                          PasswordFormField(
                            controller: newPasswordController,
                            labelText: 'Neues Passwort',
                          ),
                          const SizedBox(height: 10),
                          PasswordFormField(
                            controller: confirmPasswordController,
                            labelText: 'Neues Passwort bestätigen',
                          ),
                        ]
                        : [
                          PasswordFormField(
                            controller: currentPasswordController,
                            labelText: 'Aktuelles Passwort',
                          ),
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: () {
                              AuthService().signOut();
                              context.go('/login/reset-password');
                              Navigator.of(context).pop();
                            },
                            child: const Text('Passwort vergessen'),
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
                    if (!isCurrentPasswordVerified) {
                      final currentPassword =
                          currentPasswordController.text.trim();
                      try {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user == null)
                          throw Exception('Kein Benutzer angemeldet.');

                        final credentials = EmailAuthProvider.credential(
                          email: user.email ?? '',
                          password: currentPassword,
                        );
                        await user.reauthenticateWithCredential(credentials);
                        setState(() => isCurrentPasswordVerified = true);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Fehler: ${e.toString()}')),
                        );
                      }
                    } else {
                      final newPassword = newPasswordController.text.trim();
                      final confirmPassword =
                          confirmPasswordController.text.trim();

                      if (newPassword != confirmPassword) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Die neuen Passwörter stimmen nicht überein.',
                            ),
                          ),
                        );
                        return;
                      }

                      try {
                        final user = FirebaseAuth.instance.currentUser;
                        await user?.updatePassword(newPassword);
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Passwort erfolgreich geändert.'),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Fehler: ${e.toString()}')),
                        );
                      }
                    }
                  },
                  child: Text(
                    isCurrentPasswordVerified ? 'Speichern' : 'Weiter',
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> showEditEmailDialog(BuildContext context) async {
    final emailController = TextEditingController(text: email);
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('E-Mail ändern'),
          content: TextField(
            controller: emailController,
            decoration: const InputDecoration(
              labelText: 'Neue E-Mail',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newEmail = emailController.text.trim();
                try {
                  final user = FirebaseAuth.instance.currentUser;
                  await user?.verifyBeforeUpdateEmail(newEmail);
                  //await user?.updateEmail(newEmail);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('E-Mail erfolgreich geändert.'),
                    ),
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
        );
      },
    );
  }

  Future<void> showDeleteAccountDialog(BuildContext context) async {
    final confirmationController = TextEditingController();
    bool isConfirmed = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Account löschen'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Geben Sie "Bestätigen" ein, um Ihren Account dauerhaft zu löschen.',
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: confirmationController,
                    decoration: InputDecoration(
                      labelText: 'Bestätigen',
                      labelStyle: TextStyle(
                        color:
                            isConfirmed
                                ? Colors.green
                                : Theme.of(context).colorScheme.error,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color:
                              isConfirmed
                                  ? Colors.green
                                  : Theme.of(context).colorScheme.error,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color:
                              isConfirmed
                                  ? Colors.green
                                  : Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                    autocorrect:
                        false, // disable autocorrect to avoid underline
                    enableSuggestions:
                        false, // disable enableSuggestions to avoid underline
                    onChanged: (value) {
                      setState(() {
                        isConfirmed = value.trim() == 'Bestätigen';
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Abbrechen'),
                ),
                ElevatedButton(
                  onPressed:
                      isConfirmed
                          ? () async {
                            try {
                              await FirebaseAuth.instance.currentUser?.delete();
                              Navigator.of(context).pop();
                              context.go('/login');
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Account wurde erfolgreich gelöscht.',
                                  ),
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Fehler: ${e.toString()}'),
                                ),
                              );
                            }
                          }
                          : null,
                  child: const Text('Löschen'),
                ),
              ],
            );
          },
        );
      },
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
              onNameChanged: (newName) {},
              isEditable: true,
            ),
          ),
        ),
        ListTile(
          onTap: () => showEditEmailDialog(context),
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
  final ValueChanged<String> onNameChanged; // Callback für Namensänderungen

  const AvatarWithName({
    super.key,
    required this.title,
    this.imageUrl = '',
    this.isEditable = false,
    required this.onNameChanged, // Callback als Pflichtparameter
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

  Future<void> showEditNameDialog(BuildContext context) async {
    final nameController = TextEditingController(text: title);
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Name ändern'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Neuer Name',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = nameController.text.trim();
                if (newName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Name darf nicht leer sein.')),
                  );
                  return;
                }

                try {
                  final user = FirebaseAuth.instance.currentUser;
                  await user?.updateDisplayName(newName);

                  // Callback auslösen, um den neuen Namen mitzuteilen
                  onNameChanged(newName);

                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Name erfolgreich geändert.')),
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
        );
      },
    );
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
        if (isEditable)
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Change name',
            onPressed: () => showEditNameDialog(context),
          ),
      ],
    );
  }
}
