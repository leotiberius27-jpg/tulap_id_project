import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/search_result_entity.dart';

class SearchResultCard extends StatelessWidget {
  final SearchResultEntity item;
  final VoidCallback onTap;

  const SearchResultCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMMM yyyy', 'id_ID');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      color: AppColors.surface,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Left Thumbnail or Entity Icon
              _buildLeadingWidget(),
              const SizedBox(width: 12),

              // 2. Center Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: Entity Badge & Date
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildEntityTypeBadge(item.entityType),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            dateFormat.format(item.date),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Title
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    // Subtitle / Details
                    if (item.subtitle != null && item.subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],

                    // Location Info
                    if (item.location != null && item.location!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 12,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              item.location!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Special Metric Row per Entity
                    _buildEntitySpecificFooter(),
                  ],
                ),
              ),
              const SizedBox(width: 6),

              // 3. Right Chevron
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeadingWidget() {
    // If local image exists (e.g. photo or receipt scan)
    if (item.localThumbnailPath != null && item.localThumbnailPath!.isNotEmpty) {
      final file = File(item.localThumbnailPath!);
      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(
            file,
            width: 52,
            height: 52,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildFallbackIcon(),
          ),
        );
      }
    }

    return _buildFallbackIcon();
  }

  Widget _buildFallbackIcon() {
    IconData icon;
    Color bg;
    Color fg;

    switch (item.entityType) {
      case SearchEntityType.activity:
        icon = Icons.assignment_outlined;
        bg = AppColors.infoSoft;
        fg = AppColors.primary;
        break;
      case SearchEntityType.travel:
        icon = Icons.flight_takeoff;
        bg = const Color(0xFFE8F5E9);
        fg = const Color(0xFF2E7D32);
        break;
      case SearchEntityType.evidence:
        icon = Icons.camera_alt_outlined;
        bg = const Color(0xFFF3E5F5);
        fg = const Color(0xFF7B1FA2);
        break;
      case SearchEntityType.receipt:
      case SearchEntityType.expense:
        icon = Icons.receipt_long_outlined;
        bg = const Color(0xFFFFF3E0);
        fg = const Color(0xFFE65100);
        break;
      case SearchEntityType.report:
        icon = Icons.description_outlined;
        bg = const Color(0xFFE0F2F1);
        fg = const Color(0xFF00695C);
        break;
      case SearchEntityType.document:
        icon = Icons.insert_drive_file_outlined;
        bg = const Color(0xFFEDE7F6);
        fg = const Color(0xFF512DA8);
        break;
      case SearchEntityType.lpj:
        icon = Icons.folder_special_outlined;
        bg = const Color(0xFFFFEBEE);
        fg = const Color(0xFFC62828);
        break;
    }

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: fg, size: 24),
    );
  }

  Widget _buildEntityTypeBadge(SearchEntityType type) {
    Color color;
    switch (type) {
      case SearchEntityType.activity:
        color = AppColors.primary;
        break;
      case SearchEntityType.travel:
        color = const Color(0xFF2E7D32);
        break;
      case SearchEntityType.evidence:
        color = const Color(0xFF7B1FA2);
        break;
      case SearchEntityType.receipt:
      case SearchEntityType.expense:
        color = const Color(0xFFE65100);
        break;
      case SearchEntityType.report:
        color = const Color(0xFF00695C);
        break;
      case SearchEntityType.document:
        color = const Color(0xFF512DA8);
        break;
      case SearchEntityType.lpj:
        color = const Color(0xFFC62828);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        type.label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEntitySpecificFooter() {
    if (item.metadata == null) return const SizedBox.shrink();

    final widgets = <Widget>[];

    // Activity: photoCount & expenseCount
    if (item.entityType == SearchEntityType.activity) {
      final pCount = item.metadata?['photoCount'];
      final eCount = item.metadata?['expenseCount'];
      if (pCount != null || eCount != null) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                if (pCount != null) ...[
                  const Icon(Icons.camera_alt, size: 11, color: AppColors.textMuted),
                  const SizedBox(width: 3),
                  Text('$pCount Foto', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                  const SizedBox(width: 8),
                ],
                if (eCount != null) ...[
                  const Icon(Icons.receipt, size: 11, color: AppColors.textMuted),
                  const SizedBox(width: 3),
                  Text('$eCount Nota', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                ],
              ],
            ),
          ),
        );
      }
    }

    // LPJ: Completeness Score
    if (item.entityType == SearchEntityType.lpj) {
      final score = item.metadata?['completenessScore'];
      if (score != null) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                const Icon(Icons.verified, size: 12, color: AppColors.success),
                const SizedBox(width: 4),
                Text(
                  'Kelengkapan: $score%',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    if (widgets.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: widgets);
  }
}
