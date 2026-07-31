import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lexor_desktop/helpers/image_decode.dart';
import 'package:lexor_desktop/providers/account_provider.dart';
import 'package:lexor_desktop/theme/app_colors.dart';
import 'package:provider/provider.dart';

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  String? _imageBase64;
  bool _loaded = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final provider = Provider.of<AccountProvider>(context, listen: false);
    await provider.fetch();
    final a = provider.account;
    if (a != null && mounted) {
      _username.text = a.username;
      _email.text = a.email;
      _phone.text = a.phoneNumber ?? '';
      _imageBase64 = a.profileImageBase64;
    }
    if (mounted) setState(() => _loaded = true);
  }

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.pickFiles(type: FileType.image, withData: true);
    final bytes = result?.files.single.bytes;
    if (bytes != null) setState(() => _imageBase64 = base64Encode(bytes));
  }

  Future<void> _save() async {
    final username = _username.text.trim();
    if (username.isEmpty) {
      setState(() => _error = 'Korisničko ime ne može biti prazno.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final provider = Provider.of<AccountProvider>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    final err = await provider.update(
      username: username,
      email: _email.text.trim(),
      phoneNumber: _phone.text.trim(),
      profileImageBase64: _imageBase64,
    );
    if (!mounted) return;
    setState(() {
      _saving = false;
      _error = err;
    });
    if (err == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Profil je ažuriran.'),
          backgroundColor: AppColors.successBright,
        ),
      );
    }
  }

  Future<void> _changePassword() async {
    final provider = Provider.of<AccountProvider>(context, listen: false);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _ChangePasswordDialog(provider: provider),
    );
    if (ok == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lozinka je promijenjena.'),
          backgroundColor: AppColors.successBright,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Center(child: CircularProgressIndicator());
    }
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Moj profil',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Center(child: _avatar()),
                  const SizedBox(height: 24),
                  _field('Korisničko ime', _username),
                  const SizedBox(height: 16),
                  _field('Email', _email),
                  const SizedBox(height: 16),
                  _field('Telefon', _phone, hint: 'npr. 062 123 456'),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Sačuvaj izmjene'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _changePassword,
                    icon: const Icon(Icons.lock_outline),
                    label: const Text('Promijeni lozinku'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _avatar() {
    ImageProvider? bg;
    final img = _imageBase64;
    if (img != null && img.isNotEmpty) {
      try {
        bg = MemoryImage(cachedImageBytes(img));
      } catch (_) {
        bg = null;
      }
    }
    return Column(
      children: [
        CircleAvatar(
          radius: 46,
          backgroundColor: Colors.grey.shade200,
          backgroundImage: bg,
          child: bg == null
              ? Icon(Icons.person, size: 46, color: Colors.grey.shade500)
              : null,
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _pickImage,
          icon: const Icon(Icons.photo_camera_outlined, size: 18),
          label: Text(img == null ? 'Dodaj sliku' : 'Promijeni sliku'),
        ),
      ],
    );
  }

  Widget _field(String label, TextEditingController controller, {String? hint}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class _ChangePasswordDialog extends StatefulWidget {
  final AccountProvider provider;
  const _ChangePasswordDialog({required this.provider});

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _old = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _old.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_old.text.isEmpty || _new.text.isEmpty) {
      setState(() => _error = 'Popunite sva polja.');
      return;
    }
    if (_new.text.length < 6) {
      setState(() => _error = 'Nova lozinka mora imati najmanje 6 znakova.');
      return;
    }
    if (_new.text != _confirm.text) {
      setState(() => _error = 'Nova lozinka i potvrda se ne poklapaju.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final err = await widget.provider.changePassword(
      oldPassword: _old.text,
      newPassword: _new.text,
      confirmNewPassword: _confirm.text,
    );
    if (!mounted) return;
    if (err == null) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _saving = false;
        _error = err;
      });
    }
  }

  Widget _passwordField(
    String label,
    TextEditingController controller,
    bool obscure,
    VoidCallback onToggle,
  ) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Promjena lozinke'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _passwordField('Trenutna lozinka', _old, _obscureOld,
                () => setState(() => _obscureOld = !_obscureOld)),
            const SizedBox(height: 14),
            _passwordField('Nova lozinka', _new, _obscureNew,
                () => setState(() => _obscureNew = !_obscureNew)),
            const SizedBox(height: 14),
            _passwordField('Potvrdi novu lozinku', _confirm, _obscureConfirm,
                () => setState(() => _obscureConfirm = !_obscureConfirm)),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Odustani'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: _saving
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Sačuvaj'),
        ),
      ],
    );
  }
}
