import 'dart:convert';

import 'package:flutter/material.dart';

import '../../services/api_service.dart';

class SystemSettingsPage extends StatefulWidget {
  const SystemSettingsPage({super.key});

  @override
  State<SystemSettingsPage> createState() =>
      _SystemSettingsPageState();
}

class _SystemSettingsPageState
    extends State<SystemSettingsPage> {
  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController _jobPointController =
      TextEditingController();

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

  // Komisi menggunakan double karena database decimal
  static const double _defaultCommission = 15.0;

  // ============================================================
  // STATE
  // ============================================================

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isResetting = false;

  String? _errorMessage;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _loadSettings();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _jobPointController.dispose();
    _cancelPointController.dispose();
    _ratingBonusController.dispose();
    _commissionController.dispose();

    super.dispose();
  }

  // ============================================================
  // LOAD DATABASE
  // ============================================================

  Future<void> _loadSettings() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.get(
        '/superadmin/system-settings',
      );

      debugPrint(
        '📥 SYSTEM SETTINGS: ${response.body}',
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);

        if (body['success'] == true) {
          final data = body['data'];

          if (data != null) {
            // ==================================================
            // POINT
            // ==================================================

            final int jobPoint =
                int.tryParse(
                      data['points_on_completion']
                          ?.toString() ??
                          '',
                    ) ??
                    _defaultJobPoint;

            final int cancelPoint =
                int.tryParse(
                      data['points_on_cancellation']
                          ?.toString() ??
                          '',
                    ) ??
                    _defaultCancelPoint;

            final int ratingBonus =
                int.tryParse(
                      data['points_bonus_rating']
                          ?.toString() ??
                          '',
                    ) ??
                    _defaultRatingBonus;

            // ==================================================
            // COMMISSION
            // ==================================================

            final double commission =
                double.tryParse(
                      data['platform_commission_percent']
                              ?.toString()
                              .replaceAll(',', '.') ??
                          '',
                    ) ??
                    _defaultCommission;

            setState(() {
              _jobPointController.text =
                  jobPoint.toString();

              _cancelPointController.text =
                  cancelPoint.toString();

              _ratingBonusController.text =
                  ratingBonus.toString();

              _commissionController.text =
                  _formatCommissionInput(
                commission,
              );

              _isLoading = false;
            });

            debugPrint(
              '💰 COMMISSION DARI DATABASE: $commission',
            );
          } else {
            _setDefaultValues();

            setState(() {
              _isLoading = false;
            });
          }
        } else {
          setState(() {
            _errorMessage =
                body['message'] ??
                    'Gagal mengambil pengaturan sistem.';

            _isLoading = false;
          });
        }
      } else {
        String message =
            'Gagal mengambil pengaturan sistem.';

        try {
          final body = jsonDecode(response.body);

          if (body['message'] != null) {
            message =
                body['message'].toString();
          }
        } catch (_) {}

        setState(() {
          _errorMessage =
              '$message\nStatus: ${response.statusCode}';

          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint(
        '❌ ERROR LOAD SETTINGS: $e',
      );

      if (!mounted) return;

      setState(() {
        _errorMessage =
            'Tidak dapat terhubung ke server.\n$e';

        _isLoading = false;
      });
    }
  }

  // ============================================================
  // DEFAULT VALUE
  // ============================================================

  void _setDefaultValues() {
    _jobPointController.text =
        _defaultJobPoint.toString();

    _cancelPointController.text =
        _defaultCancelPoint.toString();

    _ratingBonusController.text =
        _defaultRatingBonus.toString();

    _commissionController.text =
        _formatCommissionInput(
      _defaultCommission,
    );
  }

  // ============================================================
  // PARSE INTEGER
  // ============================================================

  int _parseIntValue(
    TextEditingController controller,
  ) {
    return int.tryParse(
          controller.text.trim(),
        ) ??
        0;
  }

  // ============================================================
  // PARSE COMMISSION
  // ============================================================

  double _parseCommission() {
    final String value =
        _commissionController.text
            .trim()
            .replaceAll(',', '.');

    return double.tryParse(value) ?? 0.0;
  }

  // ============================================================
  // FORMAT COMMISSION
  // ============================================================

  String _formatCommissionInput(
    double value,
  ) {
    // Menampilkan maksimal 2 angka desimal.
    // 15     -> 15.00
    // 15.5   -> 15.50
    // 15.25  -> 15.25
    return value.toStringAsFixed(2);
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (
        context,
        constraints,
      ) {
        final bool isMobile =
            constraints.maxWidth < 850;

        return SingleChildScrollView(
          physics:
              const ClampingScrollPhysics(),
          padding: EdgeInsets.only(
            left: isMobile ? 16 : 24,
            right: isMobile ? 16 : 24,
            top: 12,
            bottom: 24,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            mainAxisSize:
                MainAxisSize.min,
            children: [
              _buildPageHeader(isMobile),

              const SizedBox(height: 16),

              if (_isLoading)
                _buildLoading()
              else if (_errorMessage != null)
                _buildError()
              else ...[
                if (isMobile)
                  Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch,
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      _buildPointSettingsCard(),

                      const SizedBox(height: 12),

                      _buildCommissionCard(),
                    ],
                  )
                else
                  Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child:
                            _buildPointSettingsCard(),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child:
                            _buildCommissionCard(),
                      ),
                    ],
                  ),

                const SizedBox(height: 12),

                _buildActionButtons(isMobile),
              ],
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildPageHeader(
    bool isMobile,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      mainAxisSize:
          MainAxisSize.min,
      children: [
        Text(
          'Pengaturan Sistem Poin',
          style: TextStyle(
            fontSize:
                isMobile ? 22 : 26,
            fontWeight:
                FontWeight.w800,
            color:
                const Color(0xFF0F172A),
          ),
        ),

        const SizedBox(height: 4),

        Text(
          'Konfigurasi aturan poin yang berlaku untuk seluruh mitra',
          style: TextStyle(
            fontSize:
                isMobile ? 12 : 13,
            color:
                const Color(0xFF64748B),
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
      padding:
          const EdgeInsets.symmetric(
        vertical: 60,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(12),
        border: Border.all(
          color:
              const Color(0xFFE2E8F0),
        ),
      ),
      child: const Column(
        children: [
          CircularProgressIndicator(),

          SizedBox(height: 16),

          Text(
            'Mengambil konfigurasi sistem...',
            style: TextStyle(
              color:
                  Color(0xFF64748B),
            ),
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
      padding:
          const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(12),
        border: Border.all(
          color:
              const Color(0xFFFECACA),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline,
            size: 42,
            color: Colors.red,
          ),

          const SizedBox(height: 12),

          const Text(
            'Gagal mengambil pengaturan sistem',
            style: TextStyle(
              fontWeight:
                  FontWeight.w700,
              color:
                  Color(0xFF334155),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            _errorMessage ?? '',
            textAlign:
                TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color:
                  Color(0xFF64748B),
            ),
          ),

          const SizedBox(height: 18),

          ElevatedButton.icon(
            onPressed:
                _loadSettings,
            icon:
                const Icon(Icons.refresh),
            label:
                const Text('Coba Lagi'),
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
        crossAxisAlignment:
            CrossAxisAlignment.start,
        mainAxisSize:
            MainAxisSize.min,
        children: [
          _buildCardTitle(
            icon: '🏆',
            title:
                'Aturan Poin Mitra',
          ),

          const SizedBox(height: 18),

          _buildPointSetting(
            icon: '✅',
            title:
                'Poin dapat per pekerjaan selesai',
            controller:
                _jobPointController,
            suffix: 'poin',
            borderColor:
                const Color(0xFF9DE7D1),
            textColor:
                const Color(0xFF00A86B),
          ),

          const SizedBox(height: 14),

          _buildPointSetting(
            icon: '❌',
            title:
                'Poin dipotong jika mitra batalkan',
            controller:
                _cancelPointController,
            suffix: 'poin',
            borderColor:
                const Color(0xFFFFB5B5),
            textColor:
                const Color(0xFFEF4444),
          ),

          const SizedBox(height: 14),

          _buildPointSetting(
            icon: '⭐',
            title:
                'Bonus poin jika rating ≥ 4.8',
            controller:
                _ratingBonusController,
            suffix: 'poin',
            borderColor:
                const Color(0xFFFFD89A),
            textColor:
                const Color(0xFFF59E0B),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // POINT SETTING
  // ============================================================

  Widget _buildPointSetting({
    required String icon,
    required String title,
    required TextEditingController controller,
    required String suffix,
    required Color borderColor,
    required Color textColor,
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      mainAxisSize:
          MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(
              icon,
              style:
                  const TextStyle(
                fontSize: 15,
              ),
            ),

            const SizedBox(width: 7),

            Expanded(
              child: Text(
                title,
                style:
                    const TextStyle(
                  fontSize: 13,
                  fontWeight:
                      FontWeight.w500,
                  color:
                      Color(0xFF334155),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 7),

        Row(
          children: [
            SizedBox(
              width: 76,
              height: 42,
              child: TextField(
                controller:
                    controller,
                keyboardType:
                    TextInputType.number,
                textAlign:
                    TextAlign.center,
                enabled:
                    !_isSaving &&
                    !_isResetting,
                onChanged: (_) {
                  setState(() {});
                },
                style:
                    TextStyle(
                  fontSize: 14,
                  fontWeight:
                      FontWeight.w800,
                  color:
                      textColor,
                ),
                decoration:
                    InputDecoration(
                  contentPadding:
                      const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  filled: true,
                  fillColor:
                      Colors.white,
                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(8),
                    borderSide:
                        BorderSide(
                      color:
                          borderColor,
                    ),
                  ),
                  enabledBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(8),
                    borderSide:
                        BorderSide(
                      color:
                          borderColor,
                      width: 1.3,
                    ),
                  ),
                  focusedBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(8),
                    borderSide:
                        BorderSide(
                      color:
                          textColor,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 8),

            Text(
              suffix,
              style:
                  const TextStyle(
                fontSize: 13,
                color:
                    Color(0xFF64748B),
              ),
            ),
          ],
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
        crossAxisAlignment:
            CrossAxisAlignment.start,
        mainAxisSize:
            MainAxisSize.min,
        children: [
          _buildCardTitle(
            icon: '💸',
            title:
                'Aturan Komisi Platform',
          ),

          const SizedBox(height: 18),

          const Text(
            'Komisi SiapBantu per transaksi',
            style:
                TextStyle(
              fontSize: 13,
              color:
                  Color(0xFF334155),
            ),
          ),

          const SizedBox(height: 7),

          Row(
            children: [
              SizedBox(
                width: 76,
                height: 42,
                child: TextField(
                  controller:
                      _commissionController,

                  // Mendukung angka desimal
                  keyboardType:
                      const TextInputType.numberWithOptions(
                    decimal: true,
                  ),

                  textAlign:
                      TextAlign.center,

                  enabled:
                      !_isSaving &&
                      !_isResetting,

                  onChanged: (_) {
                    setState(() {});
                  },

                  style:
                      const TextStyle(
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w800,
                    color:
                        Color(0xFF0EA5E9),
                  ),

                  decoration:
                      InputDecoration(
                    contentPadding:
                        const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    filled: true,
                    fillColor:
                        Colors.white,
                    border:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(
                        color:
                            Color(0xFF9DDDF8),
                      ),
                    ),
                    enabledBorder:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(
                        color:
                            Color(0xFF9DDDF8),
                        width: 1.3,
                      ),
                    ),
                    focusedBorder:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(
                        color:
                            Color(0xFF0EA5E9),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              const Text(
                '%',
                style:
                    TextStyle(
                  fontSize: 13,
                  color:
                      Color(0xFF64748B),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          _buildSimulationPreview(),

          const SizedBox(height: 10),

          _buildPointSummary(),
        ],
      ),
    );
  }

  // ============================================================
  // SIMULATION
  // ============================================================

  Widget _buildSimulationPreview() {
    final double commissionPercent =
        _parseCommission();

    const int transaction = 200000;

    final int commission =
        (transaction *
                commissionPercent /
                100)
            .round();

    final int partnerReceive =
        transaction -
            commission;

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(12),
      decoration:
          BoxDecoration(
        color:
            const Color(0xFFF8FAFC),
        borderRadius:
            BorderRadius.circular(9),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Preview Simulasi:',
            style:
                TextStyle(
              fontSize: 12,
              fontWeight:
                  FontWeight.w700,
              color:
                  Color(0xFF334155),
            ),
          ),

          const SizedBox(height: 8),

          _buildSimulationRow(
            'Transaksi',
            'Rp 200.000',
            const Color(0xFF64748B),
          ),

          const SizedBox(height: 4),

          _buildSimulationRow(
            'Komisi platform',
            'Rp ${_formatCurrency(commission)}',
            const Color(0xFF0EA5E9),
          ),

          const SizedBox(height: 4),

          _buildSimulationRow(
            'Mitra terima',
            'Rp ${_formatCurrency(partnerReceive)}',
            const Color(0xFF00A86B),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SIMULATION ROW
  // ============================================================

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
            style:
                const TextStyle(
              fontSize: 12,
              color:
                  Color(0xFF64748B),
            ),
          ),
        ),

        Text(
          value,
          style:
              TextStyle(
            fontSize: 12,
            fontWeight:
                FontWeight.w700,
            color:
                valueColor,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // POINT SUMMARY
  // ============================================================

  Widget _buildPointSummary() {
    final int jobPoint =
        _parseIntValue(
      _jobPointController,
    );

    final int cancelPoint =
        _parseIntValue(
      _cancelPointController,
    );

    final int ratingBonus =
        _parseIntValue(
      _ratingBonusController,
    );

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(12),
      decoration:
          BoxDecoration(
        color:
            const Color(0xFFF8FAFC),
        borderRadius:
            BorderRadius.circular(9),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Ringkasan Sistem Poin:',
            style:
                TextStyle(
              fontSize: 12,
              fontWeight:
                  FontWeight.w700,
              color:
                  Color(0xFF334155),
            ),
          ),

          const SizedBox(height: 8),

          _buildSummaryRow(
            '✅',
            'Selesai kerja:',
            '+$jobPoint poin',
            const Color(0xFF00A86B),
          ),

          const SizedBox(height: 4),

          _buildSummaryRow(
            '❌',
            'Batalkan:',
            '-$cancelPoint poin',
            const Color(0xFFEF4444),
          ),

          const SizedBox(height: 4),

          _buildSummaryRow(
            '⭐',
            'Bonus rating:',
            '+$ratingBonus poin',
            const Color(0xFFF59E0B),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SUMMARY ROW
  // ============================================================

  Widget _buildSummaryRow(
    String icon,
    String label,
    String value,
    Color valueColor,
  ) {
    return Row(
      children: [
        Text(
          icon,
          style:
              const TextStyle(
            fontSize: 13,
          ),
        ),

        const SizedBox(width: 5),

        Expanded(
          child: Text(
            label,
            style:
                const TextStyle(
              fontSize: 12,
              color:
                  Color(0xFF64748B),
            ),
          ),
        ),

        Text(
          value,
          style:
              TextStyle(
            fontSize: 12,
            fontWeight:
                FontWeight.w700,
            color:
                valueColor,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // CARD
  // ============================================================

  Widget _buildCard({
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(18),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(12),
        border: Border.all(
          color:
              const Color(0xFFE2E8F0),
        ),
      ),
      child: child,
    );
  }

  // ============================================================
  // CARD TITLE
  // ============================================================

  Widget _buildCardTitle({
    required String icon,
    required String title,
  }) {
    return Row(
      children: [
        Text(
          icon,
          style:
              const TextStyle(
            fontSize: 16,
          ),
        ),

        const SizedBox(width: 7),

        Expanded(
          child: Text(
            title,
            style:
                const TextStyle(
              fontSize: 15,
              fontWeight:
                  FontWeight.w700,
              color:
                  Color(0xFF0F172A),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ACTION BUTTONS
  // ============================================================

  Widget _buildActionButtons(
    bool isMobile,
  ) {
    if (isMobile) {
      return Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: [
          _buildSaveButton(),

          const SizedBox(height: 8),

          _buildResetButton(),
        ],
      );
    }

    return Row(
      mainAxisSize:
          MainAxisSize.min,
      children: [
        _buildSaveButton(),

        const SizedBox(width: 10),

        _buildResetButton(),
      ],
    );
  }

  // ============================================================
  // SAVE BUTTON
  // ============================================================

  Widget _buildSaveButton() {
    return ElevatedButton.icon(
      onPressed:
          (_isSaving || _isResetting)
              ? null
              : _saveConfiguration,

      icon:
          _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2,
                    color:
                        Colors.white,
                  ),
                )
              : const Text(
                  '💾',
                  style:
                      TextStyle(
                    fontSize: 14,
                  ),
                ),

      label: Text(
        _isSaving
            ? 'Menyimpan...'
            : 'Simpan Konfigurasi',
      ),

      style:
          ElevatedButton.styleFrom(
        backgroundColor:
            const Color(0xFFF04444),
        foregroundColor:
            Colors.white,
        disabledBackgroundColor:
            const Color(0xFFFCA5A5),
        disabledForegroundColor:
            Colors.white,
        padding:
            const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 13,
        ),
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(8),
        ),
        elevation: 0,
      ),
    );
  }

  // ============================================================
  // RESET BUTTON
  // ============================================================

  Widget _buildResetButton() {
    return OutlinedButton(
      onPressed:
          (_isSaving || _isResetting)
              ? null
              : _resetConfiguration,

      style:
          OutlinedButton.styleFrom(
        foregroundColor:
            const Color(0xFF64748B),
        backgroundColor:
            Colors.white,
        padding:
            const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 13,
        ),
        side:
            const BorderSide(
          color:
              Color(0xFFE2E8F0),
        ),
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(8),
        ),
      ),

      child: Text(
        _isResetting
            ? 'Mereset...'
            : 'Reset ke Default',
      ),
    );
  }

  // ============================================================
  // SAVE CONFIGURATION
  // ============================================================

  Future<void> _saveConfiguration() async {
    // ==========================================================
    // AMBIL POINT
    // ==========================================================

    final int jobPoint =
        _parseIntValue(
      _jobPointController,
    );

    final int cancelPoint =
        _parseIntValue(
      _cancelPointController,
    );

    final int ratingBonus =
        _parseIntValue(
      _ratingBonusController,
    );

    // ==========================================================
    // AMBIL COMMISSION
    // ==========================================================

    final double commission =
        _parseCommission();

    // ==========================================================
    // DEBUG
    // ==========================================================

    debugPrint(
      '💰 COMMISSION INPUT: '
      '${_commissionController.text}',
    );

    debugPrint(
      '💰 COMMISSION PARSED: '
      '$commission',
    );

    // ==========================================================
    // VALIDASI POINT
    // ==========================================================

    if (jobPoint < 0 ||
        cancelPoint < 0 ||
        ratingBonus < 0) {
      _showMessage(
        'Nilai poin tidak boleh negatif.',
        isError: true,
      );
      return;
    }

    // ==========================================================
    // VALIDASI COMMISSION
    // ==========================================================

    if (commission < 0 ||
        commission > 100) {
      _showMessage(
        'Komisi platform harus berada antara 0 sampai 100%.',
        isError: true,
      );
      return;
    }

    if (!mounted) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // ========================================================
      // PUT DATABASE
      // ========================================================

      final response =
          await ApiService.put(
        '/superadmin/system-settings',
        {
          'points_on_completion':
              jobPoint,

          'points_on_cancellation':
              cancelPoint,

          'points_bonus_rating':
              ratingBonus,

          // PENTING:
          // commission sekarang DOUBLE
          'platform_commission_percent':
              commission,
        },
      );

      debugPrint(
        '📤 DATA SAVE: '
        'completion=$jobPoint, '
        'cancellation=$cancelPoint, '
        'rating=$ratingBonus, '
        'commission=$commission',
      );

      debugPrint(
        '📥 SAVE SYSTEM SETTINGS: '
        '${response.body}',
      );

      if (!mounted) return;

      // ========================================================
      // SUCCESS
      // ========================================================

      if (response.statusCode == 200) {
        String message =
            'Konfigurasi sistem berhasil disimpan.';

        try {
          final body =
              jsonDecode(response.body);

          if (body['message'] != null) {
            message =
                body['message'].toString();
          }
        } catch (_) {}

        setState(() {
          _isSaving = false;
        });

        _showMessage(message);

        // ======================================================
        // LOAD ULANG DARI DATABASE
        // ======================================================

        await _loadSettings();

        return;
      }

      // ========================================================
      // SERVER ERROR
      // ========================================================

      String message =
          'Gagal menyimpan konfigurasi.';

      try {
        final body =
            jsonDecode(response.body);

        if (body['message'] != null) {
          message =
              body['message'].toString();
        }
      } catch (_) {}

      setState(() {
        _isSaving = false;
      });

      _showMessage(
        message,
        isError: true,
      );
    } catch (e) {
      debugPrint(
        '❌ ERROR SAVE SETTINGS: $e',
      );

      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      _showMessage(
        'Terjadi kesalahan: $e',
        isError: true,
      );
    }
  }

  // ============================================================
  // RESET CONFIGURATION
  // ============================================================

  Future<void> _resetConfiguration() async {
    if (!mounted) return;

    // ==========================================================
    // TAMPILKAN DEFAULT DI UI
    // ==========================================================

    setState(() {
      _isResetting = true;

      _jobPointController.text =
          _defaultJobPoint.toString();

      _cancelPointController.text =
          _defaultCancelPoint.toString();

      _ratingBonusController.text =
          _defaultRatingBonus.toString();

      _commissionController.text =
          _formatCommissionInput(
        _defaultCommission,
      );
    });

    // ==========================================================
    // SIMPAN DEFAULT KE DATABASE
    // ==========================================================

    try {
      final response =
          await ApiService.put(
        '/superadmin/system-settings',
        {
          'points_on_completion':
              _defaultJobPoint,

          'points_on_cancellation':
              _defaultCancelPoint,

          'points_bonus_rating':
              _defaultRatingBonus,

          'platform_commission_percent':
              _defaultCommission,
        },
      );

      debugPrint(
        '📤 RESET DATA: '
        'completion=$_defaultJobPoint, '
        'cancellation=$_defaultCancelPoint, '
        'rating=$_defaultRatingBonus, '
        'commission=$_defaultCommission',
      );

      debugPrint(
        '📥 RESET SYSTEM SETTINGS: '
        '${response.body}',
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          _isResetting = false;
        });

        _showMessage(
          'Konfigurasi dikembalikan ke default.',
        );

        await _loadSettings();
      } else {
        String message =
            'Gagal mereset konfigurasi.';

        try {
          final body =
              jsonDecode(response.body);

          if (body['message'] != null) {
            message =
                body['message'].toString();
          }
        } catch (_) {}

        setState(() {
          _isResetting = false;
        });

        _showMessage(
          message,
          isError: true,
        );
      }
    } catch (e) {
      debugPrint(
        '❌ ERROR RESET SETTINGS: $e',
      );

      if (!mounted) return;

      setState(() {
        _isResetting = false;
      });

      _showMessage(
        'Terjadi kesalahan: $e',
        isError: true,
      );

      // Ambil kembali nilai sebenarnya
      // dari database.
      await _loadSettings();
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content:
            Text(message),
        backgroundColor:
            isError
                ? Colors.red
                : const Color(0xFF16A34A),
        behavior:
            SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // CURRENCY
  // ============================================================

  String _formatCurrency(
    int value,
  ) {
    final String text =
        value.toString();

    final StringBuffer result =
        StringBuffer();

    for (
      int i = 0;
      i < text.length;
      i++
    ) {
      if (i > 0 &&
          (text.length - i) % 3 ==
              0) {
        result.write('.');
      }

      result.write(text[i]);
    }

    return result.toString();
  }
}