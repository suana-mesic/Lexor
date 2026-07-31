import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lexor_desktop/config/api_config.dart';
import 'package:lexor_desktop/theme/app_colors.dart';
import 'package:lexor_shared/lexor_shared.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _codeSent = false;
  bool _isLoading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _snack(String message, {bool error = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.error : AppColors.successBright,
      ),
    );
  }

  Future<void> _sendCode() async {
    final email = _email.text.trim();
    if (email.isEmpty || !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      _snack('Unesite ispravan email.');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/Access/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw ApiException(ApiError.fromResponse(res));
      }
      if (!mounted) return;
      setState(() => _codeSent = true);
      _snack('Ako nalog postoji, poslali smo kod na email.', error: false);
    } catch (e) {
      if (mounted) _snack(messageFor(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _reset() async {
    if (_code.text.trim().isEmpty || _password.text.isEmpty) {
      _snack('Popunite sva polja.');
      return;
    }
    if (_password.text.length < 6) {
      _snack('Lozinka mora imati najmanje 6 znakova.');
      return;
    }
    if (_password.text != _confirm.text) {
      _snack('Lozinke se ne poklapaju.');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/Access/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _email.text.trim(),
          'code': _code.text.trim(),
          'newPassword': _password.text,
        }),
      );
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw ApiException(ApiError.fromResponse(res));
      }
      if (!mounted) return;
      _snack('Lozinka je promijenjena. Prijavite se novom lozinkom.', error: false);
      Navigator.pop(context);
    } catch (e) {
      if (mounted) _snack(messageFor(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 420,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _codeSent ? 'Unesite kod i novu lozinku' : 'Zaboravljena lozinka',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  _codeSent
                      ? 'Kod smo poslali na vaš email. Vrijedi 30 minuta.'
                      : 'Unesite email i poslat ćemo vam kod za resetovanje.',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _email,
                  enabled: !_codeSent,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (_codeSent) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: _code,
                    decoration: const InputDecoration(
                      labelText: 'Kod iz emaila',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _password,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: 'Nova lozinka',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _confirm,
                    obscureText: _obscure,
                    decoration: const InputDecoration(
                      labelText: 'Potvrdite lozinku',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : (_codeSent ? _reset : _sendCode),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(_codeSent ? 'Resetuj lozinku' : 'Pošalji kod'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Nazad na prijavu'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
