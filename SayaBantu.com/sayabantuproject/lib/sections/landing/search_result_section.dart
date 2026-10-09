import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../models/job_model.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/safe_mouse_region.dart';

class SearchResultSection extends StatelessWidget {
  final List<JobModel> jobs;
  final String keyword;

  const SearchResultSection({
    super.key,
    required this.jobs,
    required this.keyword,
  });

  @override
  Widget build(BuildContext context) {
    if (keyword.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isMobile = width < 768;

        final horizontalPadding = isMobile ? 20.0 : 64.0;
        final verticalPadding = isMobile ? 48.0 : 72.0;

        return Container(
          width: double.infinity,
          color: AppColors.sectionLight,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1320),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: verticalPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // HEADER
                    _buildSectionLabel()
                        .animate()
                        .fadeIn(duration: 500.ms)
                        .slideX(
                          begin: -0.08,
                          end: 0,
                          duration: 500.ms,
                          curve: Curves.easeOutCubic,
                        ),

                    const SizedBox(height: 14),

                    RichText(
                      text: TextSpan(
                        style: AppTextStyles.displayOnLight.copyWith(
                          fontSize: isMobile ? 24 : 32,
                        ),
                        children: [
                          const TextSpan(text: 'Hasil pencarian untuk '),
                          TextSpan(
                            text: '"$keyword"',
                            style: const TextStyle(
                              color: AppColors.primaryTeal,
                            ),
                          ),
                        ],
                      ),
                    )
                        .animate(delay: 100.ms)
                        .fadeIn(duration: 600.ms)
                        .slideY(
                          begin: 0.08,
                          end: 0,
                          duration: 600.ms,
                          curve: Curves.easeOutCubic,
                        ),

                    const SizedBox(height: 8),

                    Text(
                      '${jobs.length} pekerjaan ditemukan',
                      style: AppTextStyles.bodyOnLight.copyWith(
                        fontSize: 14,
                        color: AppColors.grey600,
                      ),
                    )
                        .animate(delay: 150.ms)
                        .fadeIn(duration: 500.ms),

                    SizedBox(height: isMobile ? 28 : 36),

                    // RESULT
                    if (jobs.isEmpty)
                      _buildEmptyState(isMobile: isMobile)
                    else
                      _buildJobsList(isMobile: isMobile),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // SECTION LABEL
  // ============================================================
  Widget _buildSectionLabel() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: AppColors.mint,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          'HASIL PENCARIAN',
          style: TextStyle(
            color: AppColors.primaryTeal,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================
  Widget _buildEmptyState({required bool isMobile}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 32 : 48),
      decoration: BoxDecoration(
        color: AppColors.sectionAltLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primaryTeal.withOpacity(0.10),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.mint.withOpacity(0.20),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_off_rounded,
              color: AppColors.primaryTeal,
              size: 30,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Pekerjaan tidak ditemukan',
            textAlign: TextAlign.center,
            style: AppTextStyles.headingSmall.copyWith(
              fontSize: isMobile ? 16 : 18,
              color: AppColors.grey900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coba kata kunci lain atau ubah pencarianmu.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyOnLight.copyWith(
              fontSize: 13,
              color: AppColors.grey600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // JOBS LIST
  // ============================================================
  Widget _buildJobsList({required bool isMobile}) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: jobs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final job = jobs[index];
        return _JobCard(job: job, isMobile: isMobile)
            .animate(delay: Duration(milliseconds: 200 + (index * 80)))
            .fadeIn(duration: 500.ms)
            .slideY(
              begin: 0.08,
              end: 0,
              duration: 500.ms,
              curve: Curves.easeOutCubic,
            );
      },
    );
  }
}

// ============================================================
// JOB CARD
// ============================================================
class _JobCard extends StatefulWidget {
  final JobModel job;
  final bool isMobile;

  const _JobCard({
    required this.job,
    required this.isMobile,
  });

  @override
  State<_JobCard> createState() => _JobCardState();
}

class _JobCardState extends State<_JobCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return SafeMouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: () => setState(() => _isHovered = true),
      onExit: () => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: EdgeInsets.all(widget.isMobile ? 16 : 20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _isHovered
                ? AppColors.mint
                : AppColors.primaryTeal.withOpacity(0.10),
            width: _isHovered ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.darkTeal.withOpacity(
                _isHovered ? 0.10 : 0.05,
              ),
              blurRadius: _isHovered ? 20 : 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: widget.isMobile
            ? _buildMobileContent()
            : _buildDesktopContent(),
      ),
    );
  }

  // ============================================================
  // MOBILE CONTENT
  // ============================================================
  Widget _buildMobileContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildJobHeader(),
        const SizedBox(height: 12),
        _buildDescription(),
        const SizedBox(height: 12),
        _buildLocation(),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildPrice(),
            _buildBadge(),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // DESKTOP CONTENT
  // ============================================================
  Widget _buildDesktopContent() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.mint.withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.work_outline_rounded,
            color: AppColors.primaryTeal,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.job.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.headingSmall.copyWith(fontSize: 17),
              ),
              const SizedBox(height: 6),
              _buildDescription(maxLines: 2),
              const SizedBox(height: 8),
              _buildLocation(),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildPrice(),
            const SizedBox(height: 8),
            _buildBadge(),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // PARTS
  // ============================================================
  Widget _buildJobHeader() {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.mint.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.work_outline_rounded,
            color: AppColors.primaryTeal,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            widget.job.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.headingSmall.copyWith(fontSize: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildDescription({int maxLines = 3}) {
    return Text(
      widget.job.description,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      style: AppTextStyles.bodyOnLight.copyWith(
        fontSize: 13.5,
        height: 1.6,
      ),
    );
  }

  Widget _buildLocation() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.location_on_outlined,
          size: 14,
          color: AppColors.grey500,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            widget.job.location ?? 'Lokasi tidak tersedia',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySmallOnLight.copyWith(
              fontSize: 12,
              color: AppColors.grey600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrice() {
    return Text(
      widget.job.price,
      style: AppTextStyles.headingSmall.copyWith(
        fontSize: 16,
        color: AppColors.primaryTeal,
      ),
    );
  }

  Widget _buildBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.mint.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.primaryTeal,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Mencari Mitra',
            style: AppTextStyles.labelOnDark.copyWith(
              color: AppColors.primaryTeal,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}