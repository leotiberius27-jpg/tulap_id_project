import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../app/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/domain/entities/auth_user_entity.dart';
import '../../../auth/domain/usecases/update_user_profile.dart';

/// EditProfilePage
/// ----------------------------------------------------------------------
/// Formulir pembaruan identitas pengguna: foto profil (kamera / galeri),
/// nama lengkap, nomor telepon, dan NIP.
/// ----------------------------------------------------------------------
class EditProfilePage extends StatefulWidget {
  final AuthUserEntity user;

  const EditProfilePage({super.key, required this.user});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _instansiController;
  late final TextEditingController _nipController;

  String? _photoPath;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _photoPath = widget.user.photoUrl;
    _nameController = TextEditingController(text: widget.user.fullName);
    _emailController = TextEditingController(text: widget.user.email);
    _phoneController = TextEditingController(text: widget.user.phoneNumber ?? '');
    _instansiController = TextEditingController(
      text: widget.user.instansiName ?? 'BPKAD Kabupaten Mimika',
    );
    _nipController = TextEditingController(text: widget.user.nip ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _instansiController.dispose();
    _nipController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (picked != null && mounted) {
        setState(() {
          _photoPath = picked.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih foto: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  void _showPhotoOptionsModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.bottomSheetTop)),
      ),
      backgroundColor: AppColors.surface,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Foto Profil',
                style: AppTypography.sectionTitle.copyWith(fontSize: 16),
              ),
              const SizedBox(height: AppSpacing.md),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AppColors.iconSoftBlue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
                ),
                title: const Text('Ambil Foto dengan Kamera'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AppColors.iconSoftIndigo,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library_outlined, color: AppColors.action),
                ),
                title: const Text('Pilih dari Galeri'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (_photoPath != null)
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete_outline, color: AppColors.danger),
                  ),
                  title: const Text(
                    'Hapus Foto Profil',
                    style: TextStyle(color: AppColors.danger),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    setState(() => _photoPath = null);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final updateUserProfile = sl<UpdateUserProfile>();
    final result = await updateUserProfile(
      fullName: _nameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      instansiName: _instansiController.text.trim(),
      nip: _nipController.text.trim(),
      photoUrl: _photoPath,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    result.fold(
      (failure) {
        setState(() => _errorMessage = failure.message);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: ${failure.message}'),
            backgroundColor: AppColors.danger,
          ),
        );
      },
      (updatedUser) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil berhasil diperbarui.'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop(true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit Profil'),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.base),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. AVATAR PREVIEW
                Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _showPhotoOptionsModal,
                        child: Stack(
                          children: [
                            UserAvatar(
                              fullName: _nameController.text.isNotEmpty
                                  ? _nameController.text
                                  : widget.user.fullName,
                              photoUrl: _photoPath,
                              size: 96,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: const [
                                BoxShadow(
                                  color: AppColors.shadowSoft,
                                  blurRadius: 16,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2.5),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: AppColors.shadowSoft,
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextButton.icon(
                        onPressed: _showPhotoOptionsModal,
                        icon: const Icon(Icons.photo_camera_outlined, size: 16, color: AppColors.primary),
                        label: Text(
                          _photoPath != null ? 'Ubah Foto Profil' : 'Tambah Foto Profil',
                          style: AppTypography.small.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.dangerSoft,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: AppTypography.small.copyWith(color: AppColors.danger),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                // 2. FORM FIELDS
                Container(
                  padding: const EdgeInsets.all(AppSpacing.base),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.cardLarge),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.shadowSoft,
                        blurRadius: 16,
                        offset: Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel('Nama Lengkap', isRequired: true),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _nameController,
                        decoration: _inputDecoration(
                          hint: 'Masukkan nama lengkap',
                          icon: Icons.person_outline,
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Nama lengkap wajib diisi';
                          }
                          return null;
                        },
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      _buildFieldLabel('Email (ID Login Terdaftar)'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _emailController,
                        readOnly: true,
                        decoration: _inputDecoration(
                          hint: 'Email pegawai',
                          icon: Icons.email_outlined,
                          isReadOnly: true,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(
                          'Email terikat dengan otentikasi identitas akun dan bersifat tetap.',
                          style: AppTypography.small.copyWith(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      _buildFieldLabel('Instansi / Organisasi'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _instansiController,
                        decoration: _inputDecoration(
                          hint: 'Contoh: BPKAD Kabupaten Mimika',
                          icon: Icons.apartment_outlined,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      _buildFieldLabel('NIP / Nomor Identitas Pegawai'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _nipController,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration(
                          hint: 'Contoh: 198503152010011002',
                          icon: Icons.badge_outlined,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      _buildFieldLabel('Nomor Telepon'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: _inputDecoration(
                          hint: 'Contoh: 081234567890',
                          icon: Icons.phone_outlined,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // 3. SUBMIT BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.button),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Simpan Perubahan',
                            style: AppTypography.body.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: AppSpacing.base),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label, {bool isRequired = false}) {
    return RichText(
      text: TextSpan(
        text: label,
        style: AppTypography.body.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        children: isRequired
            ? const [
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold),
                ),
              ]
            : null,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    bool isReadOnly = false,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTypography.body.copyWith(color: AppColors.textSecondary.withValues(alpha: 0.6)),
      prefixIcon: Icon(icon, size: 20, color: isReadOnly ? AppColors.textSecondary.withValues(alpha: 0.5) : AppColors.primary),
      filled: true,
      fillColor: isReadOnly ? AppColors.background : AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
        borderSide: BorderSide(
          color: isReadOnly ? AppColors.border : AppColors.border,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }
}
