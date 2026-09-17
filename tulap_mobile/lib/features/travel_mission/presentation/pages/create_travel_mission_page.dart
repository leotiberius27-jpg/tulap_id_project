import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../../app/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/domain/usecases/get_current_session.dart';
import '../../domain/entities/travel_mission_entity.dart';
import '../../domain/repositories/travel_repository.dart';
import 'travel_mission_detail_page.dart';

class CreateTravelMissionPage extends StatefulWidget {
  const CreateTravelMissionPage({super.key});

  @override
  State<CreateTravelMissionPage> createState() => _CreateTravelMissionPageState();
}

class _CreateTravelMissionPageState extends State<CreateTravelMissionPage> {
  int _currentStep = 0;
  bool _isSaving = false;

  // Controllers
  final _assignmentNumberController = TextEditingController();
  final _titleController = TextEditingController();
  final _purposeController = TextEditingController();
  final _originController = TextEditingController(text: 'Timika');
  final _destinationController = TextEditingController();
  final _transportDetailsController = TextEditingController();
  final _personnelNameController = TextEditingController();
  final _personnelNipController = TextEditingController();
  final _personnelPositionController = TextEditingController();
  final _personnelUnitController = TextEditingController();
  final _notesController = TextEditingController();

  // Budget Controllers
  final _transportBudgetController = TextEditingController(text: '0');
  final _perDiemBudgetController = TextEditingController(text: '0');
  final _lodgingBudgetController = TextEditingController(text: '0');
  final _fuelBudgetController = TextEditingController(text: '0');
  final _tollBudgetController = TextEditingController(text: '0');
  final _mealsBudgetController = TextEditingController(text: '0');
  final _otherBudgetController = TextEditingController(text: '0');

  DateTime _assignmentDate = DateTime.now();
  DateTime _departureDate = DateTime.now();
  DateTime _returnDate = DateTime.now().add(const Duration(days: 2));
  TravelTransportMode _transportMode = TravelTransportMode.kendaraanDinas;

