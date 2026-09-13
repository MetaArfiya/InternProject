// lib/models/complaint_model.dart

class ComplaintModel {
  final int id;
  final int userId;
  final String userRole;
  final String category;
  final String title;
  final String description;
  final int? jobId;
  final String? jobTitle;
  final String status;
  final String? adminResponse;
  final DateTime? createdAt;
  final DateTime? handledAt;

  ComplaintModel({
    required this.id,
    required this.userId,
    required this.userRole,
    required this.category,
    required this.title,
    required this.description,
    this.jobId,
    this.jobTitle,
    required this.status,
    this.adminResponse,
    this.createdAt,
    this.handledAt,
  });

  // ============================================================
  // KODE PENGADUAN UNTUK UI (PGD-001)
  // ============================================================
  String get code => 'PGD-${id.toString().padLeft(3, '0')}';

  // ============================================================
  // TANGGAL FORMAT INDONESIA
  // ============================================================
  String get formattedDate {
    final date = createdAt ?? DateTime.now();
    const bulan = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${date.day} ${bulan[date.month - 1]} ${date.year}';
  }

  // ============================================================
  // ID PEKERJAAN (untuk display)
  // ============================================================
  String get jobCode {
    if (jobId == null) return '-';
    return 'JOB-${jobId.toString().padLeft(3, '0')}';
  }

  // ============================================================
  // FROM JSON
  // ============================================================
  factory ComplaintModel.fromJson(Map<String, dynamic> json) {
    String? jobTitle;
    if (json['job'] is Map) {
      jobTitle = json['job']['tittle']?.toString() ??
          json['job']['title']?.toString();
    }

    return ComplaintModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      userId: int.tryParse(json['user_id']?.toString() ?? '0') ?? 0,
      userRole: json['user_role']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Lainnya',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      jobId: json['job_id'] != null
          ? int.tryParse(json['job_id'].toString())
          : null,
      jobTitle: jobTitle,
      status: json['status']?.toString() ?? 'Menunggu',
      adminResponse: json['admin_response']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      handledAt: json['handled_at'] != null
          ? DateTime.tryParse(json['handled_at'].toString())
          : null,
    );
  }
}