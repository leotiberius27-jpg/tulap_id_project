import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../../app/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../expense_ocr/presentation/pages/receipt_scanner_entry_page.dart';
import '../../../geotag_camera/domain/usecases/get_task_photo_previews.dart';
import '../../../task_detail/domain/entities/task_entity.dart';
import '../../../task_detail/domain/usecases/get_task_detail.dart';
import '../../../task_detail/domain/usecases/start_task.dart';
import '../../../task_detail/domain/usecases/submit_task_for_verification.dart';
import '../../../task_detail/domain/usecases/toggle_checklist_item.dart';
import '../../../task_detail/presentation/controllers/task_detail_controller.dart';
import '../../../task_detail/presentation/pages/create_activity_page.dart';
import '../../../task_detail/presentation/pages/task_detail_page.dart';
import '../../domain/entities/lpj_package_entity.dart';
import '../../domain/entities/supporting_document_entity.dart';
import '../../domain/entities/travel_mission_entity.dart';
import '../../../assistant/presentation/pages/tanya_tulap_page.dart';
import '../controllers/travel_mission_detail_controller.dart';
import 'lpj_package_preview_page.dart';
import 'lpj_review_and_generate_page.dart';

class TravelMissionDetailPage extends StatelessWidget {
  final String travelId;

  const TravelMissionDetailPage({super.key, required this.travelId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<TravelMissionDetailController>(
      create: (_) => sl<TravelMissionDetailController>()..loadDetail(travelId),
      child: _TravelMissionDetailPageContent(travelId: travelId),
    );
  }
}

class _TravelMissionDetailPageContent extends StatefulWidget {
  final String travelId;

  const _TravelMissionDetailPageContent({required this.travelId});

