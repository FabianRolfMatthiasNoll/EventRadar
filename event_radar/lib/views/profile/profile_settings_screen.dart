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
  String? uid;
  String? oldEmail;
  String? newEmail;
  bool? isPending = false;
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final user = AuthService().currentUser();
    name = user?.displayName;
    email = user?.email;
    imageUrl = user?.photoURL;
    uid = user?.uid;
    loadEmailFromDevice();
  }

  String? validateBothPasswords(String? value) {
    if (value == null || value.isEmpty) {
      return 'Bitte ein Passwort eingeben';
    }
    if (value.length < 6) {
      return 'Passwort ist mind. 6 Zeichen lang.';
    }
    if (newPasswordController.text.trim() !=
        confirmPasswordController.text.trim()) {
      return 'Passwörter stimmen nicht überein';
    }
    return null;
  }

  Future<void> onDeleteUser() async {
    if (uid != null && email != null) {
      await SharedPreferencesService.clearOldEmail(uid!);
      await SharedPreferencesService.clearNewEmail(uid!);
      await SharedPreferencesService.clearEmailPending(uid!);
    }
  }

  Future<void> loadEmailFromDevice() async {
    if (uid != null && email != null) {
      newEmail = await SharedPreferencesService.getNewEmail(uid!);
      oldEmail = await SharedPreferencesService.getOldEmail(uid!);
      isPending = await SharedPreferencesService.isEmailPending(uid!);
      if ((newEmail?.toLowerCase() != email?.toLowerCase()) && isPending!) {
        setState(() {
          pendingEmail = newEmail;
        });
      }
    }
  }

  Future<void> onUpdateEmail(newEmail) async {
    if (uid != null && email != null) {
      setState(() {
        oldEmail = email!;
        this.newEmail = newEmail;
        pendingEmail = newEmail;
        isPending = true;
      });
      await SharedPreferencesService.setEmailPending(uid!, true);
      await SharedPreferencesService.saveOldEmail(
        userId: uid!,
        oldEmail: email!,
      );
      await SharedPreferencesService.saveNewEmail(
        userId: uid!,
        newEmail: newEmail,
      );
    }
  }

  Future<void> refreshUser() async {
    try {
      await AuthService().currentUser()?.reload();
      final updatedUser = AuthService().currentUser();
      if (isPending!) {
        if (updatedUser?.email?.toLowerCase() == pendingEmail?.toLowerCase()) {
          setState(() {
            email = pendingEmail;
            pendingEmail = null;
            isPending = false;
          });
          await SharedPreferencesService.setEmailPending(uid!, false);
        }
      } else {
        if (updatedUser?.email?.toLowerCase() == oldEmail?.toLowerCase()) {
          await SharedPreferencesService.clearNewEmail(uid!);
          setState(() {
            email = oldEmail;
            newEmail = null;
          });
        }
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Die Seite wurde aktualisiert.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        final success = await showDialog(
          context: context,
          builder:
              (context) => ReauthenticatorDialog(
                email: isPending! ? newEmail : oldEmail,
                titleText: 'Ihre Sitzung ist abgelaufen.',
                contentText:
                    'Bitte authentifizieren Sie sich erneut, um fortzufahren.',
              ),
        );
        if (success) {
          await AuthService().currentUser()?.reload();
          final updatedUser = AuthService().currentUser();

          if (isPending!) {
            final updatedUser = AuthService().currentUser();

            if (updatedUser?.email?.toLowerCase() == newEmail?.toLowerCase()) {
              await SharedPreferencesService.setEmailPending(uid!, false);
              setState(() {
                email = pendingEmail;
                pendingEmail = null;
                isPending = false;
              });
            }
          } else {
            if (updatedUser?.email?.toLowerCase() == oldEmail?.toLowerCase()) {
              await SharedPreferencesService.clearNewEmail(uid!);
              setState(() {
                email = oldEmail;
                newEmail = null;
              });
            }
          }
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Die Seite wurde aktualisiert.')),
            );
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Falsches Passwort wurde eingegeben.')),
            );
          }
        }
      }
    }
  }

  Future<void> showEditEmailDialog(BuildContext context) async {
    final emailController = TextEditingController();
    bool sentEmail = false;
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final formKey = GlobalKey<FormState>();
            return AlertDialog(
              title: const Text('E-Mail ändern'),
              content: Form(
                key: formKey,
                child: TextFormField(
                  controller: emailController,
                  validator: AuthService().validateEmail,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Neue E-Mail-Adresse',
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
                    if (formKey.currentState?.validate() ?? false) {
                      final newEmail = emailController.text.trim();
                      try {
                        sentEmail = await AuthService().changeUserEmail(
                          newEmail,
                        );
                        if (sentEmail) {
                          onUpdateEmail(newEmail);
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Ein Verifizierungslink wurde an die E-Mail-Adresse: $newEmail gesendet. Bitte bestätigen und die Seite neu aktualisieren.',
                                ),
                              ),
                            );
                          }
                          sentEmail = false;
                        }
                      } catch (e) {
                        if (e is FirebaseAuthException &&
                            e.code == 'requires-recent-login') {
                          if (context.mounted) {
                            final success = await showDialog(
                              context: context,
                              builder:
                                  (context) =>
                                      ReauthenticatorDialog(email: email),
                            );
                            if (success) {
                              sentEmail = await AuthService().changeUserEmail(
                                newEmail,
                              );
                              if (sentEmail) {
                                onUpdateEmail(newEmail);
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                }
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Ein Verifizierungslink wurde an die E-Mail-Adresse: $newEmail gesendet. Bitte bestätigen und die Seite neu aktualisieren.',
                                      ),
                                    ),
                                  );
                                }
                                sentEmail = false;
                              } else {
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                }
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Beim Senden eines Verifizierungslink ist ein Fehler aufgetreten, bitte versuchen Sie es später erneut.',
                                      ),
                                    ),
                                  );
                                }
                              }
                            }
                          }
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Ein unbekannter Fehler ist aufgetreten.',
                                ),
                              ),
                            );
                          }
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
    await showDialog(
      context: context,
      builder: (context) {
        final formKey = GlobalKey<FormState>();
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Neues Passwort festlegen'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PasswordFormField(
                      controller: newPasswordController,
                      labelText: "Neues Passwort",
                      validator: validateBothPasswords,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 10),
                    PasswordFormField(
                      controller: confirmPasswordController,
                      labelText: "Neues Passwort bestätigen",
                      validator: validateBothPasswords,
                      textInputAction: TextInputAction.done,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Abbrechen'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState?.validate() ?? false) {
                      try {
                        await AuthService().changePassword(
                          newPasswordController.text.trim(),
                        );
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
                          if (context.mounted) {
                            final success = await showDialog(
                              context: context,
                              builder:
                                  (context) =>
                                      ReauthenticatorDialog(email: email),
                            );
                            if (success) {
                              await AuthService().changePassword(
                                newPasswordController.text.trim(),
                              );
                              if (context.mounted) {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Passwort erfolgreich geändert.',
                                    ),
                                  ),
                                );
                              }
                            }
                          }
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Ein unbekannter Fehler ist aufgetreten.',
                                ),
                              ),
                            );
                          }
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
                              await AuthService().deleteUser();
                              onDeleteUser();
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
                                if (context.mounted) {
                                  final success = await showDialog(
                                    context: context,
                                    builder:
                                        (context) =>
                                            ReauthenticatorDialog(email: email),
                                  );
                                  if (success) {
                                    AuthService().deleteUser();
                                    SharedPreferencesService.clearNewEmail(
                                      uid!,
                                    );
                                    if (context.mounted) {
                                      Navigator.of(context).pop();
                                      context.go('/login');
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Account wurde erfolgreich gelöscht.',
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                }
                              } else {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Ein unbekannter Fehler ist aufgetreten.',
                                      ), //${e.toString()} falls logging
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
                      if (isPending!)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            'Ausstehend: Bestätigung von',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      if (isPending!)
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
