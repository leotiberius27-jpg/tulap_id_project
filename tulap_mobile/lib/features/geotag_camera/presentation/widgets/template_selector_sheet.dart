import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/entities/watermark_template_entity.dart';
import '../controllers/geotag_camera_controller.dart';

/// TemplateSelectorSheet
/// ----------------------------------------------------------------------
/// Bottom sheet profesional untuk memilih template stamp geotag dan
/// menyesuaikan elemen visual foto bukti secara interaktif.
/// ----------------------------------------------------------------------
class TemplateSelectorSheet extends StatefulWidget {
  final GeotagCameraController controller;

  const TemplateSelectorSheet({
    super.key,
    required this.controller,
  });

  static Future<void> show(
    BuildContext context, {
    required GeotagCameraController controller,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TemplateSelectorSheet(controller: controller),
    );
  }

  @override
  State<TemplateSelectorSheet> createState() => _TemplateSelectorSheetState();
}

class _TemplateSelectorSheetState extends State<TemplateSelectorSheet> {
  bool _showCustomization = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final config = widget.controller.state.stampConfig;

        return Container(
          height: MediaQuery.of(context).size.height * 0.78,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 24,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              // 1. Drag Handle
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 40,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 2. Header: Judul & Tombol Tutup
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pilih Template Stamp',
                          style: TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Pilih gaya visual watermark bukti kegiatan',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      color: const Color(0xFF64748B),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              const Divider(height: 20),

              // 3. Grid Template & Accordion Kustomisasi
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  children: [
                    // Grid 6 Template Utama
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 1.18,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: TemplateCatalog.all.length,
                      itemBuilder: (context, index) {
                        final template = TemplateCatalog.all[index];
                        final isSelected = config.templateId == template.id;

                        return _buildTemplateCard(
                          context: context,
                          template: template,
                          isSelected: isSelected,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            widget.controller.setTemplate(template.id);
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    // Accordion: Sesuaikan Elemen Tampilan
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Column(
                        children: [
                          InkWell(
                            onTap: () {
                              setState(() {
                                _showCustomization = !_showCustomization;
                              });
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.tune_rounded,
                                    color: const Color(0xFF006EE6),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  const Expanded(
                                    child: Text(
                                      'Sesuaikan Elemen Visual',
                                      style: TextStyle(
                                        color: Color(0xFF0F172A),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    _showCustomization
                                        ? Icons.expand_less_rounded
                                        : Icons.expand_more_rounded,
                                    color: Colors.black45,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          if (_showCustomization) ...[
                            const Divider(height: 1),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Forensic Notice
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0x1A006EE6),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: const Color(0x33006EE6)),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Icons.shield_outlined,
                                          color: Color(0xFF006EE6),
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Pemberitahuan: Mematikan elemen visual hanya menyembunyikannya dari foto. Seluruh metadata forensik tetap tersimpan lengkap di Evidence Record.',
                                            style: const TextStyle(
                                              color: Color(0xFF1E40AF),
                                              fontSize: 11.5,
                                              height: 1.35,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  _buildSwitchTile('Nama Kegiatan', config.showTaskName, (val) {
                                    widget.controller.updateStampConfig(config.copyWith(showTaskName: val));
                                  }),
                                  _buildSwitchTile('Lokasi / Alamat', config.showLocation, (val) {
                                    widget.controller.updateStampConfig(config.copyWith(showLocation: val));
                                  }),
                                  _buildSwitchTile('Tanggal & Jam', config.showDate, (val) {
                                    widget.controller.updateStampConfig(config.copyWith(showDate: val, showTime: val));
                                  }),
                                  _buildSwitchTile('Koordinat GPS', config.showCoordinates, (val) {
                                    widget.controller.updateStampConfig(config.copyWith(showCoordinates: val));
                                  }),
                                  _buildSwitchTile('Akurasi GPS (±m)', config.showGpsAccuracy, (val) {
                                    widget.controller.updateStampConfig(config.copyWith(showGpsAccuracy: val));
                                  }),
                                  _buildSwitchTile('ID Bukti (Short ID)', config.showEvidenceId, (val) {
                                    widget.controller.updateStampConfig(config.copyWith(showEvidenceId: val));
                                  }),
                                  _buildSwitchTile('Nama Petugas & Instansi', config.showOfficerName, (val) {
                                    widget.controller.updateStampConfig(config.copyWith(showOfficerName: val));
                                  }),
                                  _buildSwitchTile('Mini Map Kontekstual', config.showMiniMap, (val) {
                                    widget.controller.updateStampConfig(config.copyWith(showMiniMap: val));
                                  }),
                                  _buildSwitchTile('QR Google Maps', config.showQrMaps, (val) {
                                    widget.controller.updateStampConfig(config.copyWith(showQrMaps: val));
                                  }),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTemplateCard({
    required BuildContext context,
    required WatermarkTemplateDefinition template,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label: 'Template ${template.name}, ${isSelected ? "dipilih" : "tidak dipilih"}',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? const Color(0xFF006EE6) : const Color(0xFFE2E8F0),
              width: isSelected ? 2.0 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF006EE6) : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      template.icon,
                      size: 18,
                      color: isSelected ? Colors.white : const Color(0xFF475569),
                    ),
                  ),
                  if (isSelected)
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF006EE6),
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.name,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    template.subtitle,
                    style: TextStyle(
                      color: isSelected ? const Color(0xFF006EE6) : const Color(0xFF64748B),
                      fontSize: 11.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF334155),
              fontSize: 13.0,
              fontWeight: FontWeight.w500,
            ),
          ),
          Switch.adaptive(
            value: value,
            activeColor: const Color(0xFF006EE6),
            onChanged: (newVal) {
              HapticFeedback.selectionClick();
              onChanged(newVal);
            },
          ),
        ],
      ),
    );
  }
}
