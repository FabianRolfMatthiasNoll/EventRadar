import 'package:flutter/material.dart';

class PasswordFormField extends StatefulWidget {
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final String? labelText;

  const PasswordFormField({
    super.key,
    this.controller,
    this.validator,
    this.textInputAction,
    this.labelText = 'Passwort',
  });

  @override
  State<StatefulWidget> createState() {
    return _PasswordFormFieldState();
  }
}

class _PasswordFormFieldState extends State<PasswordFormField> {
  var _obscurePassword = true;

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      validator: widget.validator,
      textInputAction: widget.textInputAction,
      obscureText: _obscurePassword,
      onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
      decoration: InputDecoration(
        border: OutlineInputBorder(),
        labelText: widget.labelText,
        prefixIcon: Icon(Icons.lock),
        suffixIcon: IconButton(
          icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility
          ),
          onPressed: _togglePasswordVisibility,
        ),
      ),
    );
  }
}
