import 'dart:async';
import 'dart:io';

import 'package:event_radar/core/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/image_picker.dart';
import '../../core/utils/image_placeholder.dart';
import '../../widgets/password_form_field.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  StreamSubscription<User?>? authSubscription;
  String? name;
  String? email;
  String? imageUrl;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    name = user?.displayName;
    email = user?.email;
    imageUrl = user?.photoURL;
  }

  bool validateEmail(email) {
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(email)) {
      return true;
    }
    return false;
  }

  //ChangeEmailDialogWindow
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
                if (!validateEmail(newEmail)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Bitte geben Sie eine gültige E-Mail-Adresse ein.',
                      ),
                    ),
                  );
                  return;
                }
                try {
                  AuthService().changeUserEmail(newEmail);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Ein Verifizierungslink wurde an $newEmail gesendet. Bitte bestätigen Sie Ihre E-Mail-Adresse.',
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Fehler: ${e.toString()}')),
                    );
                  }
                }
              },
              child: const Text('Speichern'),
            ),
          ],
        );
      },
    );
  }

  //ChangePasswordDialogWindow
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
                          const Text(
                            'Gib erst dein aktuelles Passwort ein, um ein neues Passwort festzulegen.',
                          ),
                          const SizedBox(height: 10),
                          PasswordFormField(
                            controller: currentPasswordController,
                            labelText: 'Aktuelles Passwort',
                          ),
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              AuthService().resetPassword(email!);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Ein Passwort-Wiederherrstellungslink wurde an $email gesendet.',
                                    ),
                                  ),
                                );
                              }
                            },
                            child: const Text('Passwort vergessen?'),
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
                      if (await AuthService().validatePassword(
                        currentPassword,
                      )) {
                        setState(() => isCurrentPasswordVerified = true);
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Das eingegebene Passwort ist invalide, versuchen Sie es erneut.',
                              ),
                            ),
                          );
                        }
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
                        if (context.mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Passwort erfolgreich geändert.'),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Fehler: ${e.toString()}')),
                          );
                        }
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

  //SignOutDialogWindow
  Future<void> signOut(BuildContext context) async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Abmelden'),
          content: const Text('Möchten Sie sich wirklich abmelden?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
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

  //DeleteAccountDialogWindow
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
                    autocorrect: false, // to avoid underline while writing
                    enableSuggestions:
                        false, // to avoid underline while writing
                    onChanged: (value) {
                      setState(() {
                        isConfirmed =
                            value.trim().toLowerCase() == 'bestätigen';
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
                              AuthService().deleteUser();
                              if (context.mounted) {
                                Navigator.of(context).pop();
                                context.go('/login');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Account wurde erfolgreich gelöscht.',
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Fehler: ${e.toString()}'),
                                  ),
                                );
                              }
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
          child: Container(
            padding: EdgeInsets.all(16),
            child: AvatarWithName(
              title: name ?? '<kein Name>',
              imageUrl: imageUrl,
              onNameChanged: (newName) {
                setState(() {
                  name = newName;
                });
              },
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
          onTap: () => showDeleteAccountDialog(context),
          leading: Icon(Icons.delete),
          title: Text('Account löschen'),
        ),
      ],
    );
  }
}

class AvatarWithName extends StatefulWidget {
  final String title;
  final String? imageUrl;
  final bool isEditable;
  final ValueChanged<String> onNameChanged;

  const AvatarWithName({
    super.key,
    required this.title,
    this.imageUrl,
    this.isEditable = false,
    required this.onNameChanged,
  });

  @override
  State<AvatarWithName> createState() => _AvatarWithNameState();
}

class _AvatarWithNameState extends State<AvatarWithName> {
  String currentImageUrl = '';

  @override
  void initState() {
    super.initState();
    currentImageUrl = widget.imageUrl ?? '';
  }

  //ChangeProfilePictureDialogWindow
  Future<void> updateProfilePicture(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Profilbild bearbeiten'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.image),
                label: const Text('Galerie'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: () async {
                  File? image = await pickAndCropImage();
                  if (image != null) {
                    try {
                      if (context.mounted) {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (BuildContext context) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          },
                        );
                      }
                      String newImageUrl = await AuthService()
                          .uploadAndUpdateProfileImage(image);
                      image = null;
                      setState(() {
                        currentImageUrl = newImageUrl;
                      });
                      if (context.mounted) {
                        Navigator.of(context, rootNavigator: true).pop();
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Profilbild erfolgreich geändert.'),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        image = null;
                        Navigator.of(context, rootNavigator: true).pop();
                        Navigator.of(context).pop();
                        image = File('');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Fehler: ${e.toString()}')),
                        );
                      }
                    }
                  }
                },
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Abbrechen'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                      minimumSize: const Size(48, 48),
                      shape: const CircleBorder(),
                    ),
                    onPressed: () async {
                      try {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (BuildContext context) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          },
                        );
                        AuthService().deleteProfileImage();
                        setState(() {
                          currentImageUrl = '';
                        });
                        if (context.mounted) {
                          Navigator.of(context, rootNavigator: true).pop();
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Profilbild erfolgreich gelöscht.'),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          Navigator.of(context, rootNavigator: true).pop();
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Fehler: ${e.toString()}')),
                          );
                        }
                      }
                    },
                    child: const Icon(
                      Icons.delete,
                    ), // Nur das Icon wird angezeigt
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  //ChangeNameDialogWindow
  Future<void> showEditNameDialog(BuildContext context) async {
    final nameController = TextEditingController(text: widget.title);
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
                if (newName.length > 15) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Name darf max. 15 Zeichen enthalten.'),
                    ),
                  );
                  return;
                }
                try {
                  AuthService().changeUsername(newName);
                  widget.onNameChanged(newName);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Name erfolgreich geändert.'),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Fehler: ${e.toString()}')),
                    );
                  }
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
        InkWell(
          onTap: () => updateProfilePicture(context),
          child: CircleAvatar(
            radius: 40,
            child: ClipOval(
              child:
                  currentImageUrl.isNotEmpty
                      ? Image.network(
                        currentImageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(child: CircularProgressIndicator());
                        },
                        errorBuilder:
                            (context, error, stackTrace) =>
                                const Center(child: Icon(Icons.error)),
                      )
                      : Text(getImagePlaceholder(widget.title)),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            widget.title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        if (widget.isEditable)
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Name ändern',
            onPressed: () => showEditNameDialog(context),
          ),
      ],
    );
  }
}
