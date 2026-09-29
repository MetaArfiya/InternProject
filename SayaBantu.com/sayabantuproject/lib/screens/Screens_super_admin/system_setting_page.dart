import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/api_service.dart';

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
  // DESIGN TOKENS
  // ============================================================

  static const Color _accent = Color(0xFFF04444);
  static const Color _bg = Color(0xFFF5F7FB);
  static const Color _border = Color(0xFFE5E7EB);
  static const Color _darkText = Color(0xFF0F172A);
  static const Color _mutedText = Color(0xFF64748B);

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
  final TextEditingController _cancelPointController = TextEditingController();
  final TextEditingController _ratingBonusController = TextEditingController();
  final TextEditingController _commissionController = TextEditingController();

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
              _commissionController.text = _formatCommissionInput(commission);
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
    _commissionController.text = _formatCommissionInput(_defaultCommission);
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
          color: _bg,
          child: RefreshIndicator(
            onRefresh: _loadSettings,
            color: _accent,
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
                      _buildPageHeader(isMobile),
                      SizedBox(height: isMobile ? 18 : 24),

                      if (_isLoading)
                        _buildLoading()
                      else if (_errorMessage != null)
                        _buildError()
                      else ...[
                        _buildMainContent(isMobile: isMobile),
                        SizedBox(height: isMobile ? 16 : 20),
                        _buildActionButtons(isMobile),
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
  // MAIN CONTENT — 2 kolom di web, stack di mobile
  // ============================================================

  Widget _buildMainContent({required bool isMobile}) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPointSettingsCard(),
          const SizedBox(height: 16),
          _buildCommissionCard(),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildPointSettingsCard()),
        const SizedBox(width: 16),
        Expanded(child: _buildCommissionCard()),
      ],
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildPageHeader(bool isMobile) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: isMobile ? 42 : 48,
          height: isMobile ? 42 : 48,
          decoration: BoxDecoration(
            color: _accent.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.settings_outlined,
            color: _accent,
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
                  color: _darkText,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Konfigurasi aturan poin dan komisi platform',
                style: TextStyle(
                  fontSize: isMobile ? 12.5 : 13,
                  color: _mutedText,
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
  Widget _buildLoading() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: const Column(
        children: [
          CircularProgressIndicator(color: _accent),
          SizedBox(height: 16),
          Text(
            'Mengambil konfigurasi sistem...',
            style: TextStyle(color: _mutedText, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================
  Widget _buildError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline,
            size: 48,
            color: Color(0xFFDC2626),
          ),
          const SizedBox(height: 12),
          const Text(
            'Gagal mengambil pengaturan sistem',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF7F1D1D),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? '',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF991B1B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: _loadSettings,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
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
  Widget _buildPointSettingsCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCardTitle(
            icon: Icons.emoji_events_outlined,
            iconColor: const Color(0xFFF59E0B),
            title: 'Aturan Poin Mitra',
            subtitle: 'Konfigurasi poin reward & penalti',
          ),
          const SizedBox(height: 18),
          _buildPointSetting(
            icon: Icons.check_circle_outline,
            iconColor: const Color(0xFF00A86B),
            title: 'Poin per pekerjaan selesai',
            controller: _jobPointController,
            suffix: 'poin',
            borderColor: const Color(0xFF9DE7D1),
            textColor: const Color(0xFF00A86B),
          ),
          const SizedBox(height: 14),
          _buildPointSetting(
            icon: Icons.cancel_outlined,
            iconColor: const Color(0xFFEF4444),
            title: 'Poin dipotong jika dibatalkan',
            controller: _cancelPointController,
            suffix: 'poin',
            borderColor: const Color(0xFFFFB5B5),
            textColor: const Color(0xFFEF4444),
          ),
          const SizedBox(height: 14),
          _buildPointSetting(
            icon: Icons.star_outline,
            iconColor: const Color(0xFFF59E0B),
            title: 'Bonus poin rating ≥ 4.8',
            controller: _ratingBonusController,
            suffix: 'poin',
            borderColor: const Color(0xFFFFD89A),
            textColor: const Color(0xFFF59E0B),
          ),
          const SizedBox(height: 18),
          _buildPointSummary(),
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
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 17, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: Color(0xFF334155),
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
                fillColor: Colors.white,
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
            style: const TextStyle(
              fontSize: 11.5,
              color: _mutedText,
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
  Widget _buildPointSummary() {
    final int jobPoint = _parseIntValue(_jobPointController);
    final int cancelPoint = _parseIntValue(_cancelPointController);
    final int ratingBonus = _parseIntValue(_ratingBonusController);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ringkasan Sistem Poin',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: _darkText,
            ),
          ),
          const SizedBox(height: 10),
          _buildSummaryRow(
            icon: Icons.check_circle,
            iconColor: const Color(0xFF00A86B),
            label: 'Selesai kerja',
            value: '+$jobPoint poin',
            valueColor: const Color(0xFF00A86B),
          ),
          const SizedBox(height: 6),
          _buildSummaryRow(
            icon: Icons.cancel,
            iconColor: const Color(0xFFEF4444),
            label: 'Batalkan',
            value: '-$cancelPoint poin',
            valueColor: const Color(0xFFEF4444),
          ),
          const SizedBox(height: 6),
          _buildSummaryRow(
            icon: Icons.star,
            iconColor: const Color(0xFFF59E0B),
            label: 'Bonus rating',
            value: '+$ratingBonus poin',
            valueColor: const Color(0xFFF59E0B),
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
  }) {
    return Row(
      children: [
        Icon(icon, size: 15, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: _mutedText),
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
  Widget _buildCommissionCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCardTitle(
            icon: Icons.payments_outlined,
            iconColor: const Color(0xFF0EA5E9),
            title: 'Aturan Komisi Platform',
            subtitle: 'Persentase komisi per transaksi',
          ),
          const SizedBox(height: 18),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _border),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0EA5E9).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.percent,
                    size: 17,
                    color: Color(0xFF0EA5E9),
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Komisi SiapBantu per transaksi',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF334155),
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
                    keyboardType: const TextInputType.numberWithOptions(
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
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0EA5E9),
                    ),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 8,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Color(0xFF9DDDF8),
                          width: 1.2,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Color(0xFF9DDDF8),
                          width: 1.2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Color(0xFF0EA5E9),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  '%',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: _mutedText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          _buildSimulationPreview(),
        ],
      ),
    );
  }

  // ============================================================
  // SIMULATION
  // ============================================================
  Widget _buildSimulationPreview() {
    final double commissionPercent = _parseCommission();
    const int transaction = 200000;
    final int commission = (transaction * commissionPercent / 100).round();
    final int partnerReceive = transaction - commission;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.calculate_outlined,
                size: 15,
                color: _mutedText,
              ),
              SizedBox(width: 6),
              Text(
                'Preview Simulasi',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: _darkText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildSimulationRow(
            'Transaksi',
            'Rp 200.000',
            const Color(0xFF64748B),
          ),
          const SizedBox(height: 6),
          _buildSimulationRow(
            'Komisi platform',
            'Rp ${_formatCurrency(commission)}',
            const Color(0xFF0EA5E9),
          ),
          const SizedBox(height: 6),
          _buildSimulationRow(
            'Mitra terima',
            'Rp ${_formatCurrency(partnerReceive)}',
            const Color(0xFF00A86B),
          ),
        ],
      ),
    );
  }

  Widget _buildSimulationRow(
    String label,
    String value,
    Color valueColor,
  ) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: _mutedText),
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
  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
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
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
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
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _darkText,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: _mutedText,
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
  Widget _buildActionButtons(bool isMobile) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSaveButton(),
          const SizedBox(height: 10),
          _buildResetButton(),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _buildResetButton(),
        const SizedBox(width: 10),
        _buildSaveButton(),
      ],
    );
  }

  // ============================================================
  // SAVE BUTTON
  // ============================================================
  Widget _buildSaveButton() {
    return SizedBox(
      height: 46,
      child: ElevatedButton.icon(
        onPressed: (_isSaving || _isResetting) ? null : _saveConfiguration,
        icon: _isSaving
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
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
          backgroundColor: _accent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFFCA5A5),
          disabledForegroundColor: Colors.white,
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
  Widget _buildResetButton() {
    return SizedBox(
      height: 46,
      child: OutlinedButton.icon(
        onPressed: (_isSaving || _isResetting) ? null : _resetConfiguration,
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
          foregroundColor: _mutedText,
          backgroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          side: const BorderSide(color: _border),
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
    final int jobPoint = _parseIntValue(_jobPointController);
    final int cancelPoint = _parseIntValue(_cancelPointController);
    final int ratingBonus = _parseIntValue(_ratingBonusController);
    final double commission = _parseCommission();

    if (jobPoint < 0 || cancelPoint < 0 || ratingBonus < 0) {
      _showMessage('Nilai poin tidak boleh negatif.', isError: true);
      return;
    }

    if (jobPoint > _maxPointValue ||
        cancelPoint > _maxPointValue ||
        ratingBonus > _maxPointValue) {
      _showMessage('Nilai poin maksimal $_maxPointValue.', isError: true);
      return;
    }

    if (commission < 0 || commission > 100) {
      _showMessage(
        'Komisi platform harus berada antara 0 sampai 100%.',
        isError: true,
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
        _showMessage(message);
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
      _showMessage(message, isError: true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showMessage('Terjadi kesalahan: $e', isError: true);
    }
  }

  // ============================================================
  // RESET CONFIGURATION
  // ============================================================
  Future<void> _resetConfiguration() async {
    if (!mounted) return;

    setState(() {
      _isResetting = true;
      _jobPointController.text = _defaultJobPoint.toString();
      _cancelPointController.text = _defaultCancelPoint.toString();
      _ratingBonusController.text = _defaultRatingBonus.toString();
      _commissionController.text = _formatCommissionInput(_defaultCommission);
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
        _showMessage('Konfigurasi dikembalikan ke default.');
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
        _showMessage(message, isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isResetting = false);
      _showMessage('Terjadi kesalahan: $e', isError: true);
      await _loadSettings();
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================
  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}