import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../../../app/di/injection_container.dart';
import '../../../../core/geo/reverse_geocoder.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_date_formatter.dart';
import '../../../auth/domain/usecases/get_current_session.dart';
import '../../../geotag_camera/domain/usecases/get_task_photo_previews.dart';
import '../../domain/usecases/create_activity.dart';
import '../../domain/usecases/get_task_detail.dart';
import '../../domain/usecases/start_task.dart';
import '../../domain/usecases/submit_task_for_verification.dart';
import '../../domain/usecases/toggle_checklist_item.dart';
import '../controllers/task_detail_controller.dart';
import 'task_detail_page.dart';

/// CreateActivityPage
/// ----------------------------------------------------------------------
/// Form pembuatan kegiatan lapangan mandiri (Mobile-first, Offline-first).
/// Memungkinkan petugas di lapangan membuat aktivitas tugas baru secara
/// langsung tanpa harus menunggu dibuatkan dari admin pusat.
/// ----------------------------------------------------------------------
class CreateActivityPage extends StatefulWidget {
  final String? travelId;
  final String? initialDestination;

  const CreateActivityPage({
    super.key,
    this.travelId,
    this.initialDestination,
  });

  @override
  State<CreateActivityPage> createState() => _CreateActivityPageState();
}

class _CreateActivityPageState extends State<CreateActivityPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  late final TextEditingController _locationController;
  final _descController = TextEditingController();
  final _budgetController = TextEditingController();
  final _newChecklistController = TextEditingController();

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  bool _isMultiDay = false;

  bool _isDetectingLocation = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _locationController = TextEditingController(text: widget.initialDestination ?? '');
  }

  final List<String> _checklistItems = [
    'Tiba di Lokasi & Verifikasi Koordinat',
    'Pemeriksaan / Observasi Fisik Lapangan',
    'Pengambilan Foto Dokumentasi Ber-watermark',
    'Pencatatan Pengeluaran & Scan Nota',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _descController.dispose();
    _budgetController.dispose();
    _newChecklistController.dispose();
    super.dispose();
  }

  bool get _hasUnsavedData =>
      _titleController.text.trim().isNotEmpty ||
      _locationController.text.trim().isNotEmpty ||
      _descController.text.trim().isNotEmpty ||
      _budgetController.text.trim().isNotEmpty;

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedData) return true;

    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.cardLarge),
        ),
        title: const Text(
          'Batalkan Pembuatan Kegiatan?',
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontWeight: FontWeight.w800,
            fontSize: 17,
            color: AppColors.textPrimary,
          ),
        ),
        content: const Text(
          'Data yang telah Anda isi akan hilang jika keluar dari halaman ini.',
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Tetap di Halaman',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
            ),
            child: const Text(
              'Keluar',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    return shouldLeave ?? false;
  }

  Future<void> _detectCurrentLocation() async {
    if (_isDetectingLocation) return;
    setState(() => _isDetectingLocation = true);
    HapticFeedback.lightImpact();

    try {
      Position? position;
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        final req = await Geolocator.requestPermission();
        if (req == LocationPermission.denied ||
            req == LocationPermission.deniedForever) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Izin akses lokasi tidak diizinkan.'),
                backgroundColor: AppColors.warning,
              ),
            );
          }
          return;
        }
      }

      position = await Geolocator.getLastKnownPosition();
      position ??= await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );

      final pos = position;
      if (pos != null) {
        final geocoder = sl<ReverseGeocoder>();
        final address = await geocoder.reverseGeocode(
          latitude: pos.latitude,
          longitude: pos.longitude,
        );
        if (mounted) {
          setState(() {
            _locationController.text = address ??
                '${pos.latitude.toStringAsFixed(6)}, ${pos.longitude.toStringAsFixed(6)}';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lokasi saat ini berhasil disematkan!'),
              backgroundColor: AppColors.success,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Tidak dapat memperoleh koordinat GPS. Silakan ketik manual.',
              ),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mendeteksi lokasi: $e'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDetectingLocation = false);
      }
    }
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
      locale: const Locale('id', 'ID'),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (!_isMultiDay || _endDate.isBefore(_startDate)) {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate.isBefore(_startDate) ? _startDate : _endDate,
      firstDate: _startDate,
      lastDate: DateTime(now.year + 2),
      locale: const Locale('id', 'ID'),
    );

    if (picked != null) {
      if (picked.isBefore(_startDate)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tanggal selesai tidak boleh sebelum tanggal mulai.'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
        return;
      }
      setState(() {
        _endDate = picked;
      });
    }
  }

  void _addChecklistItem() {
    final text = _newChecklistController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _checklistItems.add(text);
        _newChecklistController.clear();
      });
    }
  }

  void _removeChecklistItem(int index) {
    setState(() {
      _checklistItems.removeAt(index);
    });
  }

  void _formatBudgetInput(String value) {
    final cleanDigits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanDigits.isEmpty) {
      return;
    }
    final number = int.tryParse(cleanDigits) ?? 0;
    final formatted = AppDateFormatter.formatRupiah(number);
    _budgetController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  Future<void> _submitActivity() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon lengkapi semua kolom wajib di atas.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (_isMultiDay && _endDate.isBefore(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tanggal selesai tidak boleh sebelum tanggal mulai.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    if (_isSubmitting) return;

    if (_checklistItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Minimal sertakan 1 butir checklist untuk kegiatan ini.',
          ),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();

    try {
      final user = await sl<GetCurrentSession>()();
      final budget =
          double.tryParse(
            _budgetController.text.replaceAll(RegExp(r'[^0-9]'), ''),
          ) ??
          0.0;

      final createActivity = sl<CreateActivity>();
      final result = await createActivity(
        taskName: _titleController.text.trim(),
        destination: _locationController.text.trim(),
        startDate: _startDate,
        endDate: _isMultiDay ? _endDate : _startDate,
        budgetAmount: budget,
        description: _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
        checklistLabels: _checklistItems,
        currentUser: user,
        travelId: widget.travelId,
      );

      if (!mounted) return;

      result.fold(
        (failure) {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(failure.message),
              backgroundColor: AppColors.danger,
            ),
          );
        },
        (createdTask) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kegiatan berhasil dibuat & dimulai!'),
              backgroundColor: AppColors.success,
              duration: Duration(seconds: 2),
            ),
          );

          // Navigasi LANGSUNG ke Activity Workspace (TaskDetailPage)
          final officerName = user?.fullName ?? 'Petugas Lapangan';
          final agencyName = user?.instansiName ?? 'BPKAD';

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => ChangeNotifierProvider<TaskDetailController>(
                create: (_) => TaskDetailController(
                  getTaskDetail: sl<GetTaskDetail>(),
                  toggleChecklistItem: sl<ToggleChecklistItem>(),
                  startTask: sl<StartTask>(),
                  submitForVerification: sl<SubmitTaskForVerification>(),
                  getTaskPhotoPreviews: sl<GetTaskPhotoPreviews>(),
                  taskId: createdTask.id,
                )..loadTask(),
                child: TaskDetailPage(
                  officerName: officerName,
                  agencyName: agencyName,
                ),
              ),
            ),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan kegiatan: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tulapColors;

    return PopScope(
      canPop: !_hasUnsavedData,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldLeave = await _onWillPop();
        if (shouldLeave && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            'Buat Kegiatan Lapangan',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: colors.textPrimary,
            ),
          ),
          backgroundColor: colors.surface,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_rounded,
              color: colors.textPrimary,
            ),
            onPressed: () async {
              final shouldLeave = await _onWillPop();
              if (shouldLeave && context.mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.base),
            children: [
              // Banner Informasi Offline-First
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: colors.iconSoftBlue,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(
                    color: colors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.cloud_sync_rounded,
                      color: colors.primary,
                      size: 24,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Kegiatan akan disimpan terlebih dahulu di perangkat dan disinkronkan ke cloud saat koneksi tersedia.',
                        style: AppTypography.small.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Bagian 1: Identitas & Informasi Kegiatan
              Text('INFORMASI KEGIATAN', style: AppTypography.sectionLabel),
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.base),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.cardLarge),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nama Kegiatan Lapangan *
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Kegiatan Lapangan *',
                        hintText: 'Contoh: Koordinasi Data BMD Distrik',
                        prefixIcon: Icon(Icons.assignment_outlined),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Nama kegiatan wajib diisi.'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Lokasi / Destinasi * + Tombol GPS
                    TextFormField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        labelText: 'Lokasi / Destinasi *',
                        hintText: 'Ketik lokasi atau gunakan GPS',
                        prefixIcon: const Icon(Icons.location_on_outlined),
                        suffixIcon: IconButton(
                          tooltip: 'Gunakan Lokasi Saya',
                          icon: _isDetectingLocation
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primary,
                                  ),
                                )
                              : const Icon(
                                  Icons.my_location_rounded,
                                  color: AppColors.primary,
                                ),
                          onPressed: _isDetectingLocation
                              ? null
                              : _detectCurrentLocation,
                        ),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Lokasi wajib diisi.'
                          : null,
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: _isDetectingLocation
                            ? null
                            : _detectCurrentLocation,
                        icon: _isDetectingLocation
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.8,
                                  color: AppColors.primary,
                                ),
                              )
                            : const Icon(Icons.my_location_rounded, size: 15),
                        label: Text(
                          _isDetectingLocation
                              ? 'Mendeteksi lokasi...'
                              : 'Gunakan Lokasi Saya',
                          style: const TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          foregroundColor: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // Tanggal Kegiatan & Toggle Multi-hari
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Lebih dari 1 hari',
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Switch.adaptive(
                          value: _isMultiDay,
                          activeColor: AppColors.primary,
                          onChanged: (val) {
                            setState(() {
                              _isMultiDay = val;
                              if (!_isMultiDay) {
                                _endDate = _startDate;
                              }
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (!_isMultiDay) ...[
                      // Single Day Date Picker
                      InkWell(
                        onTap: _pickStartDate,
                        borderRadius: BorderRadius.circular(AppRadius.button),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Tanggal Kegiatan *',
                            prefixIcon: Icon(Icons.calendar_today_rounded),
                            suffixIcon: Icon(Icons.arrow_drop_down_rounded),
                          ),
                          child: Text(
                            AppDateFormatter.formatFull(_startDate),
                            style: const TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      // Multi-Day Date Pickers (Mulai & Selesai)
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: _pickStartDate,
                              borderRadius: BorderRadius.circular(
                                AppRadius.button,
                              ),
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Tanggal Mulai *',
                                  prefixIcon: Icon(
                                    Icons.calendar_today_rounded,
                                    size: 20,
                                  ),
                                ),
                                child: Text(
                                  AppDateFormatter.formatCompact(_startDate),
                                  style: const TextStyle(
                                    fontFamily: AppTypography.fontFamily,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: InkWell(
                              onTap: _pickEndDate,
                              borderRadius: BorderRadius.circular(
                                AppRadius.button,
                              ),
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Tanggal Selesai *',
                                  prefixIcon: Icon(
                                    Icons.event_available_rounded,
                                    size: 20,
                                  ),
                                ),
                                child: Text(
                                  AppDateFormatter.formatCompact(_endDate),
                                  style: const TextStyle(
                                    fontFamily: AppTypography.fontFamily,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),

                    // Waktu Mulai & Selesai (Otomatis)
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.schedule_rounded,
                                size: 16,
                                color: AppColors.textSecondary,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Pencatatan Waktu Otomatis',
                                style: TextStyle(
                                  fontFamily: AppTypography.fontFamily,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 6),
                          Text(
                            '• Jam Mulai: Dicatat otomatis saat tombol Simpan & Mulai ditekan\n• Jam Selesai: Dicatat otomatis saat kegiatan diselesaikan di Workspace',
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 11.5,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Deskripsi / Catatan (Opsional)
                    TextFormField(
                      controller: _descController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Deskripsi / Catatan (Opsional)',
                        hintText: 'Tujuan spesifik atau instruksi tambahan...',
                        prefixIcon: Icon(Icons.notes_rounded),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Estimasi Anggaran Operasional
                    TextFormField(
                      controller: _budgetController,
                      keyboardType: TextInputType.number,
                      onChanged: _formatBudgetInput,
                      decoration: const InputDecoration(
                        labelText: 'Estimasi Anggaran Operasional (Opsional)',
                        hintText: 'Contoh: Rp250.000',
                        prefixIcon: Icon(Icons.payments_outlined),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Bagian 2: Checklist Lapangan
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('CHECKLIST LAPANGAN', style: AppTypography.sectionLabel),
                  Text(
                    '${_checklistItems.length} butir',
                    style: AppTypography.small.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.base),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.cardLarge),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _checklistItems.length,
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          if (newIndex > oldIndex) newIndex -= 1;
                          final item = _checklistItems.removeAt(oldIndex);
                          _checklistItems.insert(newIndex, item);
                        });
                      },
                      itemBuilder: (context, index) {
                        final item = _checklistItems[index];
                        return Material(
                          key: ValueKey(item + index.toString()),
                          color: Colors.transparent,
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(
                              Icons.check_circle_outline_rounded,
                              color: AppColors.primary,
                            ),
                            title: Text(
                              item,
                              style: const TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Hapus butir',
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    size: 18,
                                    color: AppColors.danger,
                                  ),
                                  onPressed: () => _removeChecklistItem(index),
                                ),
                                const Icon(
                                  Icons.drag_handle_rounded,
                                  size: 20,
                                  color: AppColors.textSecondary,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _newChecklistController,
                            decoration: const InputDecoration(
                              hintText: 'Tambah butir checklist...',
                              isDense: true,
                            ),
                            onSubmitted: (_) => _addChecklistItem(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          icon: const Icon(Icons.add_rounded),
                          onPressed: _addChecklistItem,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.all(AppSpacing.base),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowSoft,
                blurRadius: 16,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitActivity,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
              ),
              child: _isSubmitting
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.2,
                          ),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Menyimpan...',
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    )
                  : const Text(
                      'Simpan & Mulai Kegiatan',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
