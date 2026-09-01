import 'package:flutter/material.dart';

import '../../models/partner_sidebar_menu.dart';
import '../../models/partner_job_model.dart';

import '../../widgets/partner_sidebar.dart';

import '../../sections/partner/partner_dashboard.dart';
import '../../sections/partner/active_offer_screen.dart';
import '../../sections/partner/partner_profile_section.dart';
import '../../sections/partner/partner_setting_screen.dart';
import '../../sections/partner/offer_job_screen.dart';
import 'income_screen.dart';

class PartnerMainDashboard extends StatefulWidget {
  const PartnerMainDashboard({super.key});

  @override
  State<PartnerMainDashboard> createState() => _PartnerMainDashboardState();
}

class _PartnerMainDashboardState extends State<PartnerMainDashboard> {
  PartnerSidebarMenu selectedMenu = PartnerSidebarMenu.cariPekerjaan;
  PartnerJobModel? selectedJob;

  Widget currentPage() {
    switch (selectedMenu) {
      case PartnerSidebarMenu.cariPekerjaan:
        return PartnerDashboard(
          onTakeOffer: (job) {
            setState(() {
              selectedJob = job;
              selectedMenu = PartnerSidebarMenu.offerJob;
            });
          },
        );

      case PartnerSidebarMenu.offerJob:
        if (selectedJob == null) {
          return const Center(
            child: Text("Silakan pilih pekerjaan terlebih dahulu dari menu Cari Pekerjaan."),
          );
        }

        return OfferJobScreen(
          // Tambahkan .toJobModel() di sini untuk mengubah tipe data
          job: selectedJob!, 
          onSubmit: () {
            setState(() {
              selectedMenu = PartnerSidebarMenu.penawaranAktif;
            });
          },
          onBack: () {
            setState(() {
              selectedMenu = PartnerSidebarMenu.cariPekerjaan;
            });
          },
        );

      case PartnerSidebarMenu.penawaranAktif:
        return const ActiveOfferScreen();

      case PartnerSidebarMenu.penghasilan: 
        return const IncomeScreen();

      case PartnerSidebarMenu.profile: 
        return const PartnerProfileSection();

      case PartnerSidebarMenu.pengaturan:
        return PartnerSettingScreen(
          // FIX ERROR 3: Menambahkan callback wajib onProfileUpdate
          onProfileUpdate: () {
            setState(() {
              // Aksi saat profil berhasil diupdate, misal refresh data
            });
          },
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktop = constraints.maxWidth >= 1000;

        return Scaffold(
          drawer: isDesktop
              ? null
              : Drawer(
                  child: SafeArea(
                    child: PartnerSidebar(
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
          appBar: isDesktop
              ? null
              : AppBar(
                  title: const Text("Dashboard Mitra"),
                ),
          body: isDesktop
              ? Row(
                  children: [
                    PartnerSidebar(
                      activeMenu: selectedMenu,
                      onMenuSelected: (menu) {
                        setState(() {
                          selectedMenu = menu;
                        });
                      },
                    ),
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