import 'package:flutter/material.dart';

import '../../models/partner_sidebar_menu.dart';
import '../../models/partner_job_model.dart';
import '../../widgets/partner_sidebar.dart';
import '../../sections/partner/partner_dashboard.dart';
import '../../sections/partner/active_offer_screen.dart';
import '../../sections/partner/partner_profile_section.dart';
import '../../sections/partner/partner_setting_screen.dart';
import '../../sections/partner/offer_job_screen.dart';
import '../../sections/payment/payment_screen.dart';
import 'income_screen.dart';

class PartnerMainDashboard extends StatefulWidget {
  const PartnerMainDashboard({super.key});

  @override
  State<PartnerMainDashboard> createState() => _PartnerMainDashboardState();
}

class _PartnerMainDashboardState extends State<PartnerMainDashboard> {
  // Menu yang sedang aktif
  PartnerSidebarMenu selectedMenu =
      PartnerSidebarMenu.cariPekerjaan;

  // Menyimpan pekerjaan yang dipilih oleh mitra
  PartnerJobModel? selectedJob;

  // Key untuk mengakses PartnerSidebarState
  final GlobalKey<PartnerSidebarState> _sidebarKey =
      GlobalKey<PartnerSidebarState>();

  // ============================================================
  // MENENTUKAN HALAMAN BERDASARKAN MENU YANG DIPILIH
  // ============================================================
  Widget currentPage() {
    switch (selectedMenu) {
      // --------------------------------------------------------
      // CARI PEKERJAAN
      // --------------------------------------------------------
      case PartnerSidebarMenu.cariPekerjaan:
        return PartnerDashboard(
          onTakeOffer: (job) {
            setState(() {
              selectedJob = job;
              selectedMenu = PartnerSidebarMenu.offerJob;
            });
          },
        );

      // --------------------------------------------------------
      // BUAT PENAWARAN
      // --------------------------------------------------------
      case PartnerSidebarMenu.offerJob:
        if (selectedJob == null) {
          return const Center(
            child: Text(
              'Silakan pilih pekerjaan terlebih dahulu '
              'dari menu Cari Pekerjaan.',
            ),
          );
        }

        return OfferJobScreen(
          job: selectedJob!,
          onSubmit: () {
            setState(() {
              selectedMenu =
                  PartnerSidebarMenu.penawaranAktif;
            });
          },
          onBack: () {
            setState(() {
              selectedMenu =
                  PartnerSidebarMenu.cariPekerjaan;
            });
          },
        );

      // --------------------------------------------------------
      // PENAWARAN AKTIF
      // --------------------------------------------------------
      case PartnerSidebarMenu.penawaranAktif:
        return const ActiveOfferScreen();

      // --------------------------------------------------------
      // PENGHASILAN
      // --------------------------------------------------------
      case PartnerSidebarMenu.penghasilan:
        return const IncomeScreen();

      // --------------------------------------------------------
      // PEMBAYARAN
      // --------------------------------------------------------
      case PartnerSidebarMenu.pembayaran:
        return const PaymentScreen(
          role: 'mitra',
        );

      // --------------------------------------------------------
      // PROFIL
      // --------------------------------------------------------
      case PartnerSidebarMenu.profile:
        return const PartnerProfileSection();

      // --------------------------------------------------------
      // PENGATURAN
      // --------------------------------------------------------
      case PartnerSidebarMenu.pengaturan:
        return PartnerSettingScreen(
          onProfileUpdate: () {
            // Refresh data profil pada sidebar
            _sidebarKey.currentState?.refreshProfile();

            // Refresh halaman
            setState(() {});
          },
        );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktop = constraints.maxWidth >= 1000;

        return Scaffold(
          // ======================================================
          // DRAWER UNTUK MOBILE / TABLET
          // ======================================================
          drawer: isDesktop
              ? null
              : Drawer(
                  child: SafeArea(
                    child: PartnerSidebar(
                      key: _sidebarKey,
                      activeMenu: selectedMenu,
                      onMenuSelected: (menu) {
                        setState(() {
                          selectedMenu = menu;
                        });

                        // Tutup drawer setelah memilih menu
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ),

          // ======================================================
          // APP BAR MOBILE / TABLET
          // ======================================================
          appBar: isDesktop
              ? null
              : AppBar(
                  title: const Text(
                    'Dashboard Mitra',
                  ),
                ),

          // ======================================================
          // BODY
          // ======================================================
          body: isDesktop
              ? Row(
                  children: [
                    // SIDEBAR DESKTOP
                    PartnerSidebar(
                      key: _sidebarKey,
                      activeMenu: selectedMenu,
                      onMenuSelected: (menu) {
                        setState(() {
                          selectedMenu = menu;
                        });
                      },
                    ),

                    // KONTEN
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