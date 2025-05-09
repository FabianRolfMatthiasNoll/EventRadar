import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/auth_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() {
    return _ResetPasswordScreenState();
  }
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final email = _emailController.text.trim();
      final status = await AuthService().resetPassword(email);

      String message;
      switch (status) {
        case PasswordResetStatus.success:
          message = 'Ein Link zum Zurücksetzen des Passworts wurde gesendet.';
          break;
        case PasswordResetStatus.userNotFound:
          message = 'Kein Benutzer mit dieser E-Mail-Adresse gefunden.';
          break;
        case PasswordResetStatus.invalidEmail:
          message = 'Bitte eine gültige E-Mail-Adresse eingeben.';
          break;
        case PasswordResetStatus.noInternet:
          message = 'Keine Internetverbindung. Bitte erneut versuchen.';
          break;
        default:
          message = 'Ein unbekannter Fehler ist aufgetreten.';
      }
      if (mounted) {
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text('Passwort zurücksetzen'),
                content: Text(message),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('OK'),
                  ),
                ],
              ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Passwort zurücksetzen')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Passwort zurücksetzen',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
                validator: AuthService().validateEmail,
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: _submit,
                      child: Text('Passwort zurücksetzen'),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => context.pop(),
                    child: Text('zurück'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
