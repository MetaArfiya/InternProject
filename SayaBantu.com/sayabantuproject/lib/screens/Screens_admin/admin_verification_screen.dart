import 'dart:convert';

import 'package:flutter/material.dart';

import '../../data/admin_activity_data.dart';
import '../../services/api_service.dart';

class AdminVerificationScreen extends StatefulWidget {
  final ValueChanged<int>? onPendingCountChanged;

  const AdminVerificationScreen({
    super.key,
    this.onPendingCountChanged,
  });

  @override
  State<AdminVerificationScreen> createState() =>
      _AdminVerificationScreenState();
}

class _AdminVerificationScreenState
    extends State<AdminVerificationScreen> {
  // =========================================================
  // STATE
  // =========================================================

  List<Map<String, dynamic>> partners = [];

  bool isLoading = true;
  bool isProcessing = false;

  // Statistik dari DATABASE / API
  int waitingCount = 0;
  int approvedToday = 0;
  int rejected = 0;

  int? adminId;

  // =========================================================
  // INIT STATE
  // =========================================================

  @override
  void initState() {
    super.initState();

    _initialize();
  }

  // =========================================================
  // INITIALIZE
  // =========================================================

  Future<void> _initialize() async {
    await _getAdminId();
    await _fetchUnverifiedMitra();
  }

  // =========================================================
  // GET ADMIN LOGIN
  // =========================================================

  Future<void> _getAdminId() async {
    try {
      final response = await ApiService.get('/user');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        dynamic userData;

        if (decoded is Map) {
          userData = decoded['data'] ?? decoded['user'];
        }

        if (userData is Map) {
          final dynamic id = userData['id'];

          if (id != null) {
            adminId = int.tryParse(id.toString());
          }
        }
      }
    } catch (e) {
      debugPrint(
        'GET ADMIN ID ERROR: $e',
      );
    }
  }

  // =========================================================
  // GET MITRA BELUM TERVERIFIKASI
  // =========================================================

  Future<void> _fetchUnverifiedMitra() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      final response = await ApiService.get(
        '/admin/unverified-mitra',
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded is! Map) {
          throw Exception(
            'Format response API tidak valid.',
          );
        }

        // =====================================================
        // STATISTIK DARI API
        // =====================================================

        final dynamic statistics =
            decoded['statistics'];

        if (statistics is Map) {
          waitingCount =
              int.tryParse(
                    statistics['menunggu']
                            ?.toString() ??
                        '0',
                  ) ??
                  0;

          approvedToday =
              int.tryParse(
                    statistics[
                                'disetujui_hari_ini']
                            ?.toString() ??
                        '0',
                  ) ??
                  0;

          rejected =
              int.tryParse(
                    statistics['ditolak']
                            ?.toString() ??
                        '0',
                  ) ??
                  0;
        }

        // =====================================================
        // DATA MITRA
        // =====================================================

        final dynamic rawData =
            decoded['data'];

        final List<dynamic> data =
            rawData is List ? rawData : [];

        final List<Map<String, dynamic>>
            mappedPartners =
            data.map<Map<String, dynamic>>(
          (item) {
            final Map<String, dynamic>
                mitra =
                item is Map<String, dynamic>
                    ? item
                    : Map<String, dynamic>.from(
                        item,
                      );

            // -------------------------------------------------
            // USER
            // -------------------------------------------------

            final dynamic rawUser =
                mitra['user'];

            final Map<String, dynamic>
                user =
                rawUser is Map
                    ? Map<String, dynamic>.from(
                        rawUser,
                      )
                    : {};

            // -------------------------------------------------
            // ID
            // -------------------------------------------------

            final dynamic id =
                mitra['id'];

            // -------------------------------------------------
            // NAMA
            // -------------------------------------------------

            final String name =
                user['name']
                        ?.toString() ??
                    mitra['name']
                        ?.toString() ??
                    'Tanpa Nama';

            // -------------------------------------------------
            // EMAIL
            // -------------------------------------------------

            final String email =
                user['email']
                        ?.toString() ??
                    mitra['email']
                        ?.toString() ??
                    'Tanpa Email';

            // -------------------------------------------------
            // KATEGORI / SKILLS
            // -------------------------------------------------

            final String category =
                mitra['skills']
                        ?.toString() ??
                    mitra['category']
                        ?.toString() ??
                    'Umum';

            // -------------------------------------------------
            // KOTA
            // -------------------------------------------------

            final String city =
                user['city']
                        ?.toString() ??
                    mitra['city']
                        ?.toString() ??
                    user['address']
                        ?.toString() ??
                    mitra['address']
                        ?.toString() ??
                    'Indonesia';

            // -------------------------------------------------
            // DOKUMEN KTP
            // -------------------------------------------------

            final dynamic verificationImage =
                mitra['verification_image'];

            // -------------------------------------------------
            // CERTIFICATE
            // -------------------------------------------------

            final dynamic rawCertificate =
                mitra['certificate'];

            String certificateText =
                'Tidak tersedia';

            if (rawCertificate is List) {
              certificateText =
                  rawCertificate.join(', ');
            } else if (rawCertificate != null) {
              certificateText =
                  rawCertificate.toString();
            }

            // -------------------------------------------------
            // DOKUMEN
            // -------------------------------------------------

            final List<Map<String, dynamic>>
                documents = [
              {
                'title':
                    'KTP / Identitas',
                'file':
                    verificationImage
                            ?.toString() ??
                        'Tidak tersedia',
                'valid':
                    verificationImage !=
                            null &&
                        verificationImage
                            .toString()
                            .isNotEmpty,
              },
              {
                'title':
                    'Bukti Keahlian',
                'file':
                    certificateText,
                'valid':
                    rawCertificate !=
                            null &&
                        certificateText
                            .isNotEmpty &&
                        certificateText !=
                            'Tidak tersedia',
              },
            ];

            return {
              'id': id,
              'name': name,
              'email': email,
              'category': category,
              'city': city,
              'time': _formatTime(
                mitra['created_at'],
              ),
              'created_at':
                  mitra['created_at'],
              'documents': documents,
              'verification_image':
                  verificationImage,
              'certificate':
                  rawCertificate,
            };
          },
        ).toList();

        setState(() {
          partners = mappedPartners;
          isLoading = false;
        });

        // =====================================================
        // SYNC BADGE
        // =====================================================

        _syncPending();
      } else {
        setState(() {
          isLoading = false;
        });

        _message(
          _getErrorMessage(response),
          error: true,
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      _message(
        'Gagal terhubung ke server.',
        error: true,
      );

      debugPrint(
        'FETCH UNVERIFIED MITRA ERROR: $e',
      );
    }
  }

  // =========================================================
  // CHECK DOKUMEN
  // =========================================================

  bool _documentsComplete(
    Map<String, dynamic> partner,
  ) {
    final List<dynamic> documents =
        partner['documents'] as List<dynamic>? ??
            [];

    if (documents.isEmpty) {
      return false;
    }

    return documents.every(
      (doc) =>
          doc is Map &&
          doc['valid'] == true,
    );
  }

  // =========================================================
  // APPROVE
  // =========================================================

  Future<void> _approve(
    int index,
  ) async {
    if (index < 0 ||
        index >= partners.length) {
      return;
    }

    if (isProcessing) {
      return;
    }

    if (adminId == null) {
      _message(
        'ID admin tidak ditemukan. Silakan login ulang.',
        error: true,
      );
      return;
    }

    final partner = partners[index];

    final dynamic id =
        partner['id'];

    final String name =
        partner['name']?.toString() ??
            'Mitra';

    if (id == null) {
      _message(
        'ID mitra tidak ditemukan.',
        error: true,
      );
      return;
    }

    // -------------------------------------------------------
    // CEK DOKUMEN
    // -------------------------------------------------------

    if (!_documentsComplete(partner)) {
      _message(
        'Berkas $name belum lengkap atau belum valid.',
        error: true,
      );
      return;
    }

    // -------------------------------------------------------
    // KONFIRMASI
    // -------------------------------------------------------

    final bool ok =
        await showDialog<bool>(
              context: context,
              builder: (
                dialogContext,
              ) {
                return AlertDialog(
                  title: const Text(
                    'Approve Mitra',
                  ),
                  content: Text(
                    'Yakin ingin memverifikasi $name?\n\n'
                    'Pastikan identitas dan bukti '
                    'keahlian sudah sesuai.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(
                          dialogContext,
                          false,
                        );
                      },
                      child: const Text(
                        'Batal',
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(
                          dialogContext,
                          true,
                        );
                      },
                      icon: const Icon(
                        Icons.check,
                        size: 17,
                      ),
                      label: const Text(
                        'Approve',
                      ),
                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(
                          0xFF10B981,
                        ),
                        foregroundColor:
                            Colors.white,
                      ),
                    ),
                  ],
                );
              },
            ) ??
            false;

    if (!ok || !mounted) {
      return;
    }

    setState(() {
      isProcessing = true;
    });

    try {
      // -----------------------------------------------------
      // API APPROVE
      //
      // Laravel membutuhkan:
      // admin_id
      // action = approve
      // -----------------------------------------------------

      final response =
          await ApiService.post(
        '/admin/verify-mitra/$id',
        {
          'admin_id': adminId,
          'action': 'approve',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          partners.removeAt(index);
          isProcessing = false;

          // Update sementara agar UI langsung berubah.
          waitingCount =
              partners.length;

          approvedToday++;
        });

        _syncPending();

        AdminActivityData
            .addApprovedPartner(
          name: name,
        );

        _message(
          '$name berhasil diverifikasi.',
        );
      } else {
        setState(() {
          isProcessing = false;
        });

        _message(
          _getErrorMessage(response),
          error: true,
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isProcessing = false;
      });

      _message(
        'Terjadi kesalahan saat memverifikasi mitra.',
        error: true,
      );

      debugPrint(
        'APPROVE MITRA ERROR: $e',
      );
    }
  }

  // =========================================================
  // REJECT
  // =========================================================

  Future<void> _reject(int index) async {
    if (index < 0 || index >= partners.length) {
      return;
    }

    if (isProcessing) {
      return;
    }

    if (adminId == null) {
      _message(
        'ID admin tidak ditemukan. Silakan login ulang.',
        error: true,
      );
      return;
    }

    final partner = partners[index];

    final dynamic id = partner['id'];

    final String name =
        partner['name']?.toString() ?? 'Mitra';

    if (id == null) {
      _message(
        'ID mitra tidak ditemukan.',
        error: true,
      );
      return;
    }

    final String? reason = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final controller = TextEditingController();

        return AlertDialog(
          title: const Text(
            'Tolak Pendaftaran',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Berikan alasan penolakan untuk $name.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText:
                      'Contoh: KTP tidak jelas atau bukti keahlian tidak sesuai.',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                controller.dispose();
                Navigator.of(dialogContext).pop();
              },
              child: const Text(
                'Batal',
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                final text = controller.text.trim();

                if (text.isEmpty) {
                  return;
                }

                controller.dispose();
                Navigator.of(dialogContext).pop(text);
              },
              icon: const Icon(
                Icons.close,
                size: 17,
              ),
              label: const Text(
                'Reject',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );

    if (reason == null || !mounted) {
      return;
    }

    setState(() {
      isProcessing = true;
    });

    try {
      final response = await ApiService.post(
        '/admin/verify-mitra/$id',
        {
          'admin_id': adminId,
          'action': 'reject',
          // 'reason': reason, // aktifkan jika Laravel sudah menerima reason
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          partners.removeAt(index);
          isProcessing = false;

          waitingCount = partners.length;
          rejected++;
        });

        _syncPending();

        _message(
          '$name ditolak.',
          error: true,
        );
      } else {
        setState(() {
          isProcessing = false;
        });

        _message(
          _getErrorMessage(response),
          error: true,
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isProcessing = false;
      });

      _message(
        'Terjadi kesalahan saat menolak mitra.',
        error: true,
      );

      debugPrint(
        'REJECT MITRA ERROR: $e',
      );
    }
  }

  // =========================================================
  // VIEW DOCUMENTS
  // =========================================================

  void _viewDocuments(
    Map<String, dynamic> partner,
  ) {
    final List<dynamic> documents =
        partner['documents'] as List<dynamic>? ??
            [];

    showDialog<void>(
      context: context,
      builder: (
        dialogContext,
      ) {
        return AlertDialog(
          title: Text(
            'Berkas ${partner['name'] ?? 'Mitra'}',
          ),
          content: SizedBox(
            width: 520,
            child: documents.isEmpty
                ? const Text(
                    'Tidak ada berkas yang tersedia.',
                  )
                : Column(
                    mainAxisSize:
                        MainAxisSize.min,
                    children:
                        documents
                            .map<Widget>(
                      (doc) {
                        final Map<
                                String,
                                dynamic>
                            document =
                            doc is Map<
                                    String,
                                    dynamic>
                                ? doc
                                : {};

                        final bool valid =
                            document[
                                    'valid'] ==
                                true;

                        return Container(
                          margin:
                              const EdgeInsets.only(
                            bottom: 9,
                          ),
                          padding:
                              const EdgeInsets.all(
                            12,
                          ),
                          decoration:
                              BoxDecoration(
                            border:
                                Border.all(
                              color:
                                  const Color(
                                0xFFE2E8F0,
                              ),
                            ),
                            borderRadius:
                                BorderRadius
                                    .circular(
                              8,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                valid
                                    ? Icons
                                        .check_circle
                                    : Icons
                                        .error_outline,
                                color: valid
                                    ? const Color(
                                        0xFF10B981,
                                      )
                                    : const Color(
                                        0xFFEF4444,
                                      ),
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                              Expanded(
                                child:
                                    Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [
                                    Text(
                                      document[
                                                  'title']
                                              ?.toString() ??
                                          'Dokumen',
                                      style:
                                          const TextStyle(
                                        fontWeight:
                                            FontWeight
                                                .w600,
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 3,
                                    ),
                                    Text(
                                      document[
                                                  'file']
                                              ?.toString() ??
                                          'Tidak tersedia',
                                      maxLines:
                                          2,
                                      overflow:
                                          TextOverflow
                                              .ellipsis,
                                      style:
                                          const TextStyle(
                                        fontSize:
                                            11,
                                        color:
                                            Color(
                                          0xFF64748B,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(
                                width: 8,
                              ),
                              Text(
                                valid
                                    ? 'Sesuai'
                                    : 'Periksa',
                                style:
                                    TextStyle(
                                  fontSize:
                                      11,
                                  fontWeight:
                                      FontWeight
                                          .w700,
                                  color: valid
                                      ? const Color(
                                          0xFF10B981,
                                        )
                                      : const Color(
                                          0xFFEF4444,
                                        ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ).toList(),
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child: const Text(
                'Tutup',
              ),
            ),
          ],
        );
      },
    );
  }

  // =========================================================
  // SYNC PENDING
  // =========================================================

  void _syncPending() {
    AdminActivityData
        .setPendingPartnerCount(
      partners.length,
    );

    widget.onPendingCountChanged?.call(
      partners.length,
    );
  }

  // =========================================================
  // ERROR MESSAGE
  // =========================================================

  String _getErrorMessage(
    dynamic response,
  ) {
    try {
      final body =
          jsonDecode(response.body);

      if (body is Map) {
        if (body['message'] != null) {
          return body['message']
              .toString();
        }

        if (body['error'] != null) {
          return body['error']
              .toString();
        }

        if (body['errors'] is Map) {
          final errors =
              body['errors'] as Map;

          if (errors.isNotEmpty) {
            final firstError =
                errors.values.first;

            if (firstError is List &&
                firstError.isNotEmpty) {
              return firstError.first
                  .toString();
            }
          }
        }
      }
    } catch (_) {}

    switch (response.statusCode) {
      case 400:
        return 'Permintaan tidak valid.';

      case 401:
        return 'Token tidak valid atau sesi login telah berakhir.';

      case 403:
        return 'Anda tidak memiliki akses untuk melakukan tindakan ini.';

      case 404:
        return 'Endpoint atau data mitra tidak ditemukan.';

      case 422:
        return 'Data yang dikirim tidak valid.';

      case 500:
        return 'Terjadi kesalahan pada server Laravel.';

      default:
        return 'Request gagal (${response.statusCode}).';
    }
  }

  // =========================================================
  // FORMAT TIME
  // =========================================================

  String _formatTime(
    dynamic createdAt,
  ) {
    if (createdAt == null) {
      return 'Baru saja';
    }

    try {
      final date =
          DateTime.parse(
        createdAt.toString(),
      );

      final difference =
          DateTime.now()
              .difference(date);

      if (difference.isNegative) {
        return 'Baru saja';
      }

      if (difference.inMinutes < 1) {
        return 'Baru saja';
      }

      if (difference.inMinutes < 60) {
        return '${difference.inMinutes} menit lalu';
      }

      if (difference.inHours < 24) {
        return '${difference.inHours} jam lalu';
      }

      if (difference.inDays < 7) {
        return '${difference.inDays} hari lalu';
      }

      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return 'Baru saja';
    }
  }

  // =========================================================
  // MESSAGE
  // =========================================================

  void _message(
    String text, {
    bool error = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          behavior:
              SnackBarBehavior.floating,
          backgroundColor: error
              ? const Color(0xFFEF4444)
              : const Color(0xFF10B981),
        ),
      );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return AnimatedBuilder(
      animation:
          AdminActivityData.instance,
      builder: (
        context,
        _,
      ) =>
          LayoutBuilder(
        builder: (
          context,
          constraints,
        ) {
          final mobile =
              constraints.maxWidth < 700;

          final tablet =
              constraints.maxWidth >= 700 &&
                  constraints.maxWidth < 1100;

          return Container(
            color:
                const Color(0xFFF4F7FB),
            width:
                double.infinity,
            height:
                double.infinity,
            child: isLoading
                ? const Center(
                    child:
                        CircularProgressIndicator(),
                  )
                : RefreshIndicator(
                    onRefresh:
                        _fetchUnverifiedMitra,
                    child:
                        SingleChildScrollView(
                      physics:
                          const AlwaysScrollableScrollPhysics(),
                      padding:
                          EdgeInsets.fromLTRB(
                        mobile
                            ? 16
                            : 26,
                        mobile
                            ? 18
                            : 28,
                        mobile
                            ? 16
                            : 26,
                        30,
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          Text(
                            'Verifikasi Mitra Baru',
                            style:
                                TextStyle(
                              fontSize: mobile
                                  ? 23
                                  : tablet
                                      ? 25
                                      : 27,
                              fontWeight:
                                  FontWeight
                                      .w700,
                              color:
                                  const Color(
                                0xFF0F172A,
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          Text(
                            '$waitingCount mitra menunggu persetujuan',
                            style:
                                const TextStyle(
                              fontSize: 13,
                              color:
                                  Color(
                                0xFF64748B,
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 22,
                          ),
                          _summary(
                            mobile,
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          partners.isEmpty
                              ? _empty()
                              : _table(
                                  mobile,
                                ),
                        ],
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }

  // =========================================================
  // SUMMARY
  // =========================================================

  Widget _summary(
    bool mobile,
  ) {
    final cards = [
      _summaryCard(
        'Menunggu',
        waitingCount.toString(),
        'Perlu Ditinjau',
        Icons.hourglass_empty,
        const Color(0xFFF59E0B),
        const Color(0xFFFFF7ED),
      ),
      _summaryCard(
        'Disetujui Hari Ini',
        approvedToday.toString(),
        'Mitra Disetujui',
        Icons.check_circle_outline,
        const Color(0xFF10B981),
        const Color(0xFFECFDF5),
      ),
      _summaryCard(
        'Ditolak',
        rejected.toString(),
        'Pendaftaran Ditolak',
        Icons.cancel_outlined,
        const Color(0xFFEF4444),
        const Color(0xFFFEF2F2),
      ),
    ];

    if (mobile) {
      return Column(
        children: [
          for (
            var i = 0;
            i < cards.length;
            i++
          ) ...[
            cards[i],
            if (i <
                cards.length - 1)
              const SizedBox(
                height: 10,
              ),
          ],
        ],
      );
    }

    return Row(
      children: [
        for (
          var i = 0;
          i < cards.length;
          i++
        ) ...[
          Expanded(
            child: cards[i],
          ),
          if (i <
              cards.length - 1)
            const SizedBox(
              width: 10,
            ),
        ],
      ],
    );
  }

  // =========================================================
  // SUMMARY CARD
  // =========================================================

  Widget _summaryCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color iconColor,
    Color iconBg,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(16),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(9),
        border: Border.all(
          color:
              const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration:
                BoxDecoration(
              color: iconBg,
              borderRadius:
                  BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 21,
            ),
          ),
          const SizedBox(
            width: 12,
          ),
          Column(
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight:
                      FontWeight
                          .w700,
                  color: iconColor,
                ),
              ),
              Text(
                title,
                style:
                    const TextStyle(
                  fontSize: 12,
                  fontWeight:
                      FontWeight
                          .w600,
                  color:
                      Color(
                    0xFF334155,
                  ),
                ),
              ),
              Text(
                subtitle,
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
        ],
      ),
    );
  }

  // =========================================================
  // TABLE
  // =========================================================

  Widget _table(
    bool mobile,
  ) {
    if (mobile) {
      return Column(
        children:
            List.generate(
          partners.length,
          (i) => _mobileCard(
            partners[i],
            i,
          ),
        ),
      );
    }

    return Container(
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(9),
        border: Border.all(
          color:
              const Color(
            0xFFE2E8F0,
          ),
        ),
      ),
      child: Column(
        children: [
          _tableHeader(),
          ...List.generate(
            partners.length,
            (i) => _tableRow(
              partners[i],
              i,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // TABLE HEADER
  // =========================================================

  Widget _tableHeader() {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 13,
      ),
      color:
          const Color(0xFFF8FAFC),
      child: const Row(
        children: [
          Expanded(
            flex: 25,
            child: Text(
              'Nama Mitra',
              style: TextStyle(
                fontSize: 11,
                color:
                    Color(
                  0xFF64748B,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 22,
            child: Text(
              'Kategori',
              style: TextStyle(
                fontSize: 11,
                color:
                    Color(
                  0xFF64748B,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 18,
            child: Text(
              'Kota',
              style: TextStyle(
                fontSize: 11,
                color:
                    Color(
                  0xFF64748B,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 15,
            child: Text(
              'Waktu Daftar',
              style: TextStyle(
                fontSize: 11,
                color:
                    Color(
                  0xFF64748B,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 18,
            child: Text(
              'Berkas',
              style: TextStyle(
                fontSize: 11,
                color:
                    Color(
                  0xFF64748B,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 24,
            child: Text(
              'Aksi',
              style: TextStyle(
                fontSize: 11,
                color:
                    Color(
                  0xFF64748B,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // TABLE ROW
  // =========================================================

  Widget _tableRow(
    Map<String, dynamic> p,
    int index,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 13,
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
          Expanded(
            flex: 25,
            child: _name(p),
          ),
          Expanded(
            flex: 22,
            child: Text(
              p['category']
                      ?.toString() ??
                  '-',
              style:
                  const TextStyle(
                fontSize: 11,
                color:
                    Color(
                  0xFF475569,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 18,
            child: Text(
              p['city']
                      ?.toString() ??
                  '-',
              style:
                  const TextStyle(
                fontSize: 11,
                color:
                    Color(
                  0xFF475569,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 15,
            child: Text(
              p['time']
                      ?.toString() ??
                  'Baru saja',
              style:
                  const TextStyle(
                fontSize: 11,
                color:
                    Color(
                  0xFF64748B,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 18,
            child:
                _documentButton(p),
          ),
          Expanded(
            flex: 24,
            child:
                _actions(index),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // NAME
  // =========================================================

  Widget _name(
    Map<String, dynamic> p,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          p['name']?.toString() ??
              'Tanpa Nama',
          style:
              const TextStyle(
            fontSize: 12,
            fontWeight:
                FontWeight.w700,
            color:
                Color(0xFF1E293B),
          ),
        ),
        const SizedBox(
          height: 3,
        ),
        Text(
          p['email']?.toString() ??
              'Tanpa Email',
          maxLines: 1,
          overflow:
              TextOverflow.ellipsis,
          style:
              const TextStyle(
            fontSize: 10,
            color:
                Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // DOCUMENT BUTTON
  // =========================================================

  Widget _documentButton(
    Map<String, dynamic> p,
  ) {
    return Align(
      alignment:
          Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () {
          _viewDocuments(p);
        },
        icon: const Icon(
          Icons.attach_file,
          size: 14,
        ),
        label: const Text(
          'Lihat Berkas',
          style:
              TextStyle(
            fontSize: 10,
          ),
        ),
        style:
            TextButton.styleFrom(
          backgroundColor:
              const Color(
            0xFFF0EAFE,
          ),
          foregroundColor:
              const Color(
            0xFF8B5CF6,
          ),
          padding:
              const EdgeInsets.symmetric(
            horizontal: 9,
            vertical: 8,
          ),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              7,
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // ACTIONS
  // =========================================================

  Widget _actions(
    int index,
  ) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        ElevatedButton.icon(
          onPressed: isProcessing
              ? null
              : () {
                  _approve(index);
                },
          icon: const Icon(
            Icons.check,
            size: 14,
          ),
          label: const Text(
            'Approve',
            style:
                TextStyle(
              fontSize: 10,
            ),
          ),
          style:
              ElevatedButton.styleFrom(
            backgroundColor:
                const Color(
              0xFF10B981,
            ),
            foregroundColor:
                Colors.white,
            disabledBackgroundColor:
                const Color(
              0xFFCBD5E1,
            ),
            elevation: 0,
            padding:
                const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 9,
            ),
            minimumSize:
                Size.zero,
            tapTargetSize:
                MaterialTapTargetSize
                    .shrinkWrap,
            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(
                7,
              ),
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: isProcessing
              ? null
              : () {
                  _reject(index);
                },
          icon: const Icon(
            Icons.close,
            size: 14,
          ),
          label: const Text(
            'Reject',
            style:
                TextStyle(
              fontSize: 10,
            ),
          ),
          style:
              OutlinedButton.styleFrom(
            foregroundColor:
                const Color(
              0xFFEF4444,
            ),
            side:
                const BorderSide(
              color:
                  Color(
                0xFFFCA5A5,
              ),
            ),
            padding:
                const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 9,
            ),
            minimumSize:
                Size.zero,
            tapTargetSize:
                MaterialTapTargetSize
                    .shrinkWrap,
            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(
                7,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // MOBILE CARD
  // =========================================================

  Widget _mobileCard(
    Map<String, dynamic> p,
    int index,
  ) {
    return Container(
      width:
          double.infinity,
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      padding:
          const EdgeInsets.all(15),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(9),
        border: Border.all(
          color:
              const Color(
            0xFFE2E8F0,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _name(p),
          const SizedBox(
            height: 10,
          ),
          Text(
            '${p['category'] ?? 'Umum'} • ${p['city'] ?? 'Indonesia'}',
            style:
                const TextStyle(
              fontSize: 11,
              color:
                  Color(
                0xFF64748B,
              ),
            ),
          ),
          Text(
            p['time']?.toString() ??
                'Baru saja',
            style:
                const TextStyle(
              fontSize: 10,
              color:
                  Color(
                0xFF94A3B8,
              ),
            ),
          ),
          const SizedBox(
            height: 9,
          ),
          _documentButton(p),
          const SizedBox(
            height: 5,
          ),
          _actions(index),
        ],
      ),
    );
  }

  // =========================================================
  // EMPTY
  // =========================================================

  Widget _empty() {
    return Container(
      width:
          double.infinity,
      padding:
          const EdgeInsets.symmetric(
        vertical: 60,
        horizontal: 20,
      ),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(9),
        border: Border.all(
          color:
              const Color(
            0xFFE2E8F0,
          ),
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.verified_outlined,
            size: 42,
            color:
                Color(
              0xFFCBD5E1,
            ),
          ),
          SizedBox(
            height: 12,
          ),
          Text(
            'Tidak ada mitra yang perlu diverifikasi.',
            textAlign:
                TextAlign.center,
            style:
                TextStyle(
              fontSize: 13,
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
}