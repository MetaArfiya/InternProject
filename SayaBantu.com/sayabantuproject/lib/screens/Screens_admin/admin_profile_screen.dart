// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class AdminProfileScreen extends StatefulWidget {
//   final VoidCallback? onProfileUpdated;

//   const AdminProfileScreen({
//     super.key,
//     this.onProfileUpdated,
//   });

//   @override
//   State<AdminProfileScreen> createState() =>
//       _AdminProfileScreenState();
// }

// class _AdminProfileScreenState
//     extends State<AdminProfileScreen> {
//   String adminName = 'Admin Operator';
//   String adminEmail = 'admin@sayabantu.com';
//   String adminRole = 'Admin Harian';

//   @override
//   void initState() {
//     super.initState();
//     _loadAdminProfile();
//   }

//   // =========================================================
//   // LOAD PROFILE
//   // =========================================================

//   Future<void> _loadAdminProfile() async {
//     final prefs =
//         await SharedPreferences.getInstance();

//     if (!mounted) return;

//     setState(() {
//       adminName =
//           prefs.getString('name') ??
//               'Admin Operator';

//       adminEmail =
//           prefs.getString('email') ??
//               'admin@sayabantu.com';

//       adminRole =
//           prefs.getString('role') ??
//               'Admin Harian';
//     });
//   }

//   // =========================================================
//   // BUILD
//   // =========================================================

//   @override
//   Widget build(BuildContext context) {
//     return LayoutBuilder(
//       builder: (context, constraints) {
//         final screenWidth =
//             constraints.maxWidth;

//         final isMobile =
//             screenWidth < 700;

//         final isTablet =
//             screenWidth >= 700 &&
//                 screenWidth < 1100;

//         return _buildContent(
//           context,
//           isMobile,
//           isTablet,
//         );
//       },
//     );
//   }

//   // =========================================================
//   // CONTENT
//   // =========================================================

//   Widget _buildContent(
//     BuildContext context,
//     bool isMobile,
//     bool isTablet,
//   ) {
//     return Container(
//       width: double.infinity,
//       height: double.infinity,
//       color: const Color(0xFFF4F7FB),
//       child: SingleChildScrollView(
//         padding: EdgeInsets.fromLTRB(
//           isMobile ? 16 : 26,
//           isMobile ? 18 : 28,
//           isMobile ? 16 : 26,
//           30,
//         ),
//         child: Column(
//           crossAxisAlignment:
//               CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Profil Admin',
//               style: TextStyle(
//                 fontSize:
//                     isMobile ? 23 : 27,
//                 fontWeight:
//                     FontWeight.w700,
//                 color:
//                     const Color(0xFF0F172A),
//               ),
//             ),

//             const SizedBox(height: 5),

//             Text(
//               'Kelola informasi dan keamanan akun admin',
//               style: TextStyle(
//                 fontSize:
//                     isMobile ? 12 : 13,
//                 color:
//                     const Color(0xFF64748B),
//               ),
//             ),

//             const SizedBox(height: 22),

//             _buildProfileCard(
//               context,
//               isMobile,
//             ),

//             const SizedBox(height: 18),

//             _buildAccountCard(
//               isMobile,
//             ),

//             const SizedBox(height: 18),

//             _buildSecurityCard(
//               context,
//               isMobile,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // =========================================================
//   // PROFILE CARD
//   // =========================================================

//   Widget _buildProfileCard(
//     BuildContext context,
//     bool isMobile,
//   ) {
//     return Container(
//       width: double.infinity,
//       padding: EdgeInsets.all(
//         isMobile ? 16 : 22,
//       ),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius:
//             BorderRadius.circular(9),
//         border: Border.all(
//           color:
//               const Color(0xFFDCE3EC),
//         ),
//       ),
//       child: isMobile
//           ? Column(
//               crossAxisAlignment:
//                   CrossAxisAlignment.start,
//               children: [
//                 _profileInfo(),

//                 const SizedBox(
//                   height: 16,
//                 ),

//                 _editButton(context),
//               ],
//             )
//           : Row(
//               children: [
//                 Expanded(
//                   child: _profileInfo(),
//                 ),

//                 _editButton(context),
//               ],
//             ),
//     );
//   }

//   // =========================================================
//   // PROFILE INFO
//   // =========================================================

//   Widget _profileInfo() {
//     return Row(
//       children: [
//         Container(
//           width: 64,
//           height: 64,
//           decoration:
//               const BoxDecoration(
//             color: Color(0xFFF0E9FF),
//             shape: BoxShape.circle,
//           ),
//           child: const Icon(
//             Icons.shield_outlined,
//             color: Color(0xFF7C3AED),
//             size: 32,
//           ),
//         ),

//         const SizedBox(width: 15),

//         Expanded(
//           child: Column(
//             crossAxisAlignment:
//                 CrossAxisAlignment.start,
//             children: [
//               Text(
//                 adminName,
//                 overflow:
//                     TextOverflow.ellipsis,
//                 style: const TextStyle(
//                   fontSize: 18,
//                   fontWeight:
//                       FontWeight.w700,
//                   color:
//                       Color(0xFF111827),
//                 ),
//               ),

//               const SizedBox(height: 5),

