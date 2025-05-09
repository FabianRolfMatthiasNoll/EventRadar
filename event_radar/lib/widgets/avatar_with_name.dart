import 'dart:async';
import 'dart:io';

import 'package:event_radar/core/services/auth_service.dart';
import 'package:flutter/material.dart';

import '../core/util/image_picker.dart';
import 'avatar_or_placeholder.dart';

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
                    child: const Icon(Icons.delete),
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
    final nameController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) {
        final formKey = GlobalKey<FormState>();
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Name ändern'),
              content: Form(
                key: formKey,
                child: TextFormField(
                  controller: nameController,
                  validator: AuthService().validateNameField,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Neuer Name',
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
                      final newName = nameController.text.trim();
                      try {
                        await AuthService().changeUsername(newName);
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
                      : Text(
                        AvatarOrPlaceholder(
                          name: widget.title,
                          imageUrl: '',
                        ).getImagePlaceholder(widget.title),
                      ),
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
