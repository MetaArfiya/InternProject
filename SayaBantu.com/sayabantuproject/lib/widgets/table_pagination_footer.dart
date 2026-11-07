import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class TablePaginationFooter extends StatelessWidget {
  const TablePaginationFooter({
    super.key,
    required this.totalCount,
    required this.currentPage,
    required this.rowsPerPage,
    required this.onPageChanged,
    required this.onRowsPerPageChanged,
    required this.itemLabel,
    this.options = const [5, 10, 25, 50],
    this.accentColor = AppColors.primaryTeal,
    this.borderColor = AppColors.grey300,
    this.headerTextColor = AppColors.grey700,
    this.cellTextColor = AppColors.grey900,
  });

  final int totalCount;
  final int currentPage;
  final int rowsPerPage;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onRowsPerPageChanged;
  final String itemLabel;
  final List<int> options;
  final Color accentColor;
  final Color borderColor;
  final Color headerTextColor;
  final Color cellTextColor;

  @override
  Widget build(BuildContext context) {
    final totalPages = totalCount == 0 ? 1 : (totalCount / rowsPerPage).ceil();
    final safePage = currentPage.clamp(1, totalPages).toInt();
    final start = totalCount == 0 ? 0 : (safePage - 1) * rowsPerPage + 1;
    final end = (safePage * rowsPerPage).clamp(0, totalCount);
    final textStyle = TextStyle(
      fontSize: 12.5,
      color: headerTextColor,
      fontWeight: FontWeight.w500,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Text(
            'Menampilkan $start–$end dari $totalCount $itemLabel',
            style: textStyle,
          ),
          const Spacer(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: rowsPerPage,
                    isDense: true,
                    icon: Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        size: 16,
                        color: headerTextColor,
                      ),
                    ),
                    style: TextStyle(
                      fontSize: 12.5,
                      color: cellTextColor,
                      fontWeight: FontWeight.w600,
                    ),
                    items: options
                        .map(
                          (value) => DropdownMenuItem<int>(
                            value: value,
                            child: Text('$value / hal'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) onRowsPerPageChanged(value);
                    },
                  ),
                ),
              ),
              _pageButton(
                icon: Icons.chevron_left,
                enabled: safePage > 1,
                borderColor: borderColor,
                onTap: () => onPageChanged(safePage - 1),
              ),
              Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Hal $safePage / $totalPages',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: accentColor,
                  ),
                ),
              ),
              _pageButton(
                icon: Icons.chevron_right,
                enabled: safePage < totalPages,
                borderColor: borderColor,
                onTap: () => onPageChanged(safePage + 1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pageButton({
    required IconData icon,
    required bool enabled,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: enabled ? AppColors.grey300 : borderColor,
            ),
          ),
          child: Icon(
            icon,
            size: 18,
            color: enabled ? AppColors.grey700 : AppColors.grey300,
          ),
        ),
      ),
    );
  }
}
