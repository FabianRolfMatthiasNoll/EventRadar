import 'package:event_radar/core/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/password_form_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<StatefulWidget> createState() {
    return _RegisterScreenState();
  }
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _password1Controller = TextEditingController();
  final _password2Controller = TextEditingController();

  bool _isLoading = false;

  void _submitRegister() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      final status = await AuthService().register(
        _emailController.text,
        _password1Controller.text,
        _nameController.text,
      );
      String? message;
      switch (status) {
        case RegisterStatus.success:
          message = null;
          break;
        case RegisterStatus.weakPassword:
          message =
              'Das Passwort ist zu schwach, das Passwort muss mind. 6 Zeichen lang sein.';
          break;
        case RegisterStatus.emailAlreadyUsed:
          message = 'Es gibt bereits einen Account mit dieser Email.';
          break;
        case RegisterStatus.invalidEmail:
          message = 'Die Email ist nicht korrekt.';
          break;
        case RegisterStatus.noInternet:
          message = 'Verbindung fehlgeschlagen';
          break;
        case RegisterStatus.unknownError:
          message = 'Registrierung fehlgeschlagen';
          break;
      }

      setState(() {
        _isLoading = false;
      });
      if (!mounted) return;
      if (message == null) {
        context.go('/profile-settings');
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  void _gotoLogin(BuildContext context) {
    context.go('/login');
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Bitte ein Passwort eingeben';
    }
    if (value.length < 6) {
      return 'Passwort ist mind. 6 Zeichen lang.';
    }
    String password1 = _password1Controller.text;
    String password2 = _password2Controller.text;
    if (password1 != password2) {
      return 'Passwörter stimmen nicht überein';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 16,
          children: [
            Text(
              'Registrierung',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            TextFormField(
              controller: _emailController,
              validator: AuthService().validateEmail,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
              ),
            ),
            TextFormField(
              controller: _nameController,
              validator: AuthService().validateNameField,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Name',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            PasswordFormField(
              controller: _password1Controller,
              validator: _validatePassword,
              textInputAction: TextInputAction.next,
              labelText: 'Passwort',
            ),
            PasswordFormField(
              controller: _password2Controller,
              validator: _validatePassword,
              textInputAction: TextInputAction.next,
              labelText: 'Passwort wiederholen',
            ),
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: _submitRegister,
                        child: Text('Registrieren'),
                      ),
                    ),
                  ],
                ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () => _gotoLogin(context),
                  child: Text('Einloggen'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