//               Text(
//                 adminEmail,
//                 overflow:
//                     TextOverflow.ellipsis,
//                 style: const TextStyle(
//                   fontSize: 12,
//                   color:
//                       Color(0xFF64748B),
//                 ),
//               ),

//               const SizedBox(height: 7),

//               Container(
//                 padding:
//                     const EdgeInsets
//                         .symmetric(
//                   horizontal: 10,
//                   vertical: 5,
//                 ),
//                 decoration:
//                     BoxDecoration(
//                   color:
//                       const Color(
//                           0xFFDCFCE7),
//                   borderRadius:
//                       BorderRadius.circular(
//                           20),
//                 ),
//                 child: Text(
//                   adminRole,
//                   style:
//                       const TextStyle(
//                     fontSize: 10,
//                     fontWeight:
//                         FontWeight.w600,
//                     color:
//                         Color(0xFF16A34A),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   // =========================================================
//   // EDIT BUTTON
//   // =========================================================

//   Widget _editButton(
//     BuildContext context,
//   ) {
//     return ElevatedButton.icon(
//       onPressed: () {
//         _showEditProfileDialog(
//           context,
//         );
//       },
//       icon: const Icon(
//         Icons.edit_outlined,
//         size: 15,
//       ),
//       label: const Text(
//         'Edit Profil',
//         style: TextStyle(
//           fontSize: 11,
//           fontWeight:
//               FontWeight.w600,
//         ),
//       ),
//       style:
//           ElevatedButton.styleFrom(
//         backgroundColor:
//             const Color(0xFF7C3AED),
//         foregroundColor:
//             Colors.white,
//         elevation: 0,
//         padding:
//             const EdgeInsets.symmetric(
//           horizontal: 15,
//           vertical: 12,
//         ),
//         shape:
//             RoundedRectangleBorder(
//           borderRadius:
//               BorderRadius.circular(7),
//         ),
//       ),
//     );
//   }

//   // =========================================================
//   // EDIT PROFILE
//   // =========================================================

//   void _showEditProfileDialog(
//     BuildContext context,
//   ) {
//     final nameController =
//         TextEditingController(
//       text: adminName,
//     );

//     final emailController =
//         TextEditingController(
//       text: adminEmail,
//     );

//     final formKey =
//         GlobalKey<FormState>();

//     showDialog(
//       context: context,
//       builder: (dialogContext) {
//         return AlertDialog(
//           backgroundColor:
//               Colors.white,
//           shape:
//               RoundedRectangleBorder(
//             borderRadius:
//                 BorderRadius.circular(12),
//           ),
//           title: const Text(
//             'Edit Profil',
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight:
//                   FontWeight.w700,
//               color:
//                   Color(0xFF111827),
//             ),
//           ),
//           content: SizedBox(
//             width: 420,
//             child: Form(
//               key: formKey,
//               child: Column(
//                 mainAxisSize:
//                     MainAxisSize.min,
//                 children: [
//                   TextFormField(
//                     controller:
//                         nameController,
//                     decoration:
//                         InputDecoration(
//                       labelText:
//                           'Nama Lengkap',
//                       prefixIcon:
//                           const Icon(
//                         Icons.person_outline,
//                       ),
//                       border:
//                           OutlineInputBorder(
//                         borderRadius:
//                             BorderRadius.circular(
//                                 8),
//                       ),
//                       focusedBorder:
//                           OutlineInputBorder(
//                         borderRadius:
//                             BorderRadius.circular(
//                                 8),
//                         borderSide:
//                             const BorderSide(
//                           color:
//                               Color(0xFF7C3AED),
//                         ),
//                       ),
//                     ),
//                     validator:
//                         (value) {
//                       if (value == null ||
//                           value.trim().isEmpty) {
//                         return 'Nama tidak boleh kosong';
//                       }

//                       return null;
//                     },
//                   ),

//                   const SizedBox(
//                     height: 16,
//                   ),

//                   TextFormField(
//                     controller:
//                         emailController,
//                     keyboardType:
//                         TextInputType
//                             .emailAddress,
//                     decoration:
//                         InputDecoration(
//                       labelText: 'Email',
//                       prefixIcon:
//                           const Icon(
//                         Icons.email_outlined,
//                       ),
//                       border:
//                           OutlineInputBorder(
//                         borderRadius:
//                             BorderRadius.circular(
//                                 8),
//                       ),
//                       focusedBorder:
//                           OutlineInputBorder(
//                         borderRadius:
//                             BorderRadius.circular(
//                                 8),
//                         borderSide:
//                             const BorderSide(
//                           color:
//                               Color(0xFF7C3AED),
//                         ),
//                       ),
//                     ),
//                     validator:
//                         (value) {
//                       if (value == null ||
//                           value.trim().isEmpty) {
//                         return 'Email tidak boleh kosong';
//                       }

//                       if (!value.contains('@')) {
//                         return 'Format email tidak valid';
//                       }

