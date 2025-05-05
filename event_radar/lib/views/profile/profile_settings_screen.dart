import 'dart:async';

import 'package:event_radar/core/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/shared_preferences_service.dart';
import '../../widgets/avatar_with_name.dart';
import '../../widgets/password_form_field.dart';
import '../../widgets/reauthenticator_dialog.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  String? name;
  String? email;
  String? imageUrl;
  String? pendingEmail;

  @override
  void initState() {
    super.initState();
    final user = AuthService().currentUser();
    name = user?.displayName;
    email = user?.email;
    imageUrl = user?.photoURL;
    loadEmailFromDevice();
  }

  Future<void> loadEmailFromDevice() async {
    var pendingEmailFromStorage = await SharedPreferencesService.getEmail();
    if (pendingEmailFromStorage?.toLowerCase() != email?.toLowerCase()) {
      setState(() {
        pendingEmail = pendingEmailFromStorage;
      });
    } else {
      SharedPreferencesService.clearEmail();
    }
  }

  Future<void> updateEmail(newEmail) async {
    await SharedPreferencesService.saveEmail(newEmail);
    setState(() {
      pendingEmail = newEmail;
    });
  }

  Future<void> refreshUser() async {
    try {
      final currentPendingEmail = pendingEmail;
      await AuthService().currentUser()?.reload();
      if (currentPendingEmail != null && currentPendingEmail.isNotEmpty) {
        final updatedUser = AuthService().currentUser();
        if (updatedUser?.email?.toLowerCase() ==
            currentPendingEmail.toLowerCase()) {
          await SharedPreferencesService.clearEmail();
          setState(() {
            email = currentPendingEmail;
            pendingEmail = null;
          });
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Die Seite wurde aktualisiert')),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        final success = await showDialog(
          context: context,
          builder:
              (context) => ReauthenticatorDialog(
                user: AuthService().currentUser(),
                titleText: 'Ihre Sitzung ist abgelaufen',
                contentText:
                    'Bitte authentifizieren Sie sich erneut, um fortzufahren.',
              ),
        );
        if (success) {
          final currentPendingEmail = pendingEmail;
          await AuthService().currentUser()?.reload();
          if (currentPendingEmail != null && currentPendingEmail.isNotEmpty) {
            final updatedUser = AuthService().currentUser();
            if (updatedUser?.email?.toLowerCase() ==
                currentPendingEmail.toLowerCase()) {
              await SharedPreferencesService.clearEmail();
              setState(() {
                email = currentPendingEmail;
                pendingEmail = null;
              });
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Die Seite wurde aktualisiert')),
                );
              }
            }
          }
        }
      }
    }
  }

  Future<void> showEditEmailDialog(BuildContext context) async {
    final emailController = TextEditingController();
    bool inputWasInvalid = false;
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('E-Mail ändern'),
              content: TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Neue E-Mail-Adresse',
                  labelStyle: TextStyle(
                    color:
                        inputWasInvalid
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color:
                          inputWasInvalid
                              ? Theme.of(context).colorScheme.error
                              : Theme.of(context).dividerColor,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color:
                          inputWasInvalid
                              ? Theme.of(context).colorScheme.error
                              : Theme.of(context).colorScheme.primary,
                    ),
                  ),
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
                    if (!(await AuthService().validateEmail(newEmail))) {
                      setState(() {
                        inputWasInvalid = true;
                      });
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Bitte geben Sie eine gültige E-Mail-Adresse ein.',
                            ),
                          ),
                        );
                      }
                      return;
                    }
                    try {
                      await AuthService().changeUserEmail(newEmail);
                      updateEmail(newEmail);
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Ein Verifizierungslink wurde an die E-Mail-Adresse $newEmail gesendet. Bitte bestätigen Sie diese und laden Sie danach die Seite neu.',
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      if (e is FirebaseAuthException &&
                          e.code == 'requires-recent-login') {
                        final success = await showDialog(
                          context: context,
                          builder:
                              (context) => ReauthenticatorDialog(
                                user: AuthService().currentUser(),
                              ),
                        );
                        if (success) {
                          await AuthService().changeUserEmail(newEmail);
                          updateEmail(newEmail);
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Ein Verifizierungslink wurde an die E-Mail-Adresse $newEmail gesendet. Bitte bestätigen Sie diese und laden Sie danach die Seite neu.',
                                ),
                              ),
                            );
                          }
                        }
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Fehler: ${e.toString()}')),
                          );
                        }
                      }
                    }
                  },
                  child: const Text('Speichern'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  //ChangePasswordDialogWindow
  Future<void> showChangePasswordDialog(BuildContext context) async {
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Neues Passwort festlegen'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PasswordFormField(
                    controller: newPasswordController,
                    labelText: "Neues Passwort",
                    validator: AuthService().validatePasswordField,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 10),
                  PasswordFormField(
                    controller: confirmPasswordController,
                    labelText: "Neues Passwort bestätigen",
                    validator: AuthService().validatePasswordField,
                    textInputAction: TextInputAction.done,
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
                      await AuthService().changePassword(newPassword);
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Passwort erfolgreich geändert.'),
                          ),
                        );
                      }
                    } catch (e) {
                      if (e is FirebaseAuthException &&
                          e.code == 'requires-recent-login') {
                        final success = await showDialog(
                          context: context,
                          builder:
                              (context) => ReauthenticatorDialog(
                                user: AuthService().currentUser(),
                              ),
                        );
                        if (success) {
                          await AuthService().changePassword(newPassword);
                          if (context.mounted) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Passwort erfolgreich geändert.'),
                              ),
                            );
                          }
                        }
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Fehler: ${e.toString()}')),
                          );
                        }
                      }
                    }
                  },
                  child: const Text('Speichern'),
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
                              if (e is FirebaseAuthException &&
                                  e.code == 'requires-recent-login') {
                                final success = await showDialog(
                                  context: context,
                                  builder:
                                      (context) => ReauthenticatorDialog(
                                        user: AuthService().currentUser(),
                                      ),
                                );
                                if (success) {
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
                                }
                              } else {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Fehler: ${e.toString()}'),
                                    ),
                                  );
                                }
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
    return Column(
      children: [
        SizedBox(height: 26),
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
        Expanded(
          child: RefreshIndicator(
            onRefresh: refreshUser,
            child: ListView(
              children: [
                ListTile(
                  onTap: () => showEditEmailDialog(context),
                  leading: const Icon(Icons.mail),
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        email ?? '<keine Email>',
                        style: const TextStyle(fontSize: 16),
                      ),
                      if (pendingEmail != null && pendingEmail!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(
                            top: 4.0,
                          ), // Abstand zur Haupt-Email
                          child: Text(
                            'Ausstehend: Bestätigung von',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      if (pendingEmail != null && pendingEmail!.isNotEmpty)
                        Text(
                          pendingEmail!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),

                ListTile(
                  onTap: () => showChangePasswordDialog(context),
                  leading: const Icon(Icons.lock),
                  title: Text('Passwort ändern'),
                ),
                ListTile(
                  onTap: () => signOut(context),
                  leading: const Icon(Icons.logout),
                  title: Text('Abmelden'),
                ),
                ListTile(
                  textColor: Theme.of(context).colorScheme.error,
                  iconColor: Theme.of(context).colorScheme.error,
                  onTap: () => showDeleteAccountDialog(context),
                  leading: const Icon(Icons.delete),
                  title: Text('Account löschen'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
