import 'package:flutter/material.dart';

import '../models/job_model.dart';
import '../models/offer_model.dart';
import '../theme/app_colors.dart';

class OfferCard extends StatelessWidget {
  final JobModel job;
  final OfferModel offer;
  final bool canRespond;
  final Function(OfferModel) onReject;
  final Function(OfferModel) onAccept;
  final Function(OfferModel) onOpenProfile;

  const OfferCard({
    super.key,
    required this.job,
    required this.offer,
    this.canRespond = true,
    required this.onReject,
    required this.onAccept,
    required this.onOpenProfile,
  });

  static const Color _green = Color(0xFF16A34A);
  static const Color _red = Color(0xFFDC2626);

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.width < 500;

    final borderColor = offer.isAccepted
        ? _green
        : offer.isRejected
            ? const Color(0xFFFCA5A5)
            : AppColors.primaryTeal.withValues(alpha: 0.15);

    final backgroundColor = offer.isAccepted
        ? const Color(0xFFF0FDF4)
        : offer.isRejected
            ? const Color(0xFFFEF2F2)
            : AppColors.white;

    return Container(
      padding: EdgeInsets.all(isCompact ? 14 : 22),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(isCompact ? 14 : 18),
        border: Border.all(
          color: borderColor,
          width: offer.isAccepted ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!offer.isPending) ...[
            _buildStateBanner(),
            const SizedBox(height: 14),
          ],
          if (isCompact)
            _buildCompactContent(context)
          else
            _buildWideContent(context),
        ],
      ),
    );
  }

  // ============================================================
  // INFORMASI MITRA
  // ============================================================

  Widget _buildPartnerInfo({double avatarRadius = 26}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: avatarRadius,
          backgroundColor: offer.isAccepted
              ? const Color(0xFFDCFCE7)
              : AppColors.mint.withValues(alpha: 0.20),
          child: Icon(
            Icons.person,
            color: offer.isAccepted ? _green : AppColors.primaryTeal,
            size: avatarRadius + 2,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                offer.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.grey900,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 10,
                runSpacing: 6,
                children: [
                  if (offer.verified)
                    const _InfoChip(
                      icon: Icons.verified,
                      label: 'Terverifikasi',
                      color: _green,
                    ),
                  _InfoChip(
                    icon: Icons.work_outline,
                    label: '${offer.jobsCompleted} Job',
                    color: AppColors.grey600,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // INFORMASI JADWAL DAN DURASI
  // ============================================================

  Widget _buildScheduleInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.sectionAltLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Jadwal yang diajukan Mitra',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.grey700,
            ),
          ),
          const SizedBox(height: 10),
          _scheduleRow(
            Icons.calendar_month_outlined,
            'Mulai',
            offer.proposedStartAtText,
          ),
          const SizedBox(height: 8),
          _scheduleRow(
            Icons.schedule,
            'Estimasi durasi',
            offer.estimatedDurationText,
          ),
        ],
      ),
    );
  }

  Widget _scheduleRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.primaryTeal),
        const SizedBox(width: 8),
        SizedBox(
          width: 105,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.grey600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.grey900,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // MOBILE
  // ============================================================

  Widget _buildCompactContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPartnerInfo(),
        const SizedBox(height: 16),
        Text(
          offer.price,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: offer.isAccepted ? _green : AppColors.primaryTeal,
          ),
        ),
        const SizedBox(height: 14),
        _buildScheduleInfo(),
        const SizedBox(height: 14),
        _buildActions(context, compact: true),
      ],
    );
  }

  // ============================================================
  // DESKTOP / WIDE
  // ============================================================

  Widget _buildWideContent(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPartnerInfo(avatarRadius: 32),
              const SizedBox(height: 16),
              Text(
                offer.price,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: offer.isAccepted ? _green : AppColors.primaryTeal,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          flex: 5,
          child: _buildScheduleInfo(),
        ),
        const SizedBox(width: 20),
        _buildActions(context, compact: false),
      ],
    );
  }

  // ============================================================
  // ACTIONS
  // ============================================================

  Widget _buildActions(
    BuildContext context, {
    required bool compact,
  }) {
    final width = compact ? double.infinity : 130.0;

    if (offer.isAccepted) {
      return Column(
        children: [
          Container(
            width: width,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _green,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Text(
              'TERPILIH',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () => onOpenProfile(offer),
            child: const Text('Lihat Profil'),
          ),
        ],
      );
    }

    if (offer.isRejected) {
      return Column(
        children: [
          Container(
            width: width,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Text(
              'DITOLAK',
              style: TextStyle(
                color: _red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () => onOpenProfile(offer),
            child: const Text('Lihat Profil'),
          ),
        ],
      );
    }

    return SizedBox(
      width: width,
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: canRespond
                  ? () => _showAcceptDialog(context)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.grey200,
                minimumSize: const Size(0, 42),
              ),
              child: const Text('Terima'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: canRespond
                  ? () => _showRejectDialog(context)
                  : null,
              style: OutlinedButton.styleFrom(
                foregroundColor: _red,
                minimumSize: const Size(0, 42),
                side: const BorderSide(color: _red),
              ),
              child: const Text('Tolak'),
            ),
          ),
          TextButton(
            onPressed: () => onOpenProfile(offer),
            child: const Text('Lihat Profil'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DIALOG TERIMA
  // ============================================================

  void _showAcceptDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Konfirmasi Penawaran'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Anda akan memilih ${offer.name} sebagai mitra.'),
              const SizedBox(height: 16),
              Text(
                'Harga: ${offer.price}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildScheduleInfo(),
              const SizedBox(height: 12),
              const Text(
                'Jadwal dan durasi di atas merupakan usulan Mitra. '
                'Pastikan sesuai sebelum menerima penawaran.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.grey600,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              onAccept(offer);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryTeal,
              foregroundColor: Colors.white,
            ),
            child: const Text('Ya, Pilih'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DIALOG TOLAK
  // ============================================================

  void _showRejectDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Tolak Penawaran'),
        content: Text(
          'Yakin ingin menolak penawaran dari ${offer.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              onReject(offer);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Tolak'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATUS BANNER
  // ============================================================

  Widget _buildStateBanner() {
    final accepted = offer.isAccepted;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: accepted
            ? const Color(0xFFDCFCE7)
            : const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            accepted ? Icons.check_circle : Icons.cancel,
            color: accepted ? _green : _red,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              accepted
                  ? 'Mitra ini sudah Anda pilih.'
                  : 'Penawaran ini sudah ditolak.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: accepted ? _green : _red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
