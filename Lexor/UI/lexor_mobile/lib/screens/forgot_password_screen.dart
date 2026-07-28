import 'package:flutter/material.dart';
import 'package:lexor_mobile/api_client.dart';
import 'package:lexor_mobile/theme/app_colors.dart';
import 'package:lexor_shared/lexor_shared.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscure = true;
  bool _isLoading = false;
  bool _codeSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _snack(String message, {bool error = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.error : AppColors.success,
      ),
    );
  }

  Future<void> _sendCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty ||
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      _snack('Unesite ispravan email.');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await ApiClient.post('/Access/forgot-password', body: {'email': email});
      if (!mounted) return;
      setState(() => _codeSent = true);
      _snack('Ako nalog postoji, poslali smo kod na email.', error: false);
    } catch (e) {
      if (mounted) _snack(messageFor(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final code = _codeController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (code.isEmpty || password.isEmpty) {
      _snack('Popunite sva polja.');
      return;
    }
    if (password.length < 6) {
      _snack('Lozinka mora imati najmanje 6 znakova.');
      return;
    }
    if (password != confirm) {
      _snack('Lozinke se ne poklapaju.');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await ApiClient.post(
        '/Access/reset-password',
        body: {
          'email': _emailController.text.trim(),
          'code': code,
          'newPassword': password,
        },
      );
      if (!mounted) return;
      _snack(
        'Lozinka je promijenjena. Prijavite se novom lozinkom.',
        error: false,
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) _snack(messageFor(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const inputDecoration = InputDecoration(
      filled: true,
      fillColor: AppColors.neutralBg,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Zaboravljena lozinka'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(32, 32, 32, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _codeSent
                      ? 'Unesite kod i novu lozinku'
                      : 'Resetujte lozinku',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _codeSent
                      ? 'Kod smo poslali na vaš email. Vrijedi 30 minuta.'
                      : 'Unesite email i poslat ćemo vam kod za resetovanje.',
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 28),
                _label('Email'),
                TextField(
                  controller: _emailController,
                  enabled: !_codeSent,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: inputDecoration.copyWith(
                    hintText: 'vas@email.com',
                  ),
                ),
                if (_codeSent) ...[
                  const SizedBox(height: 18),
                  _label('Kod'),
                  TextField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    decoration: inputDecoration.copyWith(
                      hintText: 'Kod iz emaila',
                    ),
                  ),
                  const SizedBox(height: 18),
                  _label('Nova lozinka'),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscure,
                    textInputAction: TextInputAction.next,
                    decoration: inputDecoration.copyWith(
                      hintText: 'Najmanje 6 znakova',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: Colors.grey,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _label('Potvrdite lozinku'),
                  TextField(
                    controller: _confirmController,
                    obscureText: _obscure,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _resetPassword(),
                    decoration: inputDecoration.copyWith(
                      hintText: 'Ponovite lozinku',
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : (_codeSent ? _resetPassword : _sendCode),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
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
                        : Text(
                            _codeSent ? 'Resetuj lozinku' : 'Pošalji kod',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                if (_codeSent) ...[
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: _isLoading ? null : _sendCode,
                      child: const Text('Pošalji kod ponovo'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    ),
  );
}
