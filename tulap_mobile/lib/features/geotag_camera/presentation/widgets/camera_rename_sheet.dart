import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/camera/file_naming_service.dart';
import '../../domain/entities/camera_preferences_entity.dart';

/// CameraRenameSheet
/// ----------------------------------------------------------------------
/// Modal untuk mengatur pola nama berkas foto & video yang akan diambil (Phase 4).
/// - Mode OTOMATIS vs KUSTOM
/// - Pratinjau nama berkas secara real-time
/// - Menjaga pemisahan tegas antara Nama Berkas dan Evidence ID
/// ----------------------------------------------------------------------
class CameraRenameSheet extends StatefulWidget {
  final FileNamingMode currentMode;
  final String? currentPrefix;
  final String taskName;
  final bool isVideo;
  final void Function(FileNamingMode mode, String? customPrefix) onSave;

  const CameraRenameSheet({
    super.key,
    required this.currentMode,
    required this.currentPrefix,
    required this.taskName,
    required this.isVideo,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    required FileNamingMode currentMode,
    required String? currentPrefix,
    required String taskName,
    required bool isVideo,
    required void Function(FileNamingMode mode, String? customPrefix) onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CameraRenameSheet(
        currentMode: currentMode,
        currentPrefix: currentPrefix,
        taskName: taskName,
        isVideo: isVideo,
        onSave: onSave,
      ),
    );
  }

  @override
  State<CameraRenameSheet> createState() => _CameraRenameSheetState();
}

class _CameraRenameSheetState extends State<CameraRenameSheet> {
  late FileNamingMode _selectedMode;
  late TextEditingController _prefixController;
  final FileNamingService _namingService = FileNamingService();

  @override
  void initState() {
    super.initState();
    _selectedMode = widget.currentMode;
    _prefixController = TextEditingController(text: widget.currentPrefix ?? '');
  }

  @override
  void dispose() {
    _prefixController.dispose();
    super.dispose();
  }

  String _computePreview() {
    return _namingService.generateFilename(
      mode: _selectedMode,
      taskName: widget.taskName,
      timestamp: DateTime.now(),
      isVideo: widget.isVideo,
      customPrefix: _prefixController.text,
      sequence: 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final previewName = _computePreview();

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0x26006EE6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.drive_file_rename_outline_rounded,
                    color: Color(0xFF006EE6),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pola Nama Berkas',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Mengatur format penamaan bukti untuk pengambilan berikutnya',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Pratinjau Nama Berkas
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.white12 : Colors.black12,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PRATINJAU NAMA FILE:',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF006EE6),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    previewName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Mode Selector: Otomatis
            _buildModeOption(
              mode: FileNamingMode.automatic,
              title: 'Format Otomatis Berbasis Tugas',
              subtitle: '[Nama_Kegiatan]_[YYYYMMDD]_[HHMMSS]_[Urutan]',
              isDark: isDark,
            ),
            const SizedBox(height: 8),

            // Mode Selector: Kustom
            _buildModeOption(
              mode: FileNamingMode.custom,
              title: 'Format Kustom',
              subtitle: 'Gunakan awalan nama khusus yang Anda tentukan',
              isDark: isDark,
            ),

            if (_selectedMode == FileNamingMode.custom) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _prefixController,
                style: TextStyle(
                  fontSize: 13.5,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  labelText: 'Awalan Nama Berkas',
                  hintText: 'Contoh: Pemeriksaan_Kendaraan',
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF006EE6),
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ],

            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      Navigator.of(context).pop();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      side: BorderSide(
                        color: isDark ? Colors.white24 : Colors.grey.shade300,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Batal',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      final prefix = _prefixController.text.trim();
                      widget.onSave(
                        _selectedMode,
                        prefix.isEmpty ? null : prefix,
                      );
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF006EE6),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Terapkan',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
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

  Widget _buildModeOption({
    required FileNamingMode mode,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    final isSelected = _selectedMode == mode;
    final activeBlue = const Color(0xFF006EE6);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedMode = mode);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? activeBlue.withValues(alpha: 0.12)
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? activeBlue
                : (isDark ? Colors.white12 : Colors.black12),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: isSelected ? activeBlue : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
