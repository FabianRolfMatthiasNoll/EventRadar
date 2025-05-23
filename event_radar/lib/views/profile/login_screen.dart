import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/auth_service.dart';
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

  bool _isLoading = false;

  void _submitLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      final status = await AuthService().signInWithEmailPassword(
        _emailController.text,
        _passwordController.text,
      );
      String? message;
      switch (status) {
        case SignInStatus.success:
          message = null;
          break;
        case SignInStatus.userNotFound:
          message = 'Dieser Benutzer existiert nicht.';
          break;
        case SignInStatus.wrongPassword:
          message = 'Falsches Passwort wurde eingegeben.';
          break;
        case SignInStatus.invalidEmail:
          message = 'Die Email ist nicht korrekt.';
          break;
        case SignInStatus.noInternet:
          message = 'Die Verbindung ist fehlgeschlagen.';
          break;
        case SignInStatus.unknownError:
          message = 'Die Anmeldung ist fehlgeschlagen.';
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

  void _gotoRegister(BuildContext context) {
    context.go('/login/register');
  }

  void _iForgor(BuildContext context) {
    context.go('/login/reset-password');
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
              'Anmeldung',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Email-Adresse',
                prefixIcon: Icon(Icons.person),
              ),
              validator: AuthService().validateEmail,
              textInputAction: TextInputAction.next,
            ),
            PasswordFormField(
              controller: _passwordController,
              validator: AuthService().validatePasswordField,
              textInputAction: TextInputAction.next,
            ),
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: _submitLogin,
                        child: Text('Anmelden'),
                      ),
                    ),
                  ],
                ),
            Row(
              children: [
                TextButton(
                  onPressed: () => _gotoRegister(context),
                  child: Text('Registrieren'),
                ),
                Expanded(child: SizedBox()),
                TextButton(
                  onPressed: () => _iForgor(context),
                  child: Text('Passwort vergessen'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
