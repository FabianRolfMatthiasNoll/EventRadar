import 'package:flutter/material.dart';

import '../../widgets/password_form_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<StatefulWidget> createState() {
   return _LoginScreenState();
  }
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void _submitLogin() {
    if (_formKey.currentState!.validate()) {
      // TODO login action here
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Bitte Email oder Name eingeben';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Bitte Passwort eingeben';
    }
    return null;
  }

  void _gotoRegister() {
    // TODO
  }

  void _iForgor() {
    // TODO
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
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Email / Name',
                prefixIcon: Icon(Icons.person),
              ),
              validator: _validateEmail,
              textInputAction: TextInputAction.next,
            ),
            PasswordFormField(
              controller: _passwordController,
              validator: _validatePassword,
              textInputAction: TextInputAction.next,
            ),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: _submitLogin,
                    child: Text('Log in')
                  ),
                ),
              ],
            ),
            Row(
              children: [
                TextButton(
                  onPressed: _gotoRegister,
                  child: Text('Registrieren'),
                ),
                Expanded(child: SizedBox()),
                TextButton(
                  onPressed: _iForgor,
                  child: Text('Passwort vergessen'),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
