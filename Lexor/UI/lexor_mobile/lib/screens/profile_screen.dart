import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lexor_mobile/helpers/image_decode.dart';
import 'package:lexor_mobile/helpers/snackbar_helper.dart';
import 'package:lexor_mobile/models/profile_response.dart';
import 'package:lexor_mobile/providers/auth_provider.dart';
import 'package:lexor_mobile/providers/profile_provider.dart';
import 'package:lexor_mobile/screens/change_password_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lexor_mobile/screens/login_screen.dart';
import 'package:lexor_mobile/theme/app_colors.dart';
import 'package:lexor_mobile/widgets/error_view.dart';
import 'package:provider/provider.dart';
import 'package:lexor_mobile/providers/attendance_provider.dart';
import 'package:lexor_mobile/providers/leave_provider.dart';
import 'package:lexor_mobile/providers/notification_provider.dart';
import 'package:lexor_mobile/providers/salary_slip_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final DateFormat _dateFormat = DateFormat('dd.MM.yyyy');

  bool _editing = false;
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _picker = ImagePicker();
  String? _editImageBase64;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProfileProvider>(context, listen: false).fetchProfile();
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _enterEdit(ProfileResponse p) {
    _usernameController.text = p.user.username ?? p.user.email;
    _emailController.text = p.user.email;
    _phoneController.text = p.user.phoneNumber ?? '';
    _addressController.text = p.address;
    _editImageBase64 = p.user.profileImageBase64;
    setState(() => _editing = true);
  }

  Future<void> _pickProfileImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 400,
      imageQuality: 80,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() => _editImageBase64 = base64Encode(bytes));
  }

  Future<void> _save() async {
    final phone = _phoneController.text.trim();
    if (phone.isNotEmpty &&
        !RegExp(r'^(\+387|0)\d{8,9}$').hasMatch(phone.replaceAll(' ', ''))) {
      SnackbarHelper.showError(
        context,
        'Unesite validan broj telefona (npr. 062 123 456 ili +387 62 123 456).',
      );
      return;
    }
    final email = _emailController.text.trim();
    if (email.isNotEmpty &&
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      SnackbarHelper.showError(context, 'Unesite ispravan email.');
      return;
    }
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      SnackbarHelper.showError(context, 'Korisničko ime ne može biti prazno.');
      return;
    }
    final provider = Provider.of<ProfileProvider>(context, listen: false);
    final ok = await provider.updateProfile(
      username: username,
      email: _emailController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      profileImageBase64: _editImageBase64,
    );
    if (!mounted) return;
    if (ok) {
      setState(() => _editing = false);
      SnackbarHelper.showSuccess(context, 'Profil je ažuriran.');
    } else {
      SnackbarHelper.showError(
        context,
        provider.error ?? 'Greška pri spremanju.',
      );
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Odjava'),
        content: const Text('Da li ste sigurni da se želite odjaviti?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Otkaži'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Odjavi se'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final navigator = Navigator.of(context);

    // Clear all user-scoped providers so the next login starts clean (no cross-user data).
    context.read<SalarySlipProvider>().reset();
    context.read<AttendanceProvider>().reset();
    context.read<LeaveProvider>().reset();
    context.read<NotificationProvider>().reset();
    context.read<ProfileProvider>().reset();

    await Provider.of<AuthProvider>(context, listen: false).logout();
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Moj profil'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Consumer<ProfileProvider>(
        builder: (context, provider, _) {
          final p = provider.profile;
          if (provider.isLoading && p == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null && p == null) {
            // Keep logout reachable even when the profile fails to load, so the user is
            // never stuck (e.g. a token issued before a role change → 403 until re-login).
            return Column(
              children: [
                Expanded(
                  child: ErrorView(
                    message: provider.error!,
                    onRetry: provider.fetchProfile,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _logoutButton(),
                ),
              ],
            );
          }
          if (p == null) return const SizedBox.shrink();

          return ScrollConfiguration(
            behavior: ScrollConfiguration.of(
              context,
            ).copyWith(overscroll: false),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _header(p),
                  const SizedBox(height: 20),
                  if (_editing) _editForm(provider) else _details(p),
                  const SizedBox(height: 12),
                  _changePasswordButton(),
                  const SizedBox(height: 12),
                  _logoutButton(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _header(ProfileResponse p) {
    final job = [
      p.position?.name,
      p.department?.name,
    ].where((e) => e != null && e.isNotEmpty).join(' • ');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _avatar(p),
          const SizedBox(height: 12),
          Text(
            p.fullName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (job.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(job, style: const TextStyle(color: Colors.white70)),
          ],
        ],
      ),
    );
  }

  Widget _avatar(ProfileResponse p) {
    final img = p.user.profileImageBase64;
    if (img != null && img.isNotEmpty) {
      try {
        return CircleAvatar(
          radius: 40,
          backgroundImage: MemoryImage(cachedImageBytes(img)),
        );
      } catch (_) {
        // Fall through to initials if the stored image can't be decoded.
      }
    }
    return CircleAvatar(
      radius: 40,
      backgroundColor: Colors.white24,
      child: Text(
        _initials(p.fullName),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _initials(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  Widget _details(ProfileResponse p) {
    final city = p.city == null
        ? '-'
        : [
            p.city!.name,
            p.city!.country?.name,
          ].where((e) => e != null && e.isNotEmpty).join(', ');
    final phone = (p.user.phoneNumber?.isNotEmpty ?? false)
        ? p.user.phoneNumber!
        : '-';
    return Column(
      children: [
        _card('Lični podaci', [
          _row(Icons.badge_outlined, 'Korisničko ime', p.user.username ?? '-'),
          _row(Icons.email_outlined, 'Email', p.user.email),
          _row(Icons.phone_outlined, 'Telefon', phone),
          _row(
            Icons.cake_outlined,
            'Datum rođenja',
            _dateFormat.format(p.dateOfBirth),
          ),
          _row(
            Icons.home_outlined,
            'Adresa',
            p.address.isNotEmpty ? p.address : '-',
          ),
          _row(Icons.location_city_outlined, 'Grad', city),
        ]),
        const SizedBox(height: 16),
        _card('Posao', [
          _row(Icons.apartment_outlined, 'Odjel', p.department?.name ?? '-'),
          _row(Icons.work_outline, 'Pozicija', p.position?.name ?? '-'),
          _row(
            Icons.event_outlined,
            'Datum zaposlenja',
            _dateFormat.format(p.hireDate),
          ),
        ]),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _enterEdit(p),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Uredi profil'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _editForm(ProfileProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Uredi profil',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          Center(child: _editAvatar()),
          const SizedBox(height: 20),
          _field('Korisničko ime', _usernameController),
          const SizedBox(height: 12),
          _field(
            'Email',
            _emailController,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          _field(
            'Telefon',
            _phoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
            ],
            hintText: 'npr. 062 123 456',
          ),
          const SizedBox(height: 12),
          _field('Adresa', _addressController),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: provider.isSaving
                      ? null
                      : () => setState(() => _editing = false),
                  child: const Text('Otkaži'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: provider.isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: provider.isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Sačuvaj'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _editAvatar() {
    final img = _editImageBase64;
    ImageProvider? bg;
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
          radius: 44,
          backgroundColor: Colors.grey.shade200,
          backgroundImage: bg,
          child: bg == null
              ? Icon(Icons.person, size: 44, color: Colors.grey.shade500)
              : null,
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _pickProfileImage,
          icon: const Icon(Icons.photo_camera_outlined, size: 18),
          label: Text(img == null ? 'Dodaj sliku' : 'Promijeni sliku'),
        ),
      ],
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? hintText,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
        hintText: hintText,
      ),
      inputFormatters: inputFormatters,
    );
  }

  Widget _card(String title, List<Widget> rows) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          ...rows,
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.neutralFg),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _changePasswordButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
        ),
        icon: const Icon(Icons.lock_outline),
        label: const Text('Promijeni lozinku'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _logoutButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _logout,
        icon: const Icon(Icons.logout),
        label: const Text('Odjava'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: const BorderSide(color: AppColors.error),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}