//                       return null;
//                     },
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.pop(
//                   dialogContext,
//                 );
//               },
//               child: const Text(
//                 'Batal',
//                 style: TextStyle(
//                   color:
//                       Color(0xFF64748B),
//                 ),
//               ),
//             ),

//             ElevatedButton(
//               onPressed: () async {
//                 if (!formKey.currentState!
//                     .validate()) {
//                   return;
//                 }

//                 final prefs =
//                     await SharedPreferences
//                         .getInstance();

//                 final newName =
//                     nameController.text
//                         .trim();

//                 final newEmail =
//                     emailController.text
//                         .trim();

//                 await prefs.setString(
//                   'name',
//                   newName,
//                 );

//                 await prefs.setString(
//                   'email',
//                   newEmail,
//                 );

//                 await prefs.setString(
//                   'role',
//                   adminRole,
//                 );

//                 if (!mounted) return;

//                 setState(() {
//                   adminName = newName;
//                   adminEmail = newEmail;
//                 });

//                 // Beritahu AdminLayout
//                 // bahwa profile berubah.
//                 widget.onProfileUpdated
//                     ?.call();

//                 if (!dialogContext.mounted) {
//                   return;
//                 }

//                 Navigator.pop(
//                   dialogContext,
//                 );

//                 ScaffoldMessenger.of(
//                   context,
//                 ).showSnackBar(
//                   const SnackBar(
//                     content: Text(
//                       'Profil berhasil diperbarui',
//                     ),
//                     backgroundColor:
//                         Color(0xFF16A34A),
//                   ),
//                 );
//               },
//               style:
//                   ElevatedButton.styleFrom(
//                 backgroundColor:
//                     const Color(0xFF7C3AED),
//                 foregroundColor:
//                     Colors.white,
//                 elevation: 0,
//                 shape:
//                     RoundedRectangleBorder(
//                   borderRadius:
//                       BorderRadius.circular(7),
//                 ),
//               ),
//               child:
//                   const Text('Simpan'),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   // =========================================================
//   // ACCOUNT CARD
//   // =========================================================

//   Widget _buildAccountCard(
//     bool isMobile,
//   ) {
//     return Container(
//       width: double.infinity,
//       padding: EdgeInsets.all(
//         isMobile ? 16 : 22,
//       ),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius:
//             BorderRadius.circular(9),
//         border: Border.all(
//           color:
//               const Color(0xFFDCE3EC),
//         ),
//       ),
//       child: Column(
//         crossAxisAlignment:
//             CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'Informasi Akun',
//             style: TextStyle(
//               fontSize: 15,
//               fontWeight:
//                   FontWeight.w700,
//               color:
//                   Color(0xFF0F172A),
//             ),
//           ),

//           const SizedBox(height: 4),

//           const Text(
//             'Informasi dasar akun administrator',
//             style: TextStyle(
//               fontSize: 11,
//               color:
//                   Color(0xFF64748B),
//             ),
//           ),

//           const SizedBox(height: 20),

//           if (isMobile)
//             Column(
//               children: [
//                 _infoItem(
//                   Icons.person_outline,
//                   'Nama Lengkap',
//                   adminName,
//                 ),

//                 const SizedBox(
//                   height: 15,
//                 ),

//                 _infoItem(
//                   Icons.email_outlined,
//                   'Email',
//                   adminEmail,
//                 ),

//                 const SizedBox(
//                   height: 15,
//                 ),

//                 _infoItem(
//                   Icons
//                       .admin_panel_settings_outlined,
//                   'Level Akses',
//                   adminRole,
//                 ),

//                 const SizedBox(
//                   height: 15,
//                 ),

//                 _infoItem(
//                   Icons.check_circle_outline,
//                   'Status Akun',
//                   'Aktif',
//                   valueColor:
//                       const Color(
//                           0xFF16A34A),
//                 ),
//               ],
//             )
//           else
//             Row(
//               children: [
//                 Expanded(
//                   child: Column(
//                     children: [
//                       _infoItem(
//                         Icons.person_outline,
//                         'Nama Lengkap',
//                         adminName,
//                       ),

//                       const SizedBox(
//                         height: 18,
//                       ),

//                       _infoItem(
//                         Icons
//                             .admin_panel_settings_outlined,
//                         'Level Akses',
//                         adminRole,
//                       ),
//                     ],
//                   ),
//                 ),

//                 const SizedBox(
//                   width: 40,
//                 ),

//                 Expanded(
//                   child: Column(
//                     children: [
//                       _infoItem(
//                         Icons.email_outlined,
//                         'Email',
//                         adminEmail,
//                       ),

//                       const SizedBox(
//                         height: 18,
//                       ),

//                       _infoItem(
//                         Icons.check_circle_outline,
//                         'Status Akun',
//                         'Aktif',
//                         valueColor:
//                             const Color(
//                                 0xFF16A34A),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//         ],
//       ),
//     );
//   }

//   // =========================================================
//   // INFO ITEM
//   // =========================================================

//   Widget _infoItem(
//     IconData icon,
//     String label,
//     String value, {
//     Color? valueColor,
//   }) {
//     return Row(
//       crossAxisAlignment:
//           CrossAxisAlignment.start,
//       children: [
//         Container(
//           width: 38,
//           height: 38,
//           decoration:
//               BoxDecoration(
//             color:
//                 const Color(0xFFF8FAFC),
//             borderRadius:
//                 BorderRadius.circular(8),
//           ),
//           child: Icon(
//             icon,
//             size: 18,
//             color:
//                 const Color(0xFF64748B),
//           ),
//         ),

//         const SizedBox(width: 10),

//         Expanded(
//           child: Column(
//             crossAxisAlignment:
//                 CrossAxisAlignment.start,
//             children: [
//               Text(
//                 label,
//                 style:
//                     const TextStyle(
//                   fontSize: 10,
//                   color:
//                       Color(0xFF94A3B8),
//                 ),
//               ),

//               const SizedBox(height: 4),

//               Text(
//                 value,
//                 style: TextStyle(
//                   fontSize: 12,
//                   fontWeight:
//                       FontWeight.w600,
//                   color: valueColor ??
//                       const Color(
//                           0xFF334155),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   // =========================================================
//   // SECURITY CARD
//   // =========================================================

//   Widget _buildSecurityCard(
//     BuildContext context,
//     bool isMobile,
//   ) {
//     return Container(
//       width: double.infinity,
//       padding: EdgeInsets.all(
//         isMobile ? 16 : 22,
//       ),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius:
//             BorderRadius.circular(9),
//         border: Border.all(
//           color:
//               const Color(0xFFDCE3EC),
//         ),
//       ),
//       child: Column(
//         crossAxisAlignment:
//             CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'Keamanan Akun',
//             style: TextStyle(
//               fontSize: 15,
//               fontWeight:
//                   FontWeight.w700,
//               color:
//                   Color(0xFF0F172A),
//             ),
//           ),

//           const SizedBox(height: 4),

//           const Text(
//             'Pengaturan keamanan akun administrator',
//             style: TextStyle(
//               fontSize: 11,
//               color:
//                   Color(0xFF64748B),
//             ),
//           ),

//           const SizedBox(height: 18),

//           _securityItem(
//             context,
//             Icons.lock_outline,
//             'Kata Sandi',
//             'Kata sandi dapat diperbarui',
//             'Ubah',
//             const Color(0xFF7C3AED),
//           ),

//           const Divider(
//             height: 1,
//             color:
//                 Color(0xFFE2E8F0),
//           ),

//           _securityItem(
//             context,
//             Icons.verified_user_outlined,
//             'Verifikasi Akun',
//             'Akun administrator telah terverifikasi',
//             'Terverifikasi',
//             const Color(0xFF16A34A),
//           ),
//         ],
//       ),
//     );
//   }

//   // =========================================================
//   // SECURITY ITEM
//   // =========================================================

//   Widget _securityItem(
//     BuildContext context,
//     IconData icon,
//     String title,
//     String description,
//     String action,
//     Color actionColor,
//   ) {
//     return Padding(
//       padding:
//           const EdgeInsets.symmetric(
//         vertical: 12,
//       ),
//       child: Row(
//         children: [
//           Container(
//             width: 38,
//             height: 38,
//             decoration:
//                 BoxDecoration(
//               color:
//                   const Color(0xFFF8FAFC),
//               borderRadius:
//                   BorderRadius.circular(8),
//             ),
//             child: Icon(
//               icon,
//               size: 18,
//               color:
//                   const Color(0xFF64748B),
//             ),
//           ),

//           const SizedBox(width: 10),

//           Expanded(
//             child: Column(
//               crossAxisAlignment:
//                   CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   title,
//                   style:
//                       const TextStyle(
//                     fontSize: 12,
//                     fontWeight:
//                         FontWeight.w600,
//                     color:
//                         Color(0xFF334155),
//                   ),
//                 ),

//                 const SizedBox(height: 3),

//                 Text(
//                   description,
//                   style:
//                       const TextStyle(
//                     fontSize: 10,
//                     color:
//                         Color(0xFF94A3B8),
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           const SizedBox(width: 10),

//           OutlinedButton(
//             onPressed: () {
//               if (title == 'Kata Sandi') {
//                 _showChangePasswordDialog(
//                   context,
//                 );
//               }
//             },
//             style:
//                 OutlinedButton.styleFrom(
//               foregroundColor:
//                   actionColor,
//               side: BorderSide(
//                 color: actionColor,
//               ),
//               padding:
//                   const EdgeInsets.symmetric(
//                 horizontal: 12,
//                 vertical: 8,
//               ),
//               minimumSize: Size.zero,
//               tapTargetSize:
//                   MaterialTapTargetSize
//                       .shrinkWrap,
//               shape:
//                   RoundedRectangleBorder(
//                 borderRadius:
//                     BorderRadius.circular(7),
//               ),
//             ),
//             child: Text(
//               action,
//               style:
//                   const TextStyle(
//                 fontSize: 10,
//                 fontWeight:
//                     FontWeight.w600,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // =========================================================
//   // CHANGE PASSWORD
//   // =========================================================

//   void _showChangePasswordDialog(
//     BuildContext context,
//   ) {
//     final formKey =
//         GlobalKey<FormState>();

//     final oldPasswordController =
//         TextEditingController();

//     final newPasswordController =
//         TextEditingController();

//     final confirmPasswordController =
//         TextEditingController();

//     showDialog(
//       context: context,
//       builder: (dialogContext) {
//         return AlertDialog(
//           backgroundColor:
//               Colors.white,
//           shape:
//               RoundedRectangleBorder(
//             borderRadius:
//                 BorderRadius.circular(12),
//           ),

//           title: const Text(
//             'Ubah Kata Sandi',
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight:
//                   FontWeight.w700,
//             ),
//           ),

//           content: SizedBox(
//             width: 420,
//             child: Form(
//               key: formKey,
//               child: Column(
//                 mainAxisSize:
//                     MainAxisSize.min,
//                 children: [
//                   TextFormField(
//                     controller:
//                         oldPasswordController,
//                     obscureText: true,
//                     decoration:
//                         const InputDecoration(
//                       labelText:
//                           'Kata Sandi Lama',
//                       prefixIcon:
//                           Icon(
//                         Icons.lock_outline,
//                       ),
//                     ),
//                     validator: (value) {
//                       if (value == null ||
//                           value.isEmpty) {
//                         return 'Masukkan kata sandi lama';
//                       }

//                       return null;
//                     },
//                   ),

//                   const SizedBox(
//                     height: 14,
//                   ),

//                   TextFormField(
//                     controller:
//                         newPasswordController,
//                     obscureText: true,
//                     decoration:
//                         const InputDecoration(
//                       labelText:
//                           'Kata Sandi Baru',
//                       prefixIcon:
//                           Icon(
//                         Icons.lock_outline,
//                       ),
//                     ),
//                     validator: (value) {
//                       if (value == null ||
//                           value.length < 6) {
//                         return 'Minimal 6 karakter';
//                       }

//                       return null;
//                     },
//                   ),

//                   const SizedBox(
//                     height: 14,
//                   ),

//                   TextFormField(
//                     controller:
//                         confirmPasswordController,
//                     obscureText: true,
//                     decoration:
//                         const InputDecoration(
//                       labelText:
//                           'Konfirmasi Kata Sandi',
//                       prefixIcon:
//                           Icon(
//                         Icons.lock_outline,
//                       ),
//                     ),
//                     validator: (value) {
//                       if (value !=
//                           newPasswordController
//                               .text) {
//                         return 'Kata sandi tidak sama';
//                       }

//                       return null;
//                     },
//                   ),
//                 ],
//               ),
//             ),
//           ),

//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.pop(
//                   dialogContext,
//                 );
//               },
//               child:
//                   const Text('Batal'),
//             ),

//             ElevatedButton(
//               onPressed: () async {
//                 if (!formKey.currentState!
//                     .validate()) {
//                   return;
//                 }

//                 final prefs =
//                     await SharedPreferences
//                         .getInstance();

//                 final oldPassword =
//                     prefs.getString(
//                           'password',
//                         ) ??
//                         prefs.getString(
//                           'admin_password',
//                         ) ??
//                         'admin123';

//                 if (oldPassword !=
//                     oldPasswordController
//                         .text) {
//                   if (!dialogContext.mounted) {
//                     return;
//                   }

//                   ScaffoldMessenger.of(
//                     dialogContext,
//                   ).showSnackBar(
//                     const SnackBar(
//                       content: Text(
//                         'Kata sandi lama salah',
//                       ),
//                       backgroundColor:
//                           Color(0xFFEF4444),
//                     ),
//                   );

//                   return;
//                 }

//                 await prefs.setString(
//                   'password',
//                   newPasswordController
//                       .text,
//                 );

//                 await prefs.remove(
//                   'admin_password',
//                 );

//                 if (!dialogContext.mounted) {
//                   return;
//                 }

//                 Navigator.pop(
//                   dialogContext,
//                 );

//                 ScaffoldMessenger.of(
//                   context,
//                 ).showSnackBar(
//                   const SnackBar(
//                     content: Text(
//                       'Kata sandi berhasil diubah',
//                     ),
//                     backgroundColor:
//                         Color(0xFF16A34A),
//                   ),
//                 );
//               },
//               style:
//                   ElevatedButton.styleFrom(
//                 backgroundColor:
//                     const Color(0xFF7C3AED),
//                 foregroundColor:
//                     Colors.white,
//               ),
//               child:
//                   const Text('Simpan'),
//             ),
//           ],
//         );
//       },
//     );
//   }
// }

import 'dart:convert';
import 'package:flutter/material.dart';

import '../../services/api_service.dart';

class AdminProfileScreen extends StatefulWidget {
  final VoidCallback? onProfileUpdated;

  const AdminProfileScreen({
    super.key,
    this.onProfileUpdated,
  });

  @override
  State<AdminProfileScreen> createState() =>
      _AdminProfileScreenState();
}

class _AdminProfileScreenState
    extends State<AdminProfileScreen> {
  String adminName = 'Memuat...';
  String adminEmail = 'Memuat...';
  String adminRole = 'Memuat...';

  bool isLoading = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadAdminProfile();
  }

  // =========================================================
  // LOAD PROFILE DARI DATABASE
  // =========================================================

  Future<void> _loadAdminProfile() async {
  try {
    final response = await ApiService.get('/user');

    if (!mounted) return;

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final user =
          data['data'] ??
          data['user'] ??
          data;

      setState(() {
        adminName =
            user['name']?.toString() ?? 'Admin';

        adminEmail =
            user['email']?.toString() ?? '-';

        adminRole =
            user['role']?.toString() ??
            user['role_name']?.toString() ??
            'Admin';

        isLoading = false;
      });

      debugPrint(
        'ADMIN PROFILE: $user',
      );
    } else {
      setState(() {
        isLoading = false;
      });

      debugPrint(
        'GET /user ERROR: '
        '${response.statusCode} '
        '${response.body}',
      );

      _showMessage(
        'Gagal mengambil data profil.',
        error: true,
      );
    }
  } catch (e) {
    if (!mounted) return;

    setState(() {
      isLoading = false;
    });

    debugPrint(
      'LOAD ADMIN PROFILE ERROR: $e',
    );

    _showMessage(
      'Terjadi kesalahan saat mengambil profil.',
      error: true,
    );
  }
}

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
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
        padding: EdgeInsets.fromLTRB(
          isMobile ? 16 : 26,
          isMobile ? 18 : 28,
          isMobile ? 16 : 26,
          30,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              'Profil Admin',
              style: TextStyle(
                fontSize:
                    isMobile ? 23 : 27,
                fontWeight:
                    FontWeight.w700,
                color:
                    const Color(0xFF0F172A),
              ),
            ),

            const SizedBox(height: 5),

            Text(
              'Kelola informasi dan keamanan akun admin',
              style: TextStyle(
                fontSize:
                    isMobile ? 12 : 13,
                color:
                    const Color(0xFF64748B),
              ),
            ),

            const SizedBox(height: 22),

            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child:
                      CircularProgressIndicator(),
                ),
              )
            else ...[
              _buildProfileCard(
                context,
                isMobile,
              ),

              const SizedBox(height: 18),

              _buildAccountCard(
                isMobile,
              ),

              const SizedBox(height: 18),

              _buildSecurityCard(
                context,
                isMobile,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // =========================================================
  // PROFILE CARD
  // =========================================================

  Widget _buildProfileCard(
    BuildContext context,
    bool isMobile,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        isMobile ? 16 : 22,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(9),
        border: Border.all(
          color:
              const Color(0xFFDCE3EC),
        ),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                _profileInfo(),

                const SizedBox(height: 16),

                _editButton(context),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: _profileInfo(),
                ),

                _editButton(context),
              ],
            ),
    );
  }

  // =========================================================
  // PROFILE INFO
  // =========================================================

  Widget _profileInfo() {
    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration:
              const BoxDecoration(
            color: Color(0xFFF0E9FF),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.shield_outlined,
            color: Color(0xFF7C3AED),
            size: 32,
          ),
        ),

        const SizedBox(width: 15),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                adminName,
                overflow:
                    TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.w700,
                  color:
                      Color(0xFF111827),
                ),
              ),

              const SizedBox(height: 5),

              Text(
                adminEmail,
                overflow:
                    TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color:
                      Color(0xFF64748B),
                ),
              ),

              const SizedBox(height: 7),

              Container(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                          0xFFDCFCE7),
                  borderRadius:
                      BorderRadius.circular(
                          20),
                ),
                child: Text(
                  adminRole,
                  style:
                      const TextStyle(
                    fontSize: 10,
                    fontWeight:
                        FontWeight.w600,
                    color:
                        Color(0xFF16A34A),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =========================================================
  // EDIT BUTTON
  // =========================================================

  Widget _editButton(
    BuildContext context,
  ) {
    return ElevatedButton.icon(
      onPressed: isSaving
          ? null
          : () {
              _showEditProfileDialog(
                context,
              );
            },
      icon: const Icon(
        Icons.edit_outlined,
        size: 15,
      ),
      label: const Text(
        'Edit Profil',
        style: TextStyle(
          fontSize: 11,
          fontWeight:
              FontWeight.w600,
        ),
      ),
      style:
          ElevatedButton.styleFrom(
        backgroundColor:
            const Color(0xFF7C3AED),
        foregroundColor:
            Colors.white,
        elevation: 0,
        padding:
            const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 12,
        ),
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(7),
        ),
      ),
    );
  }

  // =========================================================
  // EDIT PROFILE
  // =========================================================

  void _showEditProfileDialog(
    BuildContext context,
  ) {
    final nameController =
        TextEditingController(
      text: adminName,
    );

    final emailController =
        TextEditingController(
      text: adminEmail,
    );

    final formKey =
        GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor:
              Colors.white,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(12),
          ),
          title: const Text(
            'Edit Profil',
            style: TextStyle(
              fontSize: 18,
              fontWeight:
                  FontWeight.w700,
              color:
                  Color(0xFF111827),
            ),
          ),
          content: SizedBox(
            width: 420,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  TextFormField(
                    controller:
                        nameController,
                    decoration:
                        InputDecoration(
                      labelText:
                          'Nama Lengkap',
                      prefixIcon:
                          const Icon(
                        Icons
                            .person_outline,
                      ),
                      border:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius
                                .circular(8),
                      ),
                    ),
                    validator:
                        (value) {
                      if (value == null ||
                          value
                              .trim()
                              .isEmpty) {
                        return 'Nama tidak boleh kosong';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  TextFormField(
                    controller:
                        emailController,
                    keyboardType:
                        TextInputType
                            .emailAddress,
                    decoration:
                        InputDecoration(
                      labelText: 'Email',
                      prefixIcon:
                          const Icon(
                        Icons
                            .email_outlined,
                      ),
                      border:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius
                                .circular(8),
                      ),
                    ),
                    validator:
                        (value) {
                      if (value == null ||
                          value
                              .trim()
                              .isEmpty) {
                        return 'Email tidak boleh kosong';
                      }

                      if (!value
                          .contains('@')) {
                        return 'Format email tidak valid';
                      }

                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop();
              },
              child: const Text(
                'Batal',
              ),
            ),

            ElevatedButton(
              onPressed: () async {
                if (!formKey
                    .currentState!
                    .validate()) {
                  return;
                }

                final newName =
                    nameController.text
                        .trim();

                final newEmail =
                    emailController.text
                        .trim();

                await _updateProfile(
                  dialogContext,
                  newName,
                  newEmail,
                );
              },
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(
                        0xFF7C3AED),
                foregroundColor:
                    Colors.white,
              ),
              child:
                  const Text('Simpan'),
            ),
          ],
        );
      },
    ).whenComplete(() {
      nameController.dispose();
      emailController.dispose();
    });
  }

  // =========================================================
  // UPDATE PROFILE KE DATABASE
  // =========================================================

  Future<void> _updateProfile(
    BuildContext dialogContext,
    String newName,
    String newEmail,
  ) async {
    if (isSaving) return;

    setState(() {
      isSaving = true;
    });

    try {
      final response =
          await ApiService.put(
        '/user/profile',
        {
          'name': newName,
          'email': newEmail,
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          adminName = newName;
          adminEmail = newEmail;
          isSaving = false;
        });

        if (dialogContext.mounted) {
          Navigator.of(
            dialogContext,
          ).pop();
        }

        widget.onProfileUpdated
            ?.call();

        _showMessage(
          'Profil berhasil diperbarui.',
        );
      } else {
        setState(() {
          isSaving = false;
        });

        _showMessage(
          'Gagal memperbarui profil.',
          error: true,
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      debugPrint(
        'UPDATE PROFILE ERROR: $e',
      );

      _showMessage(
        'Terjadi kesalahan saat memperbarui profil.',
        error: true,
      );
    }
  }

  // =========================================================
  // ACCOUNT CARD
  // =========================================================

  Widget _buildAccountCard(
    bool isMobile,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        isMobile ? 16 : 22,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(9),
        border: Border.all(
          color:
              const Color(0xFFDCE3EC),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Informasi Akun',
            style: TextStyle(
              fontSize: 15,
              fontWeight:
                  FontWeight.w700,
              color:
                  Color(0xFF0F172A),
            ),
          ),

          const SizedBox(height: 4),

          const Text(
            'Informasi dasar akun administrator',
            style: TextStyle(
              fontSize: 11,
              color:
                  Color(0xFF64748B),
            ),
          ),

          const SizedBox(height: 20),

          if (isMobile)
            Column(
              children: [
                _infoItem(
                  Icons.person_outline,
                  'Nama Lengkap',
                  adminName,
                ),

                const SizedBox(
                  height: 15,
                ),

                _infoItem(
                  Icons.email_outlined,
                  'Email',
                  adminEmail,
                ),

                const SizedBox(
                  height: 15,
                ),

                _infoItem(
                  Icons
                      .admin_panel_settings_outlined,
                  'Level Akses',
                  adminRole,
                ),

                const SizedBox(
                  height: 15,
                ),

                _infoItem(
                  Icons
                      .check_circle_outline,
                  'Status Akun',
                  'Aktif',
                  valueColor:
                      const Color(
                          0xFF16A34A),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _infoItem(
                        Icons.person_outline,
                        'Nama Lengkap',
                        adminName,
                      ),

                      const SizedBox(
                        height: 18,
                      ),

                      _infoItem(
                        Icons
                            .admin_panel_settings_outlined,
                        'Level Akses',
                        adminRole,
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  width: 40,
                ),

                Expanded(
                  child: Column(
                    children: [
                      _infoItem(
                        Icons.email_outlined,
                        'Email',
                        adminEmail,
                      ),

                      const SizedBox(
                        height: 18,
                      ),

                      _infoItem(
                        Icons
                            .check_circle_outline,
                        'Status Akun',
                        'Aktif',
                        valueColor:
                            const Color(
                                0xFF16A34A),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // =========================================================
  // INFO ITEM
  // =========================================================

  Widget _infoItem(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration:
              BoxDecoration(
            color:
                const Color(0xFFF8FAFC),
            borderRadius:
                BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color:
                const Color(0xFF64748B),
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style:
                    const TextStyle(
                  fontSize: 10,
                  color:
                      Color(0xFF94A3B8),
                ),
              ),

              const SizedBox(height: 4),

              Text(
                value,
                overflow:
                    TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      FontWeight.w600,
                  color: valueColor ??
                      const Color(
                          0xFF334155),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =========================================================
  // SECURITY CARD
  // =========================================================

  Widget _buildSecurityCard(
    BuildContext context,
    bool isMobile,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        isMobile ? 16 : 22,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(9),
        border: Border.all(
          color:
              const Color(0xFFDCE3EC),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Keamanan Akun',
            style: TextStyle(
              fontSize: 15,
              fontWeight:
                  FontWeight.w700,
              color:
                  Color(0xFF0F172A),
            ),
          ),

          const SizedBox(height: 4),

          const Text(
            'Pengaturan keamanan akun administrator',
            style: TextStyle(
              fontSize: 11,
              color:
                  Color(0xFF64748B),
            ),
          ),

          const SizedBox(height: 18),

          _securityItem(
            context,
            Icons.lock_outline,
            'Kata Sandi',
            'Kata sandi dapat diperbarui',
            'Ubah',
            const Color(0xFF7C3AED),
          ),

          const Divider(
            height: 1,
            color:
                Color(0xFFE2E8F0),
          ),

          _securityItem(
            context,
            Icons
                .verified_user_outlined,
            'Verifikasi Akun',
            'Akun administrator telah terverifikasi',
            'Terverifikasi',
            const Color(0xFF16A34A),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // SECURITY ITEM
  // =========================================================

  Widget _securityItem(
    BuildContext context,
    IconData icon,
    String title,
    String description,
    String action,
    Color actionColor,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 12,
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration:
                BoxDecoration(
              color:
                  const Color(0xFFF8FAFC),
              borderRadius:
                  BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 18,
              color:
                  const Color(0xFF64748B),
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style:
                      const TextStyle(
                    fontSize: 12,
                    fontWeight:
                        FontWeight.w600,
                    color:
                        Color(0xFF334155),
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  description,
                  style:
                      const TextStyle(
                    fontSize: 10,
                    color:
                        Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          OutlinedButton(
            onPressed: title ==
                    'Kata Sandi'
                ? () {
                    _showChangePasswordDialog(
                      context,
                    );
                  }
                : null,
            style:
                OutlinedButton.styleFrom(
              foregroundColor:
                  actionColor,
              side: BorderSide(
                color: actionColor,
              ),
              padding:
                  const EdgeInsets
                      .symmetric(
                horizontal: 12,
                vertical: 8,
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
                        7),
              ),
            ),
            child: Text(
              action,
              style:
                  const TextStyle(
                fontSize: 10,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // CHANGE PASSWORD
  // =========================================================

  void _showChangePasswordDialog(
    BuildContext context,
  ) {
    final formKey =
        GlobalKey<FormState>();

    final oldPasswordController =
        TextEditingController();

    final newPasswordController =
        TextEditingController();

    final confirmPasswordController =
        TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor:
              Colors.white,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(12),
          ),
          title: const Text(
            'Ubah Kata Sandi',
            style: TextStyle(
              fontSize: 18,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
          content: SizedBox(
            width: 420,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  TextFormField(
                    controller:
                        oldPasswordController,
                    obscureText: true,
                    decoration:
                        const InputDecoration(
                      labelText:
                          'Kata Sandi Lama',
                      prefixIcon:
                          Icon(
                        Icons.lock_outline,
                      ),
                    ),
                    validator:
                        (value) {
                      if (value == null ||
                          value.isEmpty) {
                        return 'Masukkan kata sandi lama';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(
                    height: 14,
                  ),

                  TextFormField(
                    controller:
                        newPasswordController,
                    obscureText: true,
                    decoration:
                        const InputDecoration(
                      labelText:
                          'Kata Sandi Baru',
                      prefixIcon:
                          Icon(
                        Icons.lock_outline,
                      ),
                    ),
                    validator:
                        (value) {
                      if (value == null ||
                          value.length < 6) {
                        return 'Minimal 6 karakter';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(
                    height: 14,
                  ),

                  TextFormField(
                    controller:
                        confirmPasswordController,
                    obscureText: true,
                    decoration:
                        const InputDecoration(
                      labelText:
                          'Konfirmasi Kata Sandi',
                      prefixIcon:
                          Icon(
                        Icons.lock_outline,
                      ),
                    ),
                    validator:
                        (value) {
                      if (value !=
                          newPasswordController
                              .text) {
                        return 'Kata sandi tidak sama';
                      }

                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop();
              },
              child:
                  const Text('Batal'),
            ),

            ElevatedButton(
              onPressed: () async {
                if (!formKey
                    .currentState!
                    .validate()) {
                  return;
                }

                await _changePassword(
                  dialogContext,
                  oldPasswordController
                      .text,
                  newPasswordController
                      .text,
                  confirmPasswordController
                      .text,
                );
              },
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(
                        0xFF7C3AED),
                foregroundColor:
                    Colors.white,
              ),
              child:
                  const Text('Simpan'),
            ),
          ],
        );
      },
    ).whenComplete(() {
      oldPasswordController.dispose();
      newPasswordController.dispose();
      confirmPasswordController.dispose();
    });
  }

  // =========================================================
  // CHANGE PASSWORD KE DATABASE
  // =========================================================

  Future<void> _changePassword(
    BuildContext dialogContext,
    String oldPassword,
    String newPassword,
    String confirmation,
  ) async {
    try {
      final response =
          await ApiService.post(
        '/change-password',
        {
          'current_password':
              oldPassword,
          'new_password':
              newPassword,
          'new_password_confirmation':
              confirmation,
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        if (dialogContext.mounted) {
          Navigator.of(
            dialogContext,
          ).pop();
        }

        _showMessage(
          'Kata sandi berhasil diubah.',
        );
      } else {
        _showMessage(
          'Gagal mengubah kata sandi.',
          error: true,
        );
      }
    } catch (e) {
      if (!mounted) return;

      debugPrint(
        'CHANGE PASSWORD ERROR: $e',
      );

      _showMessage(
        'Terjadi kesalahan saat mengubah kata sandi.',
        error: true,
      );
    }
  }

  // =========================================================
  // MESSAGE
  // =========================================================

  void _showMessage(
    String message, {
    bool error = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error
            ? const Color(0xFFEF4444)
            : const Color(0xFF16A34A),
      ),
    );
  }
}