  @override
  State<_TravelMissionDetailPageContent> createState() => _TravelMissionDetailPageContentState();
}

class _TravelMissionDetailPageContentState extends State<_TravelMissionDetailPageContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy', 'id_ID');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TravelMissionDetailController>().loadDetail(widget.travelId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadDocument(String travelId) async {
    final type = await showModalBottomSheet<SupportingDocumentType>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).padding.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Pilih Jenis Dokumen Pendukung',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Lampirkan dokumen bukti fisik penugasan atau biaya perjalanan dinas.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            ...SupportingDocumentType.values.map((t) {
              IconData icon;
              switch (t) {
                case SupportingDocumentType.assignmentLetter:
                  icon = Icons.assignment_outlined;
                  break;
                case SupportingDocumentType.sppd:
                  icon = Icons.description_outlined;
                  break;
                case SupportingDocumentType.ticket:
                  icon = Icons.flight_takeoff;
                  break;
                case SupportingDocumentType.boardingPass:
                  icon = Icons.confirmation_number_outlined;
                  break;
                case SupportingDocumentType.hotelInvoice:
                  icon = Icons.hotel_outlined;
                  break;
                case SupportingDocumentType.receipt:
                  icon = Icons.receipt_long_outlined;
                  break;
                case SupportingDocumentType.other:
                  icon = Icons.insert_drive_file_outlined;
                  break;
              }

              return Card(
                elevation: 0,
                color: AppColors.background,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.infoSoft,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: AppColors.primary, size: 20),
                  ),
                  title: Text(
                    t.label,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
                  onTap: () => Navigator.pop(ctx, t),
                ),
              );
            }),
          ],
        ),
      ),
    );

    if (type == null || !mounted) return;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).padding.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sumber Dokumen',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => Navigator.pop(ctx, ImageSource.camera),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: AppColors.infoSoft,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.camera_alt, color: AppColors.primary, size: 32),
                          SizedBox(height: 8),
                          Text(
                            'Foto Kamera',
                            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: InkWell(
                    onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: AppColors.infoSoft,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.photo_library, color: AppColors.primary, size: 32),
                          SizedBox(height: 8),
                          Text(
                            'Pilih Galeri',
                            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ],
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

    if (source == null || !mounted) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source);
    if (picked == null || !mounted) return;

    final doc = SupportingDocumentEntity(
      id: const Uuid().v4(),
      travelMissionId: travelId,
      documentType: type,
      title: '${type.label} (${_dateFormat.format(DateTime.now())})',
      filePath: picked.path,
      sha256: 'local_sha_${DateTime.now().millisecondsSinceEpoch}',
      createdAt: DateTime.now(),
    );

    await context.read<TravelMissionDetailController>().addDocument(doc);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Dokumen "${type.label}" berhasil diunggah!',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'LIHAT',
            textColor: Colors.white,
            onPressed: () {
              _tabController.animateTo(3);
            },
          ),
        ),
      );
      _tabController.animateTo(3);
    }
  }

  void _showDocumentPreview(SupportingDocumentEntity doc, String travelId) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: AppColors.primary,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      doc.title,
                      style: const TextStyle(
                        color: AppColors.onPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.onPrimary, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.55,
              ),
              child: File(doc.filePath).existsSync()
                  ? InteractiveViewer(
                      child: Image.file(
                        File(doc.filePath),
                        fit: BoxFit.contain,
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.all(32),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.insert_drive_file, size: 64, color: AppColors.primary),
                          SizedBox(height: 12),
                          Text('File dokumen tersimpan di sistem lokal.'),
                        ],
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.infoSoft,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          doc.documentType.label,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _dateFormat.format(doc.createdAt),
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 18),
                        label: const Text('Hapus Dokumen', style: TextStyle(color: AppColors.danger, fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.danger),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _confirmDeleteDocument(doc, travelId);
                        },
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.onPrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Tutup'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteDocument(SupportingDocumentEntity doc, String travelId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Dokumen?'),
        content: Text('Apakah Anda yakin ingin menghapus "${doc.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await context.read<TravelMissionDetailController>().deleteDocument(doc.id, travelId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dokumen berhasil dihapus.'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TravelMissionDetailController>();
    final state = controller.state;
    final bundle = state.bundle;

    if (bundle == null) {
      if (state.errorMessage != null) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            elevation: 0.5,
            title: const Text(
              'Detail Perjalanan Dinas',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
                  const SizedBox(height: 12),
                  Text(
                    state.errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => context.read<TravelMissionDetailController>().loadDetail(widget.travelId),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Coba Lagi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0.5,
          title: const Text(
            'Memuat Detail Perjalanan...',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final travel = bundle.travel;
    final completeness = bundle.completeness;
    final summary = bundle.expenseSummary;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0.5,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              travel.displayId,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              travel.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome_rounded, color: AppColors.primary),
            tooltip: 'Tanya Tulap (Kopilot Perjalanan)',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TanyaTulapPage(
                    contextEntityType: 'TRAVEL',
                    contextEntityId: travel.id,
                    contextTitle: travel.title,
                  ),
                ),
              );
            },
          ),
          _buildStatusBadge(travel.status),
          const SizedBox(width: 4),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
            onSelected: (val) {
              if (val == 'complete') {
                controller.markCompleted(travel.id);
              } else if (val == 'refresh') {
                controller.loadDetail(travel.id);
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'refresh', child: Text('Segarkan Data')),
              if (travel.status != TravelMissionStatus.completed)
                const PopupMenuItem(value: 'complete', child: Text('Tandai Selesai')),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            const Tab(text: 'Ringkasan'),
            Tab(text: 'Kegiatan (${bundle.linkedTasks.length})'),
            Tab(text: 'Pengeluaran (${summary.totalReceiptCount})'),
            Tab(text: 'Dokumen (${bundle.supportingDocuments.length})'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('LPJ'),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: completeness.percentage == 100
                          ? AppColors.success
                          : AppColors.warning,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${completeness.percentage}%',
                      style: const TextStyle(
                        color: AppColors.onPrimary,
                        fontSize: 10,
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
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Ringkasan
          _buildSummaryTab(bundle),

          // Tab 2: Kegiatan
          _buildActivitiesTab(bundle),

          // Tab 3: Pengeluaran
          _buildExpensesTab(bundle),

          // Tab 4: Dokumen
          _buildDocumentsTab(bundle),

          // Tab 5: LPJ
          _buildLpjTab(bundle),
        ],
      ),
    );
  }

  Widget _buildSummaryTab(dynamic bundle) {
    final travel = bundle.travel as TravelMissionEntity;
    final completeness = bundle.completeness;
    final summary = bundle.expenseSummary;

    return RefreshIndicator(
      onRefresh: () => context.read<TravelMissionDetailController>().loadDetail(travel.id),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Completeness Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  AppColors.heroGradientStart,
                  AppColors.heroGradientEnd,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadowSoft,
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Kelengkapan LPJ',
                      style: TextStyle(
                        color: AppColors.onPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${completeness.percentage}%',
                      style: const TextStyle(
                        color: AppColors.onPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: completeness.score,
                    backgroundColor: Colors.white24,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      completeness.percentage == 100
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  completeness.isReadyForLpj
                      ? '✓ Dokumen wajib lengkap, siap membuat paket LPJ.'
                      : 'Perhatian: Ada ${completeness.blockers.length} dokumen wajib belum lengkap.',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Metrik Grid
          Row(
            children: [
              Expanded(
                child: _buildMetricBox(
                  icon: Icons.assignment_outlined,
                  label: 'Kegiatan',
                  value: '${bundle.linkedTasks.length}',
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildMetricBox(
                  icon: Icons.camera_alt_outlined,
                  label: 'Bukti Foto',
                  value: '${bundle.photos.length}',
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildMetricBox(
                  icon: Icons.receipt_long_outlined,
                  label: 'Nota Riil',
                  value: '${summary.totalReceiptCount}',
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildMetricBox(
                  icon: Icons.folder_open_outlined,
                  label: 'Dokumen',
                  value: '${bundle.supportingDocuments.length}',
                  color: const Color(0xFF8B5CF6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Dokumen Pendukung Terlampir Card on Ringkasan Tab
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.folder_copy_outlined, color: AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Dokumen Pendukung (${bundle.supportingDocuments.length})',
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () => _tabController.animateTo(3),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Buka Tab ➔', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (bundle.supportingDocuments.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.infoSoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: AppColors.primary, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Belum ada dokumen. Gunakan "Unggah Dokumen" di bawah untuk melampirkan Surat Tugas / SPPD.',
                            style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (bundle.supportingDocuments as List<SupportingDocumentEntity>).map((d) {
                      return InkWell(
                        onTap: () => _showDocumentPreview(d, travel.id),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.infoSoft,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                d.documentType.label,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Informasi Misi Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dasar Penugasan & Rincian Perjalanan',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _buildInfoRow('Nomor Surat Tugas', travel.assignmentLetterNumber),
                _buildInfoRow('Tanggal Surat', _dateFormat.format(travel.assignmentLetterDate)),
                _buildInfoRow('Pelaksana', travel.personnelSnapshot.fullName),
                if (travel.personnelSnapshot.employeeNumber != null)
                  _buildInfoRow('NIP', travel.personnelSnapshot.employeeNumber!),
                _buildInfoRow('Rute Perjalanan', '${travel.origin} → ${travel.destination}'),
                _buildInfoRow('Jadwal & Durasi', '${travel.formattedPeriod} (${travel.durationDays} Hari)'),
                _buildInfoRow('Moda Transportasi', travel.transportMode.label),
                if (travel.transportDetails != null)
                  _buildInfoRow('Rincian Transport', travel.transportDetails!),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Aksi Cepat
          const Text(
            'Aksi Cepat Perjalanan',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.receipt_long, size: 18),
                  label: const Text('Scan Nota'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReceiptScannerEntryPage(
                          taskId: travel.id,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.upload_file, size: 18),
                  label: const Text('Unggah Dokumen'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _pickAndUploadDocument(travel.id),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivitiesTab(dynamic bundle) {
    final tasks = bundle.linkedTasks as List<TaskEntity>;
    final travel = bundle.travel as TravelMissionEntity;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Kegiatan Lapangan (${tasks.length})',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Tambah Kegiatan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                final created = await Navigator.push<TaskEntity>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreateActivityPage(
                      travelId: travel.id,
                      initialDestination: travel.destination,
                    ),
                  ),
                );
                if (created != null && mounted) {
                  context.read<TravelMissionDetailController>().loadDetail(travel.id);
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (tasks.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                const Icon(Icons.assignment_outlined, size: 48, color: AppColors.textMuted),
                const SizedBox(height: 12),
                const Text(
                  'Belum Ada Kegiatan Lapangan',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Tambahkan kegiatan lapangan untuk perjalanan dinas ini agar terdokumentasi rapi dalam paket LPJ.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Buat Kegiatan Lapangan Sekarang'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () async {
                    final created = await Navigator.push<TaskEntity>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CreateActivityPage(
                          travelId: travel.id,
                          initialDestination: travel.destination,
                        ),
                      ),
                    );
                    if (created != null && mounted) {
                      context.read<TravelMissionDetailController>().loadDetail(travel.id);
                    }
                  },
                ),
              ],
            ),
          )
        else
          ...tasks.map((task) {
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.border),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                title: Text(
                  task.taskName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text('${task.taskCode} • ${task.destination}'),
                    const SizedBox(height: 4),
                    Text(
                      '${task.geotagPhotoCount} Foto Bukti • ${task.expenseNoteCount} Nota',
                      style: const TextStyle(color: AppColors.primary, fontSize: 12),
                    ),
                  ],
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChangeNotifierProvider<TaskDetailController>(
                        create: (_) => TaskDetailController(
                          getTaskDetail: sl<GetTaskDetail>(),
                          toggleChecklistItem: sl<ToggleChecklistItem>(),
                          startTask: sl<StartTask>(),
                          submitForVerification: sl<SubmitTaskForVerification>(),
                          getTaskPhotoPreviews: sl<GetTaskPhotoPreviews>(),
                          taskId: task.id,
                        ),
                        child: TaskDetailPage(
                          officerName: travel.personnelSnapshot.fullName,
                          agencyName: travel.personnelSnapshot.unitName ?? 'Instansi',
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          }),
      ],
    );
  }

  Widget _buildExpensesTab(dynamic bundle) {
    final travel = bundle.travel as TravelMissionEntity;
    final summary = bundle.expenseSummary;
    final allExpenses = [
      ...summary.directExpenses,
      ...summary.activityExpenses,
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Financial Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Rekapitulasi Biaya & Realisasi',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Realisasi Riil:', style: TextStyle(fontSize: 13)),
                  Text(
                    _currencyFormat.format(summary.totalActualExpense),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Estimasi Pagu Anggaran:', style: TextStyle(fontSize: 13)),
                  Text(
                    _currencyFormat.format(summary.estimatedBudget),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Selisih (Efisiensi):', style: TextStyle(fontSize: 13)),
                  Text(
                    _currencyFormat.format(summary.varianceAmount),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: summary.varianceAmount < 0
                          ? AppColors.danger
                          : AppColors.success,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Anomalies if any
        if (summary.anomalies.isNotEmpty) ...[
          const Text(
            'Catatan Pemeriksaan Pengeluaran',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.warning),
          ),
          const SizedBox(height: 8),
          ...summary.anomalies.map((a) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warningSoft,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.warning, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        Text(a.description, style: const TextStyle(fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 10),
        ],

        // Expenses List Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Daftar Nota Kuitansi (${allExpenses.length})',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.qr_code_scanner, size: 16),
              label: const Text('Scan Nota'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReceiptScannerEntryPage(taskId: travel.id),
                  ),
                );
                if (mounted) {
                  context.read<TravelMissionDetailController>().loadDetail(travel.id);
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (allExpenses.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                const Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.textMuted),
                const SizedBox(height: 12),
                const Text(
                  'Belum Ada Nota Pengeluaran',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Scan atau unggah struk/kuitansi BBM, penginapan, makan, atau transportasi langsung dari kamera OCR.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.camera_alt, size: 18),
                  label: const Text('Scan Nota Sekarang'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReceiptScannerEntryPage(taskId: travel.id),
                      ),
                    );
                    if (mounted) {
                      context.read<TravelMissionDetailController>().loadDetail(travel.id);
                    }
                  },
                ),
              ],
            ),
          )
        else
          ...allExpenses.map((exp) {
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: AppColors.border),
            ),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.infoSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.receipt, color: AppColors.primary),
              ),
              title: Text(exp.vendorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              subtitle: Text(
                '${_dateFormat.format(exp.transactionDate)} • ${exp.category.label}',
                style: const TextStyle(fontSize: 11),
              ),
              trailing: Text(
                _currencyFormat.format(exp.totalAmount),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDocumentsTab(dynamic bundle) {
    final docs = bundle.supportingDocuments as List<SupportingDocumentEntity>;
    final travel = bundle.travel as TravelMissionEntity;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Dokumen Pendukung (${docs.length})',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Unggah Dokumen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => _pickAndUploadDocument(travel.id),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (docs.isEmpty)
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                const Icon(Icons.cloud_upload_outlined, size: 48, color: AppColors.textMuted),
                const SizedBox(height: 12),
                const Text(
                  'Belum Ada Dokumen Pendukung',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Unggah Surat Tugas resmi, lembar SPPD, tiket perjalanan, atau kuitansi hotel untuk melengkapi syarat LPJ.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add_a_photo, size: 16),
                  label: const Text('Unggah Dokumen Pertama'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _pickAndUploadDocument(travel.id),
                ),
              ],
            ),
          )
        else
          ...docs.map((doc) {
            final hasFile = File(doc.filePath).existsSync();
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.border),
              ),
              child: InkWell(
                onTap: () => _showDocumentPreview(doc, travel.id),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      // Thumbnail
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 56,
                          height: 56,
                          color: AppColors.infoSoft,
                          child: hasFile
                              ? Image.file(
                                  File(doc.filePath),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.insert_drive_file, color: AppColors.primary),
                                )
                              : const Icon(Icons.insert_drive_file, color: AppColors.primary, size: 28),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              doc.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppColors.textPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.infoSoft,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    doc.documentType.label,
                                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.primary),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _dateFormat.format(doc.createdAt),
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            const Row(
                              children: [
                                Icon(Icons.check_circle_outline, color: AppColors.success, size: 13),
                                SizedBox(width: 4),
                                Text(
                                  'Tersimpan & Siap LPJ',
                                  style: TextStyle(fontSize: 10.5, color: AppColors.success, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Action buttons
                      IconButton(
                        icon: const Icon(Icons.fullscreen, color: AppColors.primary, size: 22),
                        tooltip: 'Lihat Dokumen',
                        onPressed: () => _showDocumentPreview(doc, travel.id),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20),
                        tooltip: 'Hapus',
                        onPressed: () => _confirmDeleteDocument(doc, travel.id),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildLpjTab(dynamic bundle) {
    final completeness = bundle.completeness;
    final packages = bundle.lpjPackages as List<LpjPackageEntity>;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Completeness Header Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Pemeriksaan Kelengkapan LPJ',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${completeness.percentage}%',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: completeness.percentage == 100
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...completeness.items.map((item) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        item.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: item.isCompleted ? AppColors.success : AppColors.textMuted,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.label,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                color: item.isCompleted ? AppColors.textPrimary : AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              item.description,
                              style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),

              // Tombol Generate LPJ
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.picture_as_pdf, color: AppColors.onPrimary),
                  label: const Text(
                    'Pemeriksaan & Buat Paket LPJ',
                    style: TextStyle(color: AppColors.onPrimary, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LpjReviewAndGeneratePage(bundle: bundle),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // LPJ Packages History
        Text(
          'Riwayat Paket LPJ Terbit (${packages.length})',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (packages.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: const Center(
              child: Text(
                'Belum ada paket LPJ yang dibuat untuk perjalanan ini.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ),
          )
        else
          ...packages.map((pkg) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: AppColors.border),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.infoSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.verified, color: AppColors.primary),
                ),
                title: Text(
                  '${pkg.packageCode} (${pkg.versionLabel})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                subtitle: Text(
                  'Terbit: ${_dateFormat.format(pkg.createdAt)} • SHA-256: ${pkg.packageSha256.substring(0, 10)}...',
                  style: const TextStyle(fontSize: 11),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LpjPackagePreviewPage(package: pkg),
                    ),
                  );
                },
              ),
            );
          }),
      ],
    );
  }

  Widget _buildMetricBox({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
          const Text(': ', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(TravelMissionStatus status) {
    Color bg = AppColors.background;
    Color fg = AppColors.textSecondary;

    switch (status) {
      case TravelMissionStatus.ongoing:
        bg = AppColors.warningSoft;
        fg = AppColors.warning;
        break;
      case TravelMissionStatus.completed:
        bg = AppColors.successSoft;
        fg = AppColors.success;
        break;
      case TravelMissionStatus.lpjReady:
        bg = AppColors.infoSoft;
        fg = AppColors.primary;
        break;
      case TravelMissionStatus.draft:
      default:
        bg = AppColors.background;
        fg = AppColors.textSecondary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.label,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
