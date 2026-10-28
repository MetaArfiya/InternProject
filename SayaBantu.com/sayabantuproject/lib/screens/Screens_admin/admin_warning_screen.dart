import 'dart:convert';

import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../theme/app_colors.dart';

class AdminWarningScreen extends StatefulWidget {
  const AdminWarningScreen({super.key});

  @override
  State<AdminWarningScreen> createState() => _AdminWarningScreenState();
}

class _AdminWarningScreenState extends State<AdminWarningScreen> {
  String _role = 'Pelanggan';
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _recipients = [];
  List<Map<String, dynamic>> _letters = [];
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        ApiService.get('/admin/warning-letters/recipients?role=$_role'),
        ApiService.get('/admin/warning-letters'),
      ]);
      final recipientBody = jsonDecode(results[0].body);
      final letterBody = jsonDecode(results[1].body);
      if (!mounted) return;
      if (results[0].statusCode != 200 || recipientBody['success'] != true) {
        setState(() { _loading = false; _error = recipientBody['message']?.toString() ?? 'Gagal memuat penerima.'; });
        return;
      }
      setState(() {
        _recipients = (recipientBody['data'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _letters = results[1].statusCode == 200 && letterBody['success'] == true
            ? (letterBody['data'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList()
            : [];
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() { _loading = false; _error = 'Tidak dapat memuat data surat peringatan.'; });
    }
  }

  Future<void> _selectRole(String role) async {
    if (_role == role) return;
    setState(() { _role = role; _search.clear(); });
    await _load();
  }

  Future<void> _issue(Map<String, dynamic> recipient) async {
    final form = GlobalKey<FormState>();
    final subject = TextEditingController();
    final reason = TextEditingController();
    var level = 1;
    final send = await showDialog<bool>(context: context, builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, refresh) => AlertDialog(
        title: Text('Kirim SP kepada ${recipient['name'] ?? 'Pengguna'}'),
        content: SizedBox(width: 460, child: Form(key: form, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          DropdownButtonFormField<int>(
            value: level,
            decoration: const InputDecoration(labelText: 'Tingkat Surat Peringatan'),
            items: const [1, 2, 3].map((n) => DropdownMenuItem(value: n, child: Text('SP $n'))).toList(),
            onChanged: (value) { if (value != null) refresh(() => level = value); },
          ),
          TextFormField(controller: subject, decoration: const InputDecoration(labelText: 'Judul / Pelanggaran'), validator: (v) => v == null || v.trim().isEmpty ? 'Judul wajib diisi.' : null),
          TextFormField(controller: reason, maxLines: 4, decoration: const InputDecoration(labelText: 'Keterangan'), validator: (v) => v == null || v.trim().isEmpty ? 'Keterangan wajib diisi.' : null),
        ])))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Batal')),
          FilledButton(onPressed: () async {
            if (!form.currentState!.validate()) return;
            try {
              final response = await ApiService.post('/admin/warning-letters', {
                'user_id': recipient['id'], 'recipient_role': _role, 'level': level,
                'subject': subject.text.trim(), 'reason': reason.text.trim(),
              });
              final body = jsonDecode(response.body);
              if (response.statusCode == 201 && body['success'] == true && dialogContext.mounted) {
                Navigator.pop(dialogContext, true);
              } else if (dialogContext.mounted) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text(body['message']?.toString() ?? 'Gagal mengirim SP.')));
              }
            } catch (_) {
              if (dialogContext.mounted) ScaffoldMessenger.of(dialogContext).showSnackBar(const SnackBar(content: Text('Tidak dapat terhubung ke server.')));
            }
          }, child: const Text('Kirim SP')),
        ],
      ),
    ));
    subject.dispose();
    reason.dispose();
    if (send == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('SP berhasil dikirim dan masuk ke notifikasi penerima.')));
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final filtered = _recipients.where((u) => '${u['name']} ${u['email']}'.toLowerCase().contains(query)).toList();
    return Container(
      color: AppColors.sectionAltLight,
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: const EdgeInsets.all(24), children: [
          const Text('Surat Peringatan', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.grey900)),
          const SizedBox(height: 6),
          const Text('Kirim dan pantau SP untuk pelanggan maupun mitra di wilayah tugas Anda.', style: TextStyle(color: AppColors.grey600)),
          const SizedBox(height: 20),
          Wrap(spacing: 10, children: [
            ChoiceChip(label: const Text('Pelanggan'), selected: _role == 'Pelanggan', onSelected: (_) => _selectRole('Pelanggan')),
            ChoiceChip(label: const Text('Mitra'), selected: _role == 'Mitra', onSelected: (_) => _selectRole('Mitra')),
          ]),
          const SizedBox(height: 12),
          TextField(controller: _search, onChanged: (_) => setState(() {}), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Cari nama atau email', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          if (_loading) const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
          else if (_error != null) Card(child: ListTile(title: Text(_error!), trailing: IconButton(onPressed: _load, icon: const Icon(Icons.refresh))))
          else if (filtered.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('Tidak ada pengguna di wilayah tugas ini.')))
          else ...filtered.map((user) => Card(
            child: ListTile(
              leading: CircleAvatar(child: Icon(_role == 'Mitra' ? Icons.handyman_outlined : Icons.person_outline)),
              title: Text(user['name']?.toString() ?? '-'),
              subtitle: Text('${user['email'] ?? '-'}${user['phone'] == null ? '' : '\n${user['phone']}'}'),
              isThreeLine: user['phone'] != null,
              trailing: FilledButton.tonal(onPressed: () => _issue(user), child: const Text('Buat SP')),
            ),
          )),
          const SizedBox(height: 24),
          const Text('SP yang Dikirim', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (_letters.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('Belum ada SP yang dikirim oleh akun Anda.')))
          else ..._letters.map((letter) {
            final user = letter['recipient'] is Map ? letter['recipient'] as Map : {};
            return Card(child: ListTile(
              leading: const Icon(Icons.warning_amber_rounded, color: Colors.deepOrange),
              title: Text('SP ${letter['level']} • ${user['name'] ?? 'Pengguna'}'),
              subtitle: Text('${letter['subject'] ?? ''}\n${letter['reason'] ?? ''}'),
              isThreeLine: true,
              trailing: Text(letter['recipient_role']?.toString() ?? ''),
            ));
          }),
        ]),
      ),
    );
  }
}
