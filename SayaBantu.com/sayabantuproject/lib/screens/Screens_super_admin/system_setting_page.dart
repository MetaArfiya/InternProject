import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/api_service.dart';
import '../../theme/admin_theme.dart';
import '../../theme/admin_theme_provider.dart';
import '../../theme/app_colors.dart';

// ============================================================
// INPUT FORMATTER: BILANGAN BULAT DENGAN RENTANG
// ============================================================
class _IntRangeFormatter extends TextInputFormatter {
  final int min;
  final int max;

  const _IntRangeFormatter({
    required this.min,
    required this.max,
  });

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String text = newValue.text;

    if (text.isEmpty) return newValue;

    if (!RegExp(r'^\d+$').hasMatch(text)) return oldValue;
    if (text.length > 1 && text.startsWith('0')) return oldValue;

    final int? value = int.tryParse(text);
    if (value == null) return oldValue;
    if (value < min || value > max) return oldValue;

    return newValue;
  }
}

// ============================================================
// INPUT FORMATTER: DESIMAL DENGAN RENTANG & MAX DESIMAL
// ============================================================
class _DecimalRangeFormatter extends TextInputFormatter {
  final double min;
  final double max;
  final int maxDecimals;

  const _DecimalRangeFormatter({
    required this.min,
    required this.max,
    this.maxDecimals = 2,
  });

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String text = newValue.text;

    if (text.isEmpty) return newValue;

    final RegExp pattern = RegExp(
      r'^\d{1,3}([.,]\d{0,' + maxDecimals.toString() + r'})?$',
    );

    if (!pattern.hasMatch(text)) return oldValue;

    if (text.length > 1 &&
        text.startsWith('0') &&
        !RegExp(r'^0[.,]').hasMatch(text)) {
      return oldValue;
    }

    final String normalized = text.replaceAll(',', '.');
    final double? parsed = double.tryParse(normalized);
    if (parsed == null) return oldValue;
    if (parsed < min || parsed > max) return oldValue;

    return newValue;
  }
}

class SystemSettingsPage extends StatefulWidget {
  const SystemSettingsPage({super.key});

  @override
  State<SystemSettingsPage> createState() => _SystemSettingsPageState();
}

class _SystemSettingsPageState extends State<SystemSettingsPage> {
  // ============================================================
  // THEME
  // ============================================================

  AdminTheme get theme => AdminThemeProvider.of(context);

  // ============================================================
  // BREAKPOINTS
  // ============================================================

  static const double _mobileBreakpoint = 700;
  static const double _tabletBreakpoint = 1100;

  // ============================================================
  // LIMITS
  // ============================================================

  static const int _maxPointValue = 999;
  static const double _maxCommissionValue = 100.0;

  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController _jobPointController = TextEditingController();
  final TextEditingController _cancelPointController =
      TextEditingController();
  final TextEditingController _ratingBonusController =
      TextEditingController();
  final TextEditingController _commissionController =
      TextEditingController();

  // ============================================================
  // DEFAULT VALUES
  // ============================================================

  static const int _defaultJobPoint = 10;
  static const int _defaultCancelPoint = 5;
  static const int _defaultRatingBonus = 3;
  static const double _defaultCommission = 15.0;

  // ============================================================
  // STATE
  // ============================================================

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isResetting = false;
  String? _errorMessage;

  // ============================================================
  // INIT / DISPOSE
  // ============================================================

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _jobPointController.dispose();
    _cancelPointController.dispose();
    _ratingBonusController.dispose();
    _commissionController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD SETTINGS
  // ============================================================

  Future<void> _loadSettings() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.get('/superadmin/system-settings');

      if (!mounted) return;

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);

        if (body['success'] == true) {
          final data = body['data'];

          if (data != null) {
            final int jobPoint = int.tryParse(
                  data['points_on_completion']?.toString() ?? '',
                ) ??
                _defaultJobPoint;

            final int cancelPoint = int.tryParse(
                  data['points_on_cancellation']?.toString() ?? '',
                ) ??
                _defaultCancelPoint;

            final int ratingBonus = int.tryParse(
                  data['points_bonus_rating']?.toString() ?? '',
                ) ??
                _defaultRatingBonus;

            final double commission = double.tryParse(
                  data['platform_commission_percent']
                          ?.toString()
                          .replaceAll(',', '.') ??
                      '',
                ) ??
                _defaultCommission;

            setState(() {
              _jobPointController.text = jobPoint.toString();
              _cancelPointController.text = cancelPoint.toString();
              _ratingBonusController.text = ratingBonus.toString();
              _commissionController.text =
                  _formatCommissionInput(commission);
              _isLoading = false;
            });
          } else {
            _setDefaultValues();
            setState(() => _isLoading = false);
          }
        } else {
          setState(() {
            _errorMessage =
                body['message'] ?? 'Gagal mengambil pengaturan sistem.';
            _isLoading = false;
          });
        }
      } else {
        String message = 'Gagal mengambil pengaturan sistem.';
        try {
          final body = jsonDecode(response.body);
          if (body['message'] != null) {
            message = body['message'].toString();
          }
        } catch (_) {}
        setState(() {
          _errorMessage = '$message\nStatus: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Tidak dapat terhubung ke server.\n$e';
        _isLoading = false;
      });
    }
  }

  // ============================================================
  // DEFAULT VALUES
  // ============================================================

  void _setDefaultValues() {
    _jobPointController.text = _defaultJobPoint.toString();
    _cancelPointController.text = _defaultCancelPoint.toString();
    _ratingBonusController.text = _defaultRatingBonus.toString();
    _commissionController.text =
        _formatCommissionInput(_defaultCommission);
  }

  // ============================================================
  // PARSE HELPERS
  // ============================================================

  int _parseIntValue(TextEditingController controller) {
    return int.tryParse(controller.text.trim()) ?? 0;
  }

  double _parseCommission() {
    final String value =
        _commissionController.text.trim().replaceAll(',', '.');
    return double.tryParse(value) ?? 0.0;
  }

  String _formatCommissionInput(double value) {
    return value.toStringAsFixed(2);
  }

  String _formatCurrency(int value) {
    final String text = value.toString();
    final StringBuffer result = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      if (i > 0 && (text.length - i) % 3 == 0) {
        result.write('.');
      }
      result.write(text[i]);
    }

    return result.toString();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isMobile = width < _mobileBreakpoint;
        final isTablet =
            width >= _mobileBreakpoint && width < _tabletBreakpoint;

        final horizontalPadding =
            isMobile ? 16.0 : (isTablet ? 24.0 : 32.0);
        final verticalPadding = isMobile ? 16.0 : 28.0;

        return Container(
          width: double.infinity,
          height: double.infinity,
          color: t.bg,
          child: RefreshIndicator(
            onRefresh: _loadSettings,
            color: t.accent,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPageHeader(isMobile, t),
                      SizedBox(height: isMobile ? 18 : 24),

                      if (_isLoading)
                        _buildLoading(t)
                      else if (_errorMessage != null)
                        _buildError(t)
                      else ...[
                        _buildMainContent(
                          isMobile: isMobile,
                          t: t,
                        ),
                        SizedBox(height: isMobile ? 16 : 20),
                        _buildActionButtons(isMobile, t),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // MAIN CONTENT
  // ============================================================

  Widget _buildMainContent({
    required bool isMobile,
    required AdminTheme t,
  }) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPointSettingsCard(t),
          const SizedBox(height: 16),
          _buildCommissionCard(t),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildPointSettingsCard(t)),
        const SizedBox(width: 16),
        Expanded(child: _buildCommissionCard(t)),
      ],
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildPageHeader(bool isMobile, AdminTheme t) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: isMobile ? 42 : 48,
          height: isMobile ? 42 : 48,
          decoration: BoxDecoration(
            color: t.accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.settings_outlined,
            color: t.accent,
            size: isMobile ? 22 : 26,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pengaturan Sistem',
                style: TextStyle(
                  fontSize: isMobile ? 22 : 26,
                  fontWeight: FontWeight.w700,
                  color: t.cellText,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Konfigurasi aturan poin dan komisi platform',
                style: TextStyle(
                  fontSize: isMobile ? 12.5 : 13,
                  color: t.mutedText,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // LOADING
  // ============================================================

  Widget _buildLoading(AdminTheme t) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.border),
      ),
      child: Column(
        children: [
          CircularProgressIndicator(color: t.accent),
          const SizedBox(height: 16),
          Text(
            'Mengambil konfigurasi sistem...',
            style: TextStyle(color: t.mutedText, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildError(AdminTheme t) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: t.danger.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.danger.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: t.danger,
          ),
          const SizedBox(height: 12),
          Text(
            'Gagal mengambil pengaturan sistem',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: t.danger,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? '',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: t.danger,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: _loadSettings,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: t.accent,
              foregroundColor: AppColors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // POINT SETTINGS CARD
  // ============================================================

  Widget _buildPointSettingsCard(AdminTheme t) {
    return _buildCard(
      t: t,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCardTitle(
            icon: Icons.emoji_events_outlined,
            iconColor: t.accent,
            title: 'Aturan Poin Mitra',
            subtitle: 'Konfigurasi poin reward & penalti',
            t: t,
          ),
          const SizedBox(height: 18),
          _buildPointSetting(
            icon: Icons.check_circle_outline,
            iconColor: t.accent,
            title: 'Poin per pekerjaan selesai',
            controller: _jobPointController,
            suffix: 'poin',
            borderColor: t.accent.withValues(alpha: 0.35),
            textColor: t.accent,
            t: t,
          ),
          const SizedBox(height: 14),
          _buildPointSetting(
            icon: Icons.cancel_outlined,
            iconColor: t.danger,
            title: 'Poin dipotong jika dibatalkan',
            controller: _cancelPointController,
            suffix: 'poin',
            borderColor: t.danger.withValues(alpha: 0.35),
            textColor: t.danger,
            t: t,
          ),
          const SizedBox(height: 14),
          _buildPointSetting(
            icon: Icons.star_outline,
            iconColor: t.accent,
            title: 'Bonus poin rating ≥ 4.8',
            controller: _ratingBonusController,
            suffix: 'poin',
            borderColor: t.accent.withValues(alpha: 0.35),
            textColor: t.accent,
            t: t,
          ),
          const SizedBox(height: 18),
          _buildPointSummary(t),
        ],
      ),
    );
  }

  // ============================================================
  // POINT SETTING ITEM
  // ============================================================

  Widget _buildPointSetting({
    required IconData icon,
    required Color iconColor,
    required String title,
    required TextEditingController controller,
    required String suffix,
    required Color borderColor,
    required Color textColor,
    required AdminTheme t,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: t.border),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 17, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: t.cellText,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 64,
            height: 40,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              enabled: !_isSaving && !_isResetting,
              inputFormatters: const [
                _IntRangeFormatter(min: 0, max: _maxPointValue),
              ],
              onChanged: (_) => setState(() {}),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 8,
                ),
                filled: true,
                fillColor: AppColors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: borderColor, width: 1.2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: textColor, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            suffix,
            style: TextStyle(
              fontSize: 11.5,
              color: t.mutedText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // POINT SUMMARY
  // ============================================================

  Widget _buildPointSummary(AdminTheme t) {
    final int jobPoint = _parseIntValue(_jobPointController);
    final int cancelPoint = _parseIntValue(_cancelPointController);
    final int ratingBonus = _parseIntValue(_ratingBonusController);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ringkasan Sistem Poin',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: t.cellText,
            ),
          ),
          const SizedBox(height: 10),
          _buildSummaryRow(
            icon: Icons.check_circle,
            iconColor: t.accent,
            label: 'Selesai kerja',
            value: '+$jobPoint poin',
            valueColor: t.accent,
            t: t,
          ),
          const SizedBox(height: 6),
          _buildSummaryRow(
            icon: Icons.cancel,
            iconColor: t.danger,
            label: 'Batalkan',
            value: '-$cancelPoint poin',
            valueColor: t.danger,
            t: t,
          ),
          const SizedBox(height: 6),
          _buildSummaryRow(
            icon: Icons.star,
            iconColor: t.accent,
            label: 'Bonus rating',
            value: '+$ratingBonus poin',
            valueColor: t.accent,
            t: t,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required Color valueColor,
    required AdminTheme t,
  }) {
    return Row(
      children: [
        Icon(icon, size: 15, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 12, color: t.mutedText),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // COMMISSION CARD
  // ============================================================

  Widget _buildCommissionCard(AdminTheme t) {
    return _buildCard(
      t: t,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCardTitle(
            icon: Icons.payments_outlined,
            iconColor: t.accent,
            title: 'Aturan Komisi Platform',
            subtitle: 'Persentase komisi per transaksi',
            t: t,
          ),
          const SizedBox(height: 18),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.grey50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: t.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: t.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.percent,
                    size: 17,
                    color: t.accent,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Komisi SiapBantu per transaksi',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: t.cellText,
                      height: 1.35,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 64,
                  height: 40,
                  child: TextField(
                    controller: _commissionController,
                    keyboardType:
                        const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textAlign: TextAlign.center,
                    enabled: !_isSaving && !_isResetting,
                    inputFormatters: const [
                      _DecimalRangeFormatter(
                        min: 0,
                        max: _maxCommissionValue,
                        maxDecimals: 2,
                      ),
                    ],
                    onChanged: (_) => setState(() {}),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: t.accent,
                    ),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 8,
                      ),
                      filled: true,
                      fillColor: AppColors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: t.accent.withValues(alpha: 0.35),
                          width: 1.2,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: t.accent.withValues(alpha: 0.35),
                          width: 1.2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: t.accent,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '%',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: t.mutedText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          _buildSimulationPreview(t),
        ],
      ),
    );
  }

  // ============================================================
  // SIMULATION
  // ============================================================

  Widget _buildSimulationPreview(AdminTheme t) {
    final double commissionPercent = _parseCommission();
    const int transaction = 200000;
    final int commission = (transaction * commissionPercent / 100).round();
    final int partnerReceive = transaction - commission;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calculate_outlined,
                size: 15,
                color: t.mutedText,
              ),
              const SizedBox(width: 6),
              Text(
                'Preview Simulasi',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: t.cellText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildSimulationRow(
            'Transaksi',
            'Rp 200.000',
            t.mutedText,
            t,
          ),
          const SizedBox(height: 6),
          _buildSimulationRow(
            'Komisi platform',
            'Rp ${_formatCurrency(commission)}',
            t.accent,
            t,
          ),
          const SizedBox(height: 6),
          _buildSimulationRow(
            'Mitra terima',
            'Rp ${_formatCurrency(partnerReceive)}',
            t.accent,
            t,
          ),
        ],
      ),
    );
  }

  Widget _buildSimulationRow(
    String label,
    String value,
    Color valueColor,
    AdminTheme t,
  ) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 12, color: t.mutedText),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // CARD
  // ============================================================

  Widget _buildCard({required Widget child, required AdminTheme t}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.border),
      ),
      child: child,
    );
  }

  // ============================================================
  // CARD TITLE
  // ============================================================

  Widget _buildCardTitle({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required AdminTheme t,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: t.cellText,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11.5,
                  color: t.mutedText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ACTION BUTTONS
  // ============================================================

  Widget _buildActionButtons(bool isMobile, AdminTheme t) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSaveButton(t),
          const SizedBox(height: 10),
          _buildResetButton(t),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _buildResetButton(t),
        const SizedBox(width: 10),
        _buildSaveButton(t),
      ],
    );
  }

  // ============================================================
  // SAVE BUTTON
  // ============================================================

  Widget _buildSaveButton(AdminTheme t) {
    return SizedBox(
      height: 46,
      child: ElevatedButton.icon(
        onPressed:
            (_isSaving || _isResetting) ? null : _saveConfiguration,
        icon: _isSaving
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.white,
                ),
              )
            : const Icon(Icons.save_outlined, size: 18),
        label: Text(
          _isSaving ? 'Menyimpan...' : 'Simpan Konfigurasi',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: t.accent,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: t.accent.withValues(alpha: 0.4),
          disabledForegroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  // ============================================================
  // RESET BUTTON
  // ============================================================

  Widget _buildResetButton(AdminTheme t) {
    return SizedBox(
      height: 46,
      child: OutlinedButton.icon(
        onPressed:
            (_isSaving || _isResetting) ? null : _resetConfiguration,
        icon: _isResetting
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.restore, size: 18),
        label: Text(
          _isResetting ? 'Mereset...' : 'Reset ke Default',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: t.mutedText,
          backgroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          side: BorderSide(color: t.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SAVE CONFIGURATION
  // ============================================================

  Future<void> _saveConfiguration() async {
    final t = theme;
    final int jobPoint = _parseIntValue(_jobPointController);
    final int cancelPoint = _parseIntValue(_cancelPointController);
    final int ratingBonus = _parseIntValue(_ratingBonusController);
    final double commission = _parseCommission();

    if (jobPoint < 0 || cancelPoint < 0 || ratingBonus < 0) {
      _showMessage('Nilai poin tidak boleh negatif.', isError: true, t: t);
      return;
    }

    if (jobPoint > _maxPointValue ||
        cancelPoint > _maxPointValue ||
        ratingBonus > _maxPointValue) {
      _showMessage(
        'Nilai poin maksimal $_maxPointValue.',
        isError: true,
        t: t,
      );
      return;
    }

    if (commission < 0 || commission > 100) {
      _showMessage(
        'Komisi platform harus berada antara 0 sampai 100%.',
        isError: true,
        t: t,
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isSaving = true);

    try {
      final response = await ApiService.put(
        '/superadmin/system-settings',
        {
          'points_on_completion': jobPoint,
          'points_on_cancellation': cancelPoint,
          'points_bonus_rating': ratingBonus,
          'platform_commission_percent': commission,
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        String message = 'Konfigurasi sistem berhasil disimpan.';
        try {
          final body = jsonDecode(response.body);
          if (body['message'] != null) {
            message = body['message'].toString();
          }
        } catch (_) {}

        setState(() => _isSaving = false);
        _showMessage(message, t: t);
        await _loadSettings();
        return;
      }

      String message = 'Gagal menyimpan konfigurasi.';
      try {
        final body = jsonDecode(response.body);
        if (body['message'] != null) {
          message = body['message'].toString();
        }
      } catch (_) {}

      setState(() => _isSaving = false);
      _showMessage(message, isError: true, t: t);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showMessage('Terjadi kesalahan: $e', isError: true, t: t);
    }
  }

  // ============================================================
  // RESET CONFIGURATION
  // ============================================================

  Future<void> _resetConfiguration() async {
    if (!mounted) return;
    final t = theme;

    setState(() {
      _isResetting = true;
      _jobPointController.text = _defaultJobPoint.toString();
      _cancelPointController.text = _defaultCancelPoint.toString();
      _ratingBonusController.text = _defaultRatingBonus.toString();
      _commissionController.text =
          _formatCommissionInput(_defaultCommission);
    });

    try {
      final response = await ApiService.put(
        '/superadmin/system-settings',
        {
          'points_on_completion': _defaultJobPoint,
          'points_on_cancellation': _defaultCancelPoint,
          'points_bonus_rating': _defaultRatingBonus,
          'platform_commission_percent': _defaultCommission,
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() => _isResetting = false);
        _showMessage('Konfigurasi dikembalikan ke default.', t: t);
        await _loadSettings();
      } else {
        String message = 'Gagal mereset konfigurasi.';
        try {
          final body = jsonDecode(response.body);
          if (body['message'] != null) {
            message = body['message'].toString();
          }
        } catch (_) {}

        setState(() => _isResetting = false);
        _showMessage(message, isError: true, t: t);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isResetting = false);
      _showMessage('Terjadi kesalahan: $e', isError: true, t: t);
      await _loadSettings();
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message, {
    bool isError = false,
    required AdminTheme t,
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? t.danger : t.accent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}