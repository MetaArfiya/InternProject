import 'dart:convert';

import 'package:flutter/material.dart';

import '../../services/api_service.dart';

class AdminDailyReportScreen extends StatefulWidget {
  const AdminDailyReportScreen({
    super.key,
  });

  @override
  State<AdminDailyReportScreen> createState() =>
      _AdminDailyReportScreenState();
}

class _AdminDailyReportScreenState
    extends State<AdminDailyReportScreen> {

  // =========================================================
  // STATE
  // =========================================================

  int _approvedPartners = 0;
  int _moderatedPosts = 0;
  int _rejectedPosts = 0;
  int _userReports = 0;

  List<Map<String, dynamic>> _activities = [];

  bool _isLoading = true;
  bool _isRefreshing = false;

  String? _errorMessage;

  // =========================================================
  // INIT
  // =========================================================

  @override
  void initState() {
    super.initState();

    _loadData();
  }

  // =========================================================
  // LOAD DATA
  // =========================================================

  Future<void> _loadData({
    bool refresh = false,
  }) async {

    if (refresh) {
      if (mounted) {
        setState(() {
          _isRefreshing = true;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }
    }

    try {
      // =====================================================
      // REQUEST KE API MELALUI APISERVICE
      // =====================================================

      final response =
          await ApiService.get(
        '/admin/activities',
      );

      print(
        '📊 ADMIN ACTIVITY STATUS: '
        '${response.statusCode}',
      );

      print(
        '📊 ADMIN ACTIVITY RESPONSE: '
        '${response.body}',
      );

      // =====================================================
      // SUCCESS
      // =====================================================

      if (response.statusCode == 200) {
        final decoded =
            jsonDecode(response.body);

        if (decoded is! Map<String, dynamic>) {
          throw Exception(
            'Format response API tidak valid.',
          );
        }

        final success =
            decoded['success'] == true;

        if (!success) {
          throw Exception(
            decoded['message']?.toString() ??
                'Gagal mengambil data aktivitas.',
          );
        }

        // ===================================================
        // DATA
        // ===================================================

        final data = decoded['data'];

        if (data is! Map<String, dynamic>) {
          throw Exception(
            'Data laporan tidak ditemukan.',
          );
        }

        // ===================================================
        // STATISTICS
        // ===================================================

        final statistics =
            data['statistics'];

        int approvedPartners = 0;
        int moderatedPosts = 0;
        int rejectedPosts = 0;
        int userReports = 0;

        if (statistics is Map) {
          approvedPartners = _toInt(
            statistics[
                'approved_partners'],
          );

          moderatedPosts = _toInt(
            statistics[
                'moderated_posts'],
          );

          rejectedPosts = _toInt(
            statistics[
                'rejected_posts'],
          );

          userReports = _toInt(
            statistics[
                'user_reports'],
          );
        }

        // ===================================================
        // ACTIVITIES
        // ===================================================

        final activities =
            data['activities'];

        final parsedActivities =
            <Map<String, dynamic>>[];

        if (activities is List) {
          for (final item in activities) {
            if (item is Map) {
              parsedActivities.add(
                Map<String, dynamic>.from(
                  item,
                ),
              );
            }
          }
        }

        // ===================================================
        // UPDATE STATE
        // ===================================================

        if (!mounted) {
          return;
        }

        setState(() {
          _approvedPartners =
              approvedPartners;

          _moderatedPosts =
              moderatedPosts;

          _rejectedPosts =
              rejectedPosts;

          _userReports =
              userReports;

          _activities =
              parsedActivities;

          _errorMessage = null;
        });
      }

      // =====================================================
      // UNAUTHORIZED
      // =====================================================

      else if (response.statusCode == 401) {
        throw Exception(
          'Sesi login sudah tidak valid. Silakan login kembali.',
        );
      }

      // =====================================================
      // FORBIDDEN
      // =====================================================

      else if (response.statusCode == 403) {
        throw Exception(
          'Anda tidak memiliki akses ke laporan admin.',
        );
      }

      // =====================================================
      // OTHER ERROR
      // =====================================================

      else {
        String message =
            'Server mengembalikan status ${response.statusCode}.';

        try {
          final error =
              jsonDecode(response.body);

          if (error is Map &&
              error['message'] != null) {
            message =
                error['message'].toString();
          }
        } catch (_) {}

        throw Exception(message);
      }
    }

    // =======================================================
    // ERROR HANDLING
    // =======================================================

    catch (e) {
      print(
        '❌ ERROR ADMIN ACTIVITY: $e',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage =
            e.toString().replaceFirst(
                  'Exception: ',
                  '',
                );
      });
    }

    // =======================================================
    // FINALLY
    // =======================================================

    finally {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  // =========================================================
  // INT PARSER
  // =========================================================

  int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value) ?? 0;
    }

    return 0;
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (
        context,
        constraints,
      ) {
        final screenWidth =
            constraints.maxWidth;

        final isMobile =
            screenWidth < 700;

        final isTablet =
            screenWidth >= 700 &&
            screenWidth < 1100;

        return _buildContent(
          context,
          isMobile,
          isTablet,
        );
      },
    );
  }

  // =========================================================
  // CONTENT
  // =========================================================

  Widget _buildContent(
    BuildContext context,
    bool isMobile,
    bool isTablet,
  ) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFFF4F7FB),

      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),

        padding: EdgeInsets.fromLTRB(
          isMobile ? 16 : 26,
          isMobile ? 18 : 28,
          isMobile ? 16 : 26,
          30,
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            _buildHeader(
              isMobile,
            ),

            const SizedBox(
              height: 22,
            ),

            if (_errorMessage != null)
              _buildError(),

            if (_isLoading)
              _buildLoading()
            else ...[
              _buildStatistics(
                isMobile: isMobile,
                isTablet: isTablet,
              ),

              const SizedBox(
                height: 22,
              ),

              _buildActivitySection(),
            ],
          ],
        ),
      ),
    );
  }

  // =========================================================
  // HEADER
  // =========================================================

  Widget _buildHeader(
    bool isMobile,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Laporan Harian',
          style: TextStyle(
            fontSize: isMobile ? 23 : 27,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),

        const SizedBox(height: 5),

        Text(
          'Ringkasan aktivitas admin hari ini',
          style: TextStyle(
            fontSize: isMobile ? 12 : 13,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // ERROR
  // =========================================================

  Widget _buildError() {
    return Container(
      width: double.infinity,

      margin:
          const EdgeInsets.only(
        bottom: 18,
      ),

      padding:
          const EdgeInsets.all(
        14,
      ),

      decoration:
          BoxDecoration(
        color:
            const Color(0xFFFEF2F2),

        borderRadius:
            BorderRadius.circular(
          9,
        ),

        border:
            Border.all(
          color:
              const Color(0xFFFECACA),
        ),
      ),

      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          const Icon(
            Icons.error_outline,
            size: 20,
            color:
                Color(0xFFEF4444),
          ),

          const SizedBox(
            width: 10,
          ),

          Expanded(
            child: Text(
              _errorMessage!,

              style:
                  const TextStyle(
                fontSize: 12,
                color:
                    Color(0xFF991B1B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // LOADING
  // =========================================================

  Widget _buildLoading() {
    return Column(
      children: [
        Row(
          children:
              List.generate(
            4,
            (index) {
              return Expanded(
                child: Container(
                  height: 92,

                  margin:
                      EdgeInsets.only(
                    right:
                        index == 3
                            ? 0
                            : 10,
                  ),

                  decoration:
                      BoxDecoration(
                    color:
                        Colors.white,

                    borderRadius:
                        BorderRadius.circular(
                      9,
                    ),

                    border:
                        Border.all(
                      color:
                          const Color(
                        0xFFE2E8F0,
                      ),
                    ),
                  ),

                  child:
                      const Center(
                    child:
                        SizedBox(
                      width: 22,
                      height: 22,

                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(
          height: 22,
        ),

        Container(
          width: double.infinity,
          height: 200,

          decoration:
              BoxDecoration(
            color:
                Colors.white,

            borderRadius:
                BorderRadius.circular(
              9,
            ),

            border:
                Border.all(
              color:
                  const Color(
                0xFFE2E8F0,
              ),
            ),
          ),

          child:
              const Center(
            child:
                CircularProgressIndicator(
              strokeWidth: 2,
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // STATISTICS
  // =========================================================

  Widget _buildStatistics({
    required bool isMobile,
    required bool isTablet,
  }) {
    final statistics = [
      {
        'title':
            'Mitra berhasil diverifikasi',

        'value':
            _approvedPartners.toString(),

        'description':
            'Mitra disetujui hari ini',

        'icon':
            Icons.verified_outlined,

        'color':
            const Color(0xFF10B981),
      },

      {
        'title':
            'Konten dimoderasi',

        'value':
            _moderatedPosts.toString(),

        'description':
            'Postingan diperiksa hari ini',

        'icon':
            Icons.flag_outlined,

        'color':
            const Color(0xFF8B5CF6),
      },

      {
        'title':
            'Konten ditolak',

        'value':
            _rejectedPosts.toString(),

        'description':
            'Postingan ditolak hari ini',

        'icon':
            Icons.cancel_outlined,

        'color':
            const Color(0xFFEF4444),
      },

      {
        'title':
            'Laporan pengguna',

        'value':
            _userReports.toString(),

        'description':
            'Laporan masuk hari ini',

        'icon':
            Icons.report_problem_outlined,

        'color':
            const Color(0xFFF59E0B),
      },
    ];

    // =======================================================
    // MOBILE
    // =======================================================

    if (isMobile) {
      return Column(
        children:
            statistics.map(
          (item) {
            return Padding(
              padding:
                  const EdgeInsets.only(
                bottom: 10,
              ),

              child:
                  _statCard(
                item,
                compact: true,
              ),
            );
          },
        ).toList(),
      );
    }

    // =======================================================
    // TABLET
    // =======================================================

    if (isTablet) {
      return GridView.builder(
        shrinkWrap: true,

        physics:
            const NeverScrollableScrollPhysics(),

        itemCount:
            statistics.length,

        gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 2.8,
        ),

        itemBuilder:
            (context, index) {
          return _statCard(
            statistics[index],
          );
        },
      );
    }

    // =======================================================
    // DESKTOP
    // =======================================================

    return Row(
      children:
          statistics.map(
        (item) {
          return Expanded(
            child: Padding(
              padding:
                  EdgeInsets.only(
                right:
                    item ==
                            statistics.last
                        ? 0
                        : 10,
              ),

              child:
                  _statCard(item),
            ),
          );
        },
      ).toList(),
    );
  }

  // =========================================================
  // STAT CARD
  // =========================================================

  Widget _statCard(
    Map<String, dynamic> item, {
    bool compact = false,
  }) {
    final color =
        item['color'] as Color;

    return Container(
      width: double.infinity,

      constraints:
          BoxConstraints(
        minHeight:
            compact ? 72 : 92,
      ),

      padding:
          EdgeInsets.all(
        compact ? 14 : 17,
      ),

      decoration:
          BoxDecoration(
        color:
            Colors.white,

        borderRadius:
            BorderRadius.circular(
          9,
        ),

        border:
            Border.all(
          color:
              const Color(
            0xFFE2E8F0,
          ),
        ),
      ),

      child: Row(
        children: [
          Container(
            width:
                compact ? 40 : 42,

            height:
                compact ? 40 : 42,

            decoration:
                BoxDecoration(
              color:
                  color.withValues(
                alpha: 0.10,
              ),

              borderRadius:
                  BorderRadius.circular(
                9,
              ),
            ),

            child: Icon(
              item['icon']
                  as IconData,

              size:
                  compact ? 20 : 21,

              color:
                  color,
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          Expanded(
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,

              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  item['value']
                      as String,

                  style:
                      TextStyle(
                    fontSize:
                        compact
                            ? 20
                            : 21,

                    fontWeight:
                        FontWeight.w700,

                    color:
                        color,
                  ),
                ),

                const SizedBox(
                  height: 2,
                ),

                Text(
                  item['title']
                      as String,

                  maxLines: 1,

                  overflow:
                      TextOverflow.ellipsis,

                  style:
                      TextStyle(
                    fontSize:
                        compact
                            ? 10
                            : 11,

                    fontWeight:
                        FontWeight.w600,

                    color:
                        const Color(
                      0xFF334155,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 2,
                ),

                Text(
                  item['description']
                      as String,

                  maxLines: 1,

                  overflow:
                      TextOverflow.ellipsis,

                  style:
                      const TextStyle(
                    fontSize: 9,

                    color:
                        Color(
                      0xFF94A3B8,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // ACTIVITY SECTION
  // =========================================================

  Widget _buildActivitySection() {
    return Container(
      width: double.infinity,

      decoration:
          BoxDecoration(
        color:
            Colors.white,

        borderRadius:
            BorderRadius.circular(
          9,
        ),

        border:
            Border.all(
          color:
              const Color(
            0xFFDCE3EC,
          ),
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          const Padding(
            padding:
                EdgeInsets.all(
              17,
            ),

            child: Text(
              'Aktivitas Hari Ini',

              style:
                  TextStyle(
                fontSize: 14,

                fontWeight:
                    FontWeight.w700,

                color:
                    Color(
                  0xFF0F172A,
                ),
              ),
            ),
          ),

          const Divider(
            height: 1,

            color:
                Color(
              0xFFE2E8F0,
            ),
          ),

          // =================================================
          // EMPTY
          // =================================================

          if (_activities.isEmpty)

            _buildEmptyActivity()

          // =================================================
          // ACTIVITY LIST
          // =================================================

          else
            ..._activities.map(
              (activity) {
                return _activityItem(
                  _getIcon(
                    activity['icon']
                            ?.toString() ??
                        '',
                  ),

                  activity['title']
                          ?.toString() ??
                      'Aktivitas admin',

                  activity['time']
                          ?.toString() ??
                      '-',

                  _getColor(
                    activity[
                                'color_type']
                            ?.toString() ??
                        activity[
                                'colorType']
                            ?.toString() ??
                        '',
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // =========================================================
  // EMPTY ACTIVITY
  // =========================================================

  Widget _buildEmptyActivity() {
    return const Padding(
      padding:
          EdgeInsets.symmetric(
        vertical: 35,
        horizontal: 20,
      ),

      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.history_outlined,

              size: 35,

              color:
                  Color(
                0xFFCBD5E1,
              ),
            ),

            SizedBox(
              height: 10,
            ),

            Text(
              'Belum ada aktivitas hari ini.',

              textAlign:
                  TextAlign.center,

              style:
                  TextStyle(
                fontSize: 12,

                color:
                    Color(
                  0xFF94A3B8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // ACTIVITY ITEM
  // =========================================================

  Widget _activityItem(
    IconData icon,
    String title,
    String time,
    Color color,
  ) {
    return Container(
      width: double.infinity,

      padding:
          const EdgeInsets.symmetric(
        horizontal: 17,
        vertical: 14,
      ),

      decoration:
          const BoxDecoration(
        border: Border(
          top: BorderSide(
            color:
                Color(
              0xFFE2E8F0,
            ),
          ),
        ),
      ),

      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,

            decoration:
                BoxDecoration(
              color:
                  color.withValues(
                alpha: 0.10,
              ),

              shape:
                  BoxShape.circle,
            ),

            child: Icon(
              icon,
              size: 17,
              color: color,
            ),
          ),

          const SizedBox(
            width: 11,
          ),

          Expanded(
            child: Text(
              title,

              maxLines: 2,

              overflow:
                  TextOverflow.ellipsis,

              style:
                  const TextStyle(
                fontSize: 12,

                fontWeight:
                    FontWeight.w500,

                color:
                    Color(
                  0xFF334155,
                ),
              ),
            ),
          ),

          const SizedBox(
            width: 10,
          ),

          Text(
            time,

            style:
                const TextStyle(
              fontSize: 10,

              color:
                  Color(
                0xFF94A3B8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // ICON MAPPING
  // =========================================================

  IconData _getIcon(
    String icon,
  ) {
    switch (icon) {
      case 'verified':
        return Icons.verified_outlined;

      case 'cancel':
        return Icons.cancel_outlined;

      case 'flag':
        return Icons.flag_outlined;

      case 'report':
        return Icons.report_problem_outlined;

      case 'check':
        return Icons.check_circle_outline;

      default:
        return Icons.info_outline;
    }
  }

  // =========================================================
  // COLOR MAPPING
  // =========================================================

  Color _getColor(
    String colorType,
  ) {
    switch (colorType) {
      case 'green':
        return const Color(
          0xFF10B981,
        );

      case 'purple':
        return const Color(
          0xFF8B5CF6,
        );

      case 'red':
        return const Color(
          0xFFEF4444,
        );

      case 'orange':
        return const Color(
          0xFFF59E0B,
        );

      default:
        return const Color(
          0xFF64748B,
        );
    }
  }
}