import 'package:event_radar/core/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'password_form_field.dart';

class ReauthenticatorDialog extends StatefulWidget {
  final User? user;
  final String titleText;
  final String contentText;

  const ReauthenticatorDialog({
    super.key,
    required this.user,
    this.titleText = "Sicherheitshinweis",
    this.contentText =
        "Diese Operation ist eine sicherheitsrelevante Aktion. Bitte geben Sie Ihr Passwort ein, um fortzufahren.",
  });

  @override
  State<ReauthenticatorDialog> createState() => _ReauthenticatorDialogState();
}

class _ReauthenticatorDialogState extends State<ReauthenticatorDialog> {
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _reauthenticate() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = AuthService().currentUser();
      if (user == null) {
        setState(() {
          _errorMessage = 'Kein Benutzer angemeldet.';
        });
        return;
      }

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _passwordController.text,
      );
      await user.reauthenticateWithCredential(credential);

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        switch (e.code) {
          case 'wrong-password':
            _errorMessage = 'Falsches Passwort. Bitte erneut versuchen.';
            break;
          case 'too-many-requests':
            _errorMessage = 'Zu viele Versuche. Bitte warten Sie einen Moment.';
            break;
          default:
            _errorMessage = 'Fehler: ${e.message}';
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Ein unerwarteter Fehler ist aufgetreten.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.titleText),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.contentText),
          const SizedBox(height: 16),
          PasswordFormField(
            controller: _passwordController,
            validator: AuthService().validatePasswordField,
            textInputAction: TextInputAction.next,
            labelText: 'Passwort',
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Abbrechen'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _reauthenticate,
          child:
              _isLoading
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Text('Bestätigen'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }
}