  final DateFormat _dateFormat = DateFormat('dd MMMM yyyy', 'id_ID');
  final DateFormat _shortDateFormat = DateFormat('dd MMM yyyy', 'id_ID');
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _initUserData();
  }

  Future<void> _initUserData() async {
    try {
      final user = await sl<GetCurrentSession>()();
      if (user != null && mounted) {
        setState(() {
          if (_personnelNameController.text.isEmpty) {
            _personnelNameController.text = user.fullName;
          }
          if (_personnelNipController.text.isEmpty && user.nip != null) {
            _personnelNipController.text = user.nip!;
          }
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _assignmentNumberController.dispose();
    _titleController.dispose();
    _purposeController.dispose();
    _originController.dispose();
    _destinationController.dispose();
    _transportDetailsController.dispose();
    _personnelNameController.dispose();
    _personnelNipController.dispose();
    _personnelPositionController.dispose();
    _personnelUnitController.dispose();
    _notesController.dispose();
    _transportBudgetController.dispose();
    _perDiemBudgetController.dispose();
    _lodgingBudgetController.dispose();
    _fuelBudgetController.dispose();
    _tollBudgetController.dispose();
    _mealsBudgetController.dispose();
    _otherBudgetController.dispose();
    super.dispose();
  }

  double _parseBudget(TextEditingController c) {
    final clean = c.text.replaceAll(RegExp(r'[^0-9]'), '');
    return double.tryParse(clean) ?? 0.0;
  }

  double get _totalEstimatedBudget {
    return _parseBudget(_transportBudgetController) +
        _parseBudget(_perDiemBudgetController) +
        _parseBudget(_lodgingBudgetController) +
        _parseBudget(_fuelBudgetController) +
        _parseBudget(_tollBudgetController) +
        _parseBudget(_mealsBudgetController) +
        _parseBudget(_otherBudgetController);
  }

  void _handleContinue() {
    FocusScope.of(context).unfocus();

    // Step 0 validation: Dasar Penugasan
    if (_currentStep == 0) {
      if (_assignmentNumberController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nomor Surat Tugas wajib diisi.'),
            backgroundColor: AppColors.warning,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
      if (_titleController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Judul Perjalanan Dinas wajib diisi.'),
            backgroundColor: AppColors.warning,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
    }

    // Step 1 validation: Rute & Waktu
    if (_currentStep == 1) {
      if (_originController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kota Asal wajib diisi.'),
            backgroundColor: AppColors.warning,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
      if (_destinationController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kota Tujuan wajib diisi.'),
            backgroundColor: AppColors.warning,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
      if (_returnDate.isBefore(_departureDate)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tanggal kembali tidak boleh sebelum tanggal berangkat.'),
            backgroundColor: AppColors.danger,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
    }

    // Step 3 validation: Data Pelaksana
    if (_currentStep == 3) {
      if (_personnelNameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nama Lengkap Pelaksana wajib diisi.'),
            backgroundColor: AppColors.warning,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
    }

    if (_currentStep < 5) {
      setState(() {
        _currentStep += 1;
      });
    } else {
      _submit();
    }
  }

  void _handleCancel() {
    FocusScope.of(context).unfocus();
    if (_currentStep > 0) {
      setState(() {
        _currentStep -= 1;
      });
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (_assignmentNumberController.text.trim().isEmpty) {
      setState(() => _currentStep = 0);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nomor Surat Tugas belum diisi. Silakan lengkapi pada Langkah 1.'),
          backgroundColor: AppColors.danger,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    if (_titleController.text.trim().isEmpty) {
      setState(() => _currentStep = 0);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Judul Perjalanan Dinas belum diisi. Silakan lengkapi pada Langkah 1.'),
          backgroundColor: AppColors.danger,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    if (_originController.text.trim().isEmpty) {
      setState(() => _currentStep = 1);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kota Asal belum diisi. Silakan lengkapi pada Langkah 2.'),
          backgroundColor: AppColors.danger,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    if (_destinationController.text.trim().isEmpty) {
      setState(() => _currentStep = 1);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kota Tujuan belum diisi. Silakan lengkapi pada Langkah 2.'),
          backgroundColor: AppColors.danger,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    if (_personnelNameController.text.trim().isEmpty) {
      setState(() => _currentStep = 3);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama Lengkap Pelaksana belum diisi. Silakan lengkapi pada Langkah 4.'),
          backgroundColor: AppColors.danger,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      TravelRepository repo;
      try {
        repo = context.read<TravelRepository>();
      } catch (_) {
        repo = sl<TravelRepository>();
      }
      final now = DateTime.now();
      final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
      final randomSuffix = (1000 + (now.microsecond % 9000)).toString();
      final displayId = 'PD-$dateStr-$randomSuffix';
      final missionId = const Uuid().v4();

      final budget = TravelBudgetEstimate(
        transportasi: _parseBudget(_transportBudgetController),
        uangHarian: _parseBudget(_perDiemBudgetController),
        penginapan: _parseBudget(_lodgingBudgetController),
        bbm: _parseBudget(_fuelBudgetController),
        tol: _parseBudget(_tollBudgetController),
        konsumsi: _parseBudget(_mealsBudgetController),
        lainnya: _parseBudget(_otherBudgetController),
      );

      final personnel = TravelPersonnelSnapshot(
        fullName: _personnelNameController.text.trim().isNotEmpty
            ? _personnelNameController.text.trim()
            : 'Petugas Lapangan',
        employeeNumber: _personnelNipController.text.trim().isNotEmpty
            ? _personnelNipController.text.trim()
            : null,
        position: _personnelPositionController.text.trim().isNotEmpty
            ? _personnelPositionController.text.trim()
            : null,
        unitName: _personnelUnitController.text.trim().isNotEmpty
            ? _personnelUnitController.text.trim()
            : null,
      );

      final mission = TravelMissionEntity(
        id: missionId,
        displayId: displayId,
        userId: 'user_active',
        assignmentLetterNumber: _assignmentNumberController.text.trim(),
        assignmentLetterDate: _assignmentDate,
        title: _titleController.text.trim(),
        purpose: _purposeController.text.trim().isNotEmpty
            ? _purposeController.text.trim()
            : _titleController.text.trim(),
        origin: _originController.text.trim().isNotEmpty
            ? _originController.text.trim()
            : 'Timika',
        destination: _destinationController.text.trim(),
        departureDate: _departureDate,
        returnDate: _returnDate,
        transportMode: _transportMode,
        transportDetails: _transportDetailsController.text.trim().isNotEmpty
            ? _transportDetailsController.text.trim()
            : null,
        status: TravelMissionStatus.ongoing,
        budgetEstimate: budget,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        personnelSnapshot: personnel,
        createdAt: now,
      );

      await repo.createTravelMission(mission);

      if (mounted) {
        setState(() => _isSaving = false);
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          isDismissible: false,
          enableDrag: false,
          builder: (ctx) => _buildSuccessActionSheet(ctx, mission),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan perjalanan dinas: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentStep == 5;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0.5,
        title: const Text(
          'Buat Perjalanan Dinas Baru',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: MediaQuery.of(context).padding.bottom + 12,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: const Border(top: BorderSide(color: AppColors.border)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 6,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Langkah ${_currentStep + 1} dari 6',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  _getStepTitle(_currentStep),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                if (_currentStep > 0) ...[
                  OutlinedButton(
                    onPressed: _isSaving ? null : _handleCancel,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(80, 48),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Kembali'),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _handleContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isLast ? AppColors.success : AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: isLast ? 2 : 0,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: AppColors.onPrimary,
                              strokeWidth: 2,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isLast ? Icons.check_circle_rounded : Icons.arrow_forward_rounded,
                                color: AppColors.onPrimary,
                                size: 19,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    isLast ? 'Simpan & Terbitkan Perjalanan' : 'Lanjutkan',
                                    style: const TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.onPrimary,
                                      letterSpacing: 0.2,
                                    ),
                                    maxLines: 1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Stepper(
        type: StepperType.vertical,
        physics: const ClampingScrollPhysics(),
        currentStep: _currentStep,
        onStepTapped: (step) {
          FocusScope.of(context).unfocus();
          setState(() => _currentStep = step);
        },
        onStepContinue: _handleContinue,
        onStepCancel: _handleCancel,
        controlsBuilder: (context, details) {
          return const SizedBox(height: 16);
        },
        steps: [
          // Step 1: Dasar Penugasan
          Step(
            title: const Text('Dasar Penugasan', style: TextStyle(fontWeight: FontWeight.bold)),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.indexed,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField(
                  controller: _assignmentNumberController,
                  label: 'Nomor Surat Tugas *',
                  hint: 'Contoh: ST.012/SETDA/VIII/2026',
                  icon: Icons.article_outlined,
                ),
                const SizedBox(height: 12),
                _buildDatePicker(
                  label: 'Tanggal Surat Tugas',
                  date: _assignmentDate,
                  onSelect: (d) => setState(() => _assignmentDate = d),
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _titleController,
                  label: 'Judul Perjalanan Dinas *',
                  hint: 'Contoh: Koordinasi Teknis & Pengawasan Lapangan',
                  icon: Icons.title,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _purposeController,
                  label: 'Maksud / Perihal Penugasan',
                  hint: 'Uraian tujuan perjalanan dinas...',
                  icon: Icons.description_outlined,
                  maxLines: 2,
                ),
              ],
            ),
          ),

          // Step 2: Rute & Waktu
          Step(
            title: const Text('Rute & Waktu', style: TextStyle(fontWeight: FontWeight.bold)),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.indexed,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField(
                  controller: _originController,
                  label: 'Kota Asal *',
                  hint: 'Timika',
                  icon: Icons.trip_origin,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _destinationController,
                  label: 'Kota Tujuan *',
                  hint: 'Contoh: Jayapura / Nabire',
                  icon: Icons.location_on_outlined,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _buildDatePicker(
                        label: 'Berangkat',
                        date: _departureDate,
                        onSelect: (d) {
                          setState(() {
                            _departureDate = d;
                            if (_returnDate.isBefore(_departureDate)) {
                              _returnDate = _departureDate;
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildDatePicker(
                        label: 'Kembali',
                        date: _returnDate,
                        onSelect: (d) {
                          setState(() {
                            _returnDate = d;
                            if (_returnDate.isBefore(_departureDate)) {
                              _departureDate = _returnDate;
                            }
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.infoSoft,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.timer_outlined, size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Total Durasi: ${_returnDate.difference(_departureDate).inDays + 1} Hari Kalender',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Step 3: Moda Transportasi
          Step(
            title: const Text('Moda Transportasi', style: TextStyle(fontWeight: FontWeight.bold)),
            isActive: _currentStep >= 2,
            state: _currentStep > 2 ? StepState.complete : StepState.indexed,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pilih Moda Transportasi *',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<TravelTransportMode>(
                  value: _transportMode,
                  isExpanded: true,
                  icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                  decoration: InputDecoration(
                    prefixIcon: Icon(_getTransportIcon(_transportMode), color: AppColors.primary, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  items: TravelTransportMode.values.map((mode) {
                    return DropdownMenuItem(
                      value: mode,
                      child: Text(
                        mode.label,
                        style: const TextStyle(fontSize: 13.5, color: AppColors.textPrimary),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _transportMode = val);
                  },
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _transportDetailsController,
                  label: 'Rincian / No. Kendaraan / Maskapai',
                  hint: 'Contoh: Garuda Indonesia GA-654 / Toyota Hilux PA 1234 XX',
                  icon: Icons.directions,
                ),
              ],
            ),
          ),

          // Step 4: Data Pelaksana
          Step(
            title: const Text('Personil Pelaksana', style: TextStyle(fontWeight: FontWeight.bold)),
            isActive: _currentStep >= 3,
            state: _currentStep > 3 ? StepState.complete : StepState.indexed,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField(
                  controller: _personnelNameController,
                  label: 'Nama Lengkap Pelaksana *',
                  hint: 'Contoh: Ahmad Yani, S.T.',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _personnelNipController,
                  label: 'NIP / Nomor Pegawai',
                  hint: '19850101 201001 1 001',
                  icon: Icons.badge_outlined,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _personnelPositionController,
                  label: 'Jabatan',
                  hint: 'Contoh: Pengawas Teknis / Staf Perencanaan',
                  icon: Icons.work_outline,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _personnelUnitController,
                  label: 'Unit Kerja / Instansi',
                  hint: 'Contoh: Dinas PUPR Kabupaten Mimika',
                  icon: Icons.account_balance_outlined,
                ),
              ],
            ),
          ),

          // Step 5: Estimasi Anggaran
          Step(
            title: const Text('Estimasi Anggaran', style: TextStyle(fontWeight: FontWeight.bold)),
            isActive: _currentStep >= 4,
            state: _currentStep > 4 ? StepState.complete : StepState.indexed,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCurrencyField(controller: _transportBudgetController, label: 'Biaya Transportasi / Tiket'),
                const SizedBox(height: 10),
                _buildCurrencyField(controller: _perDiemBudgetController, label: 'Uang Harian / Saku'),
                const SizedBox(height: 10),
                _buildCurrencyField(controller: _lodgingBudgetController, label: 'Penginapan / Hotel'),
                const SizedBox(height: 10),
                _buildCurrencyField(controller: _fuelBudgetController, label: 'BBM Kendaraan'),
                const SizedBox(height: 10),
                _buildCurrencyField(controller: _tollBudgetController, label: 'Tol & Parkir'),
                const SizedBox(height: 10),
                _buildCurrencyField(controller: _mealsBudgetController, label: 'Konsumsi Lapangan'),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.infoSoft,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Estimasi Anggaran:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        _currencyFormat.format(_totalEstimatedBudget),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Step 6: Review & Catatan
          Step(
            title: const Text('Konfirmasi & Catatan', style: TextStyle(fontWeight: FontWeight.bold)),
            isActive: _currentStep >= 5,
            state: StepState.indexed,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField(
                  controller: _notesController,
                  label: 'Catatan Tambahan / Ringkasan Rencana',
                  hint: 'Tambahkan instruksi khusus atau catatan rencana perjalanan...',
                  icon: Icons.note_outlined,
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.infoSoft,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.description_outlined, color: AppColors.primary, size: 18),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Lembar Ringkasan Rencana Perjalanan',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.visible,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      _buildSummaryRow(
                        icon: Icons.article_outlined,
                        title: 'Nomor Surat Tugas',
                        value: _assignmentNumberController.text.isNotEmpty
                            ? _assignmentNumberController.text
                            : '-',
                      ),
                      const SizedBox(height: 8),
                      _buildSummaryRow(
                        icon: Icons.title,
                        title: 'Judul Penugasan',
                        value: _titleController.text.isNotEmpty
                            ? _titleController.text
                            : '-',
                      ),
                      const SizedBox(height: 8),
                      _buildSummaryRow(
                        icon: Icons.route_outlined,
                        title: 'Rute & Jadwal',
                        value: '${_originController.text} ➔ ${_destinationController.text} (${_dateFormat.format(_departureDate)} – ${_dateFormat.format(_returnDate)}, ${_returnDate.difference(_departureDate).inDays + 1} Hari)',
                      ),
                      const SizedBox(height: 8),
                      _buildSummaryRow(
                        icon: Icons.directions,
                        title: 'Moda Transportasi',
                        value: '${_transportMode.label}${_transportDetailsController.text.isNotEmpty ? ' (${_transportDetailsController.text})' : ''}',
                      ),
                      const SizedBox(height: 8),
                      _buildSummaryRow(
                        icon: Icons.person_outline,
                        title: 'Personil Pelaksana',
                        value: '${_personnelNameController.text}${_personnelPositionController.text.isNotEmpty ? ' • ${_personnelPositionController.text}' : ''}${_personnelUnitController.text.isNotEmpty ? ' • ${_personnelUnitController.text}' : ''}',
                      ),
                      const SizedBox(height: 8),
                      _buildSummaryRow(
                        icon: Icons.account_balance_wallet_outlined,
                        title: 'Total Estimasi Anggaran',
                        value: _currencyFormat.format(_totalEstimatedBudget),
                        isHighlight: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 0:
        return 'Dasar Penugasan';
      case 1:
        return 'Rute & Waktu';
      case 2:
        return 'Moda Transportasi';
      case 3:
        return 'Personil Pelaksana';
      case 4:
        return 'Estimasi Anggaran';
      case 5:
        return 'Konfirmasi & Catatan';
      default:
        return '';
    }
  }

  IconData _getTransportIcon(TravelTransportMode mode) {
    switch (mode) {
      case TravelTransportMode.pesawat:
        return Icons.flight;
      case TravelTransportMode.kendaraanDinas:
        return Icons.directions_car;
      case TravelTransportMode.kendaraanPribadi:
        return Icons.directions_car_filled;
      case TravelTransportMode.kapal:
        return Icons.directions_boat;
      case TravelTransportMode.transportasiUmum:
        return Icons.directions_bus;
      case TravelTransportMode.lainnya:
        return Icons.commute;
    }
  }

  Widget _buildSummaryRow({
    required IconData icon,
    required String title,
    required String value,
    bool isHighlight = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: isHighlight ? AppColors.primary : AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
                  color: isHighlight ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessActionSheet(BuildContext ctx, TravelMissionEntity mission) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(ctx).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.successSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: AppColors.success,
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Perjalanan Dinas Diterbitkan!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.infoSoft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${mission.displayId} • ${mission.status.label.toUpperCase()}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Data perjalanan dinas "${mission.title}" ke ${mission.destination} telah tersimpan aman di perangkat lokal.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          // Primary action: Buka Lembar Kerja
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.arrow_forward_rounded, color: AppColors.onPrimary),
              label: const Text(
                'Buka Lembar Kerja Perjalanan Ini',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onPrimary,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TravelMissionDetailPage(travelId: mission.id),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          // Secondary action: Ke Daftar Perjalanan
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.format_list_bulleted, color: AppColors.textPrimary),
              label: const Text(
                'Kembali ke Daftar Perjalanan',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context, true);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildCurrencyField({
    required TextEditingController controller,
    required String label,
  }) {
    final rawValue = _parseBudget(controller);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            if (rawValue > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.infoSoft,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _currencyFormat.format(rawValue),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            ThousandsSeparatorInputFormatter(),
          ],
          decoration: InputDecoration(
            hintText: '0',
            hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            prefixText: 'Rp ',
            prefixStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime date,
    required Function(DateTime) onSelect,
  }) {
    return InkWell(
      onTap: () async {
        FocusScope.of(context).unfocus();
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime(2035),
        );
        if (picked != null) onSelect(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_month, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _shortDateFormat.format(date),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      maxLines: 1,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat.decimalPattern('id_ID');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final cleanDigits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanDigits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final numValue = int.tryParse(cleanDigits);
    if (numValue == null) {
      return oldValue;
    }

    final formatted = _formatter.format(numValue);
    final oldRightOffset = oldValue.text.length - oldValue.selection.end;
    final newSelectionOffset = (formatted.length - oldRightOffset).clamp(0, formatted.length);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: newSelectionOffset),
    );
  }
}
