import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../app/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/auth_user_entity.dart';
import '../../domain/usecases/self_register.dart';
import '../controllers/register_controller.dart';

/// RegisterPage (Daftar)
/// ----------------------------------------------------------------------
/// Pendaftaran mandiri pegawai baru - SELALU membuat akun ber-role
/// PEGAWAI, langsung aktif & login otomatis begitu berhasil (Bagian
/// "Daftar" di layar Login).
/// ----------------------------------------------------------------------
class RegisterPage extends StatelessWidget {
  final ValueChanged<AuthUserEntity> onRegisterSuccess;

  const RegisterPage({super.key, required this.onRegisterSuccess});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<RegisterController>(
      create: (_) => RegisterController(selfRegister: sl<SelfRegister>()),
      child: _RegisterView(onRegisterSuccess: onRegisterSuccess),
    );
  }
}

class _RegisterView extends StatefulWidget {
  final ValueChanged<AuthUserEntity> onRegisterSuccess;

  const _RegisterView({required this.onRegisterSuccess});

  @override
  State<_RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<_RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _instansiController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _instansiController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit(RegisterController controller) async {
    if (!_formKey.currentState!.validate()) return;

    final success = await controller.submit(
      fullName: _fullNameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      instansiName: _instansiController.text.trim(),
      phoneNumber: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
    );

    if (!mounted || !success) return;

    final user = controller.state.user;
    if (user != null) widget.onRegisterSuccess(user);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Daftar Akun'),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
      ),
      body: Consumer<RegisterController>(
        builder: (context, controller, _) {
          final state = controller.state;
          final isBusy = state.status == RegisterStatus.submitting;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Buat akun pegawai baru untuk mulai memakai Tulap.id.',
                    style: AppTypography.bodySecondary.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextFormField(
                    controller: _fullNameController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Nama Lengkap',
                      prefixIcon: Icon(Icons.person_outline, size: 20),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Nama wajib diisi.' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.mail_outline, size: 20),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Email wajib diisi.' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _instansiController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Nama Instansi',
                      prefixIcon: Icon(Icons.apartment_outlined, size: 20),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Instansi wajib diisi.' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Nomor HP (opsional)',
                      prefixIcon: Icon(Icons.phone_outlined, size: 20),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Kata Sandi',
                      prefixIcon: const Icon(Icons.lock_outline, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (v) => (v == null || v.length < 8)
                        ? 'Kata sandi minimal 8 karakter.'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'Ulangi Kata Sandi',
                      prefixIcon: Icon(Icons.lock_outline, size: 20),
                    ),
                    validator: (v) => v != _passwordController.text
                        ? 'Kata sandi tidak sama.'
                        : null,
                    onFieldSubmitted: (_) => _submit(controller),
                  ),
                  if (state.status == RegisterStatus.error) ...[
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.dangerSoft,
                        borderRadius: BorderRadius.circular(AppRadius.small),
                      ),
                      child: Text(
                        state.errorMessage ?? 'Registrasi gagal.',
                        style: AppTypography.small.copyWith(color: AppColors.danger),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  ElevatedButton(
                    onPressed: isBusy ? null : () => _submit(controller),
                    child: isBusy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Daftar'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
