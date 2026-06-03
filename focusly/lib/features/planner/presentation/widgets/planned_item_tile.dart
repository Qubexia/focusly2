import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/planned_item_model.dart';

class PlannedItemTile extends StatelessWidget {
  const PlannedItemTile({
    super.key,
    required this.item,
    required this.onComplete,
    required this.onDelete,
  });

  final PlannedItemModel item;
  final VoidCallback onComplete;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _getColor(item.itemType);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 6,
                color: item.completed ? AppColors.secondary : color,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _buildCheckbox(context),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                decoration: item.completed
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: item.completed
                                    ? (isDark
                                        ? AppColors.textTertiaryDark
                                        : AppColors.textTertiaryLight)
                                    : (isDark
                                        ? AppColors.textPrimaryDark
                                        : AppColors.textPrimaryLight),
                              ),
                            ),
                            if (item.time != null || item.notes != null)
                              const SizedBox(height: 4),
                            Row(
                              children: [
                                if (item.time != null) ...[
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: 14,
                                    color: isDark
                                        ? AppColors.textTertiaryDark
                                        : AppColors.textTertiaryLight,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    item.time!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? AppColors.textSecondaryDark
                                          : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                ],
                                if (item.notes != null &&
                                    item.notes!.isNotEmpty) ...[
                                  if (item.time != null)
                                    const Padding(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 8),
                                      child: Text('•'),
                                    ),
                                  Expanded(
                                    child: Text(
                                      item.notes!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark
                                            ? AppColors.textSecondaryDark
                                            : AppColors.textSecondaryLight,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline_rounded,
                            size: 20),
                        color: AppColors.error.withValues(alpha: 0.7),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckbox(BuildContext context) {
    return GestureDetector(
      onTap: item.completed ? null : onComplete,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: item.completed
              ? AppColors.secondary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: item.completed
                ? AppColors.secondary
                : (Theme.of(context).brightness == Brightness.dark
                    ? AppColors.borderDark
                    : AppColors.borderLight),
            width: 2,
          ),
        ),
        child: item.completed
            ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
            : null,
      ),
    );
  }

  Color _getColor(PlannedItemType type) {
    switch (type) {
      case PlannedItemType.task:
        return AppColors.primary;
      case PlannedItemType.revision:
        return AppColors.secondary;
      case PlannedItemType.lecture:
        return AppColors.primaryDark;
      case PlannedItemType.exam:
        return AppColors.premium;
    }
  }
}
