import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sayabantu_project/screens/Screens_Landing/landing_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
//import '../../screens/Screens_auth/login_page.dart';
import '../../services/api_service.dart'; 

class CustomerSettingScreen extends StatefulWidget {
  final VoidCallback onProfileUpdate;

  const CustomerSettingScreen({
    super.key,
    required this.onProfileUpdate,
  });

  @override
  State<CustomerSettingScreen> createState() => _CustomerSettingScreenState();
}

class _CustomerSettingScreenState extends State<CustomerSettingScreen> {
  bool jobNotification = true;
  bool isLoading = true;

  String name = "";
  String email = "";
  String phone = "";
  String address = "";

  Uint8List? profileImage;
  final ImagePicker picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    loadProfileFromApi();
  }

  // 🛠️ AMBIL PROFIL DARI API LARAVEL
  // 🛠️ AMBIL PROFIL DARI API LARAVEL
  Future<void> loadProfileFromApi() async {
    try {
      setState(() => isLoading = true);
      
      // Sesuaikan dengan endpoint user yang sedang login (biasanya /user atau /profile)
      final response = await ApiService.get('/user'); 

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final userData = data['user'] ?? data;

        setState(() {
          name = userData['name'] ?? "";
          email = userData['email'] ?? "";
          phone = userData['phone'] ?? "";
          address = userData['address'] ?? "";
          
          int notifStatus = userData['is_notification_enabled'] ?? 1;
          jobNotification = notifStatus == 1;

          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
      print("Error load profile: $e");
    }
  }

  // 🛠️ SIMPAN PERUBAHAN PROFIL KE API LARAVEL
  Future<void> updateProfileToApi(String newName, String newEmail, String newPhone, String newAddress) async {
    try {
      // Sesuaikan endpoint update profil Anda di backend Laravel
      final response = await ApiService.put('/user/profile', {
        'name': newName,
        'email': newEmail,
        'phone': newPhone,
        'address': newAddress,
      });

      if (response.statusCode == 200) {
        await loadProfileFromApi();
        widget.onProfileUpdate();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profil berhasil diperbarui.")),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal memperbarui profil.")),
        );
      }
    } catch (e) {
      print("Error update profile: $e");
    }
  }

  // 🛠️ UPDATE STATUS NOTIFIKASI KE API (Menggunakan rute yang sudah ada di api.php)
  Future<void> updateNotificationStatus(bool value) async {
    try {
      await ApiService.put('/user/notification-setting', {
        'is_notification_enabled': value ? 1 : 0,
      });
    } catch (e) {
      print("Error update notification: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xffF97316))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Pengaturan",
              style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Kelola profil, notifikasi, dan keamanan akun.",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 35),

            /// HEADER PROFIL
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 55,
                    backgroundColor: const Color(0xffFFF3E8),
                    child: const Icon(
                      Icons.person,
                      size: 60,
                      color: Color(0xffF97316),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    name,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    email,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 170,
                    height: 45,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final nameController = TextEditingController(text: name);
                        final emailController = TextEditingController(text: email);
                        final phoneController = TextEditingController(text: phone);
                        final addressController = TextEditingController(text: address);

                        showDialog(
                          context: context,
                          builder: (dialogContext) {
                            return AlertDialog(
                              title: const Text("Edit Profil"),
                              content: SizedBox(
                                width: 450,
                                child: SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TextField(
                                        controller: nameController,
                                        decoration: const InputDecoration(
                                          labelText: "Nama",
                                          prefixIcon: Icon(Icons.person_outline),
                                        ),
                                      ),
                                      const SizedBox(height: 15),
                                      TextField(
                                        controller: emailController,
                                        decoration: const InputDecoration(
                                          labelText: "Email",
                                          prefixIcon: Icon(Icons.email_outlined),
                                        ),
                                      ),
                                      const SizedBox(height: 15),
                                      TextField(
                                        controller: phoneController,
                                        decoration: const InputDecoration(
                                          labelText: "Nomor HP",
                                          prefixIcon: Icon(Icons.phone_outlined),
                                        ),
                                      ),
                                      const SizedBox(height: 15),
                                      TextField(
                                        controller: addressController,
                                        maxLines: 2,
                                        decoration: const InputDecoration(
                                          labelText: "Alamat",
                                          prefixIcon: Icon(Icons.location_on_outlined),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(dialogContext),
                                  child: const Text("Batal"),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xffF97316),
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () async {
                                    Navigator.pop(dialogContext);
                                    await updateProfileToApi(
                                      nameController.text,
                                      emailController.text,
                                      phoneController.text,
                                      addressController.text,
                                    );
                                  },
                                  child: const Text("Simpan"),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text("Edit Profil"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xffF97316),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            /// INFORMASI AKUN
            const Text(
              "Informasi Akun",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 15),
            _buildCard(icon: Icons.person_outline, title: "Nama", subtitle: name),
            _buildCard(icon: Icons.email_outlined, title: "Email", subtitle: email),
            _buildCard(icon: Icons.phone_outlined, title: "Nomor HP", subtitle: phone.isEmpty ? "-" : phone),
            _buildCard(icon: Icons.location_on_outlined, title: "Alamat", subtitle: address.isEmpty ? "-" : address),
            const SizedBox(height: 35),

            /// NOTIFIKASI
            const Text(
              "Notifikasi",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 15),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xffE5E7EB)),
              ),
              child: SwitchListTile(
                value: jobNotification,
                activeColor: const Color(0xffF97316),
                secondary: const Icon(
                  Icons.notifications_active_outlined,
                  color: Color(0xffF97316),
                ),
                title: const Text("Notifikasi Penawaran"),
                subtitle: const Text(
                  "Terima notifikasi ketika mitra mengirim penawaran pada pekerjaan Anda.",
                ),
                onChanged: (value) async {
                  setState(() {
                    jobNotification = value;
                  });
                  await updateNotificationStatus(value);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        value
                            ? "Notifikasi penawaran diaktifkan."
                            : "Notifikasi penawaran dinonaktifkan.",
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 35),

            /// KEAMANAN (Logout)
            const Text(
              "Keamanan",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 15),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xffE5E7EB)),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text(
                      "Logout",
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: const Text("Logout"),
                          content: const Text("Apakah Anda yakin ingin keluar dari akun ini?"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              child: const Text("Batal"),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () async {
                                final prefs = await SharedPreferences.getInstance();
                                await prefs.clear(); // Bersihkan token/sesi lokal

                                if (!mounted) return;
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(builder: (_) => const LandingPage()),
                                  (route) => false,
                                );
                              },
                              child: const Text("Logout"),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xffE5E7EB)),
        ),
        child: ListTile(
          leading: Icon(icon, color: const Color(0xffF97316)),
          title: Text(title),
          subtitle: Text(subtitle),
        ),
      ),
    );
  }
}