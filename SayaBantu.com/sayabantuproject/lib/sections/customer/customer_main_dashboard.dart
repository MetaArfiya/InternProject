import 'package:flutter/material.dart';

import '../../../models/sidebar_menu.dart';
import '../../../widgets/customer_sidebar.dart';
import '../../models/job_model.dart';
import '../../models/offer_model.dart';
import '../../screens/Screens_Customer/offer_screen.dart';
import '../../screens/Screens_Customer/partner_profile_screen.dart';
import '../../sections/payment/payment_screen.dart';
import 'customer_dashboard.dart';
import 'notification_screen.dart';
import 'setting_screen.dart';

class CustomerMainDashboard extends StatefulWidget {
  const CustomerMainDashboard({super.key});

  @override
  State<CustomerMainDashboard> createState() =>
      _CustomerMainDashboardState();
}

class _CustomerMainDashboardState extends State<CustomerMainDashboard> {
  SidebarMenu selectedMenu = SidebarMenu.beranda;

  JobModel? selectedJob;
  OfferModel? selectedOffer;
  String? profilePhotoUrl;

  // =========================================================
  // GLOBAL KEY UNTUK CUSTOMER SIDEBAR
  // =========================================================

  final GlobalKey<CustomerSidebarState> _sidebarKey =
      GlobalKey<CustomerSidebarState>();

  // =========================================================
  // CURRENT PAGE
  // =========================================================

  Widget currentPage() {
    switch (selectedMenu) {
      // =====================================================
      // BERANDA
      // =====================================================

      case SidebarMenu.beranda:
        return CustomerDashboard(
          onOpenOffer: (job) {
            setState(() {
              selectedJob = job;
              selectedMenu = SidebarMenu.penawaran;
            });
          },
        );

      // =====================================================
      // PEMBAYARAN
      // =====================================================

      case SidebarMenu.pembayaran:
        return const PaymentScreen(
          role: 'pengguna',
        );

      // =====================================================
      // PENAWARAN
      // =====================================================

      case SidebarMenu.penawaran:
        if (selectedJob == null) {
          return const Center(
            child: Text(
              'Belum ada pekerjaan yang dipilih.\n'
              'Silakan pilih pekerjaan dari Beranda.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          );
        }

        return OfferScreen(
          job: selectedJob!,
          onBack: () {
            setState(() {
              selectedMenu = SidebarMenu.beranda;
            });
          },
          onOpenProfile: (offer) {
            setState(() {
              selectedOffer = offer;
              selectedMenu = SidebarMenu.profilMitra;
            });
          },
          onAccept: (offer) {
            setState(() {
              selectedMenu = SidebarMenu.beranda;
            });
          },
          onReject: (offer) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Penawaran ${offer.name} berhasil ditolak.',
                ),
              ),
            );
          },
        );

      // =====================================================
      // PROFIL MITRA
      // =====================================================

      case SidebarMenu.profilMitra:
        if (selectedOffer == null) {
          return const Center(
            child: Text(
              'Belum ada profil mitra yang dipilih.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          );
        }

        return PartnerProfileScreen(
          mitraId: selectedOffer!.mitraId,
          onFinish: () {
            setState(() {
              selectedMenu = SidebarMenu.penawaran;
            });
          },
        );

      // =====================================================
      // NOTIFIKASI
      // =====================================================

      case SidebarMenu.notifikasi:
        return NotificationScreen();

      // =====================================================
      // PENGATURAN
      // =====================================================

      case SidebarMenu.pengaturan:
        return CustomerSettingScreen(
          onProfileUpdate: () {
            // Refresh tampilan parent
            setState(() {});

            // Refresh data profile di sidebar
            _sidebarKey.currentState?.refreshProfile();
          },
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
        final bool isDesktop = constraints.maxWidth >= 1000;

        return Scaffold(
          // =================================================
          // DRAWER UNTUK MOBILE / TABLET
          // =================================================

          drawer: isDesktop
              ? null
              : Drawer(
                  child: SafeArea(
                    child: CustomerSidebar(
                      key: _sidebarKey,
                      activeMenu: selectedMenu,
                      onMenuSelected: (menu) {
                        setState(() {
                          selectedMenu = menu;
                        });

                        Navigator.pop(context);
                      },
                    ),
                  ),
                ),

          // =================================================
          // APP BAR UNTUK MOBILE / TABLET
          // =================================================

          appBar: isDesktop
              ? null
              : AppBar(
                  title: const Text(
                    'Dashboard Pelanggan',
                  ),
                ),

          // =================================================
          // BODY
          // =================================================

          body: isDesktop
              ? Row(
                  children: [
                    // ---------------------------------------
                    // SIDEBAR
                    // ---------------------------------------

                    CustomerSidebar(
                      key: _sidebarKey,
                      activeMenu: selectedMenu,
                      onMenuSelected: (menu) {
                        setState(() {
                          selectedMenu = menu;
                        });
                      },
                    ),

                    // ---------------------------------------
                    // CONTENT
                    // ---------------------------------------

                    Expanded(
                      child: currentPage(),
                    ),
                  ],
                )
              : currentPage(),
        );
      },
    );
  }
}