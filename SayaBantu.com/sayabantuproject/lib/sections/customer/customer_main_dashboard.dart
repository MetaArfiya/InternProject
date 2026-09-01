import 'package:flutter/material.dart';

import '../../../models/sidebar_menu.dart';
import '../../../widgets/customer_sidebar.dart';

import '../../models/job_model.dart';
import '../../models/offer_model.dart';

import '../../screens/Screens_Customer/offer_screen.dart';
import '../../screens/Screens_Customer/partner_profile_screen.dart';

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

  Widget currentPage() {
    switch (selectedMenu) {
      case SidebarMenu.beranda:
        // 🚀 Disesuaikan: Hanya mengirim onOpenOffer karena CustomerDashboard 
        // sudah mengambil data & menangani aksi 'Selesai' via API internal.
        return CustomerDashboard(
          onOpenOffer: (job) {
            setState(() {
              selectedJob = job;
              selectedMenu = SidebarMenu.penawaran;
            });
          },
        );

      case SidebarMenu.penawaran:
        if (selectedJob == null) {
          return const Center(
            child: Text(
              "Belum ada pekerjaan yang dipilih.\nSilakan pilih pekerjaan dari Beranda.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 16),
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
                content: Text("Penawaran ${offer.name} berhasil ditolak."),
              ),
            );
          },
        );

      case SidebarMenu.profilMitra:
        if (selectedOffer == null) {
          return const Center(
            child: Text(
              "Belum ada profil mitra yang dipilih.",
              style: TextStyle(color: Colors.grey, fontSize: 16),
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

      case SidebarMenu.notifikasi:
        return NotificationScreen();

      case SidebarMenu.pengaturan:
        return CustomerSettingScreen(
          onProfileUpdate: () {
            setState(() {});
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
                    child: CustomerSidebar(
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
                  title: const Text("Dashboard Pelanggan"),
                ),
          body: isDesktop
              ? Row(
                  children: [
                    CustomerSidebar(
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