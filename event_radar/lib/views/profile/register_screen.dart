import 'package:flutter/material.dart';

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

  void _submitRegister() {
    if (_formKey.currentState!.validate()) {
      // TODO register action here
    }
  }

  void _gotoLogin() {
    // TODO
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Bitte Email eingeben';
    }
    return null;
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Bitte Name eingeben';
    }
    // TODO check for uniqueness
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Bitte Passwort eingeben';
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
            TextFormField(
              controller: _emailController,
              validator: _validateEmail,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
              ),
            ),
            TextFormField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              validator: _validateName,
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
            ),
            PasswordFormField(
              controller: _password2Controller,
              validator: _validatePassword,
              textInputAction: TextInputAction.next,
            ),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                      onPressed: _submitRegister,
                      child: Text('Registrieren')
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: _gotoLogin,
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