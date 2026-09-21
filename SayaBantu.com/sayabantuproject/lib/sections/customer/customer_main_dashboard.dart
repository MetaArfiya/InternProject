import 'package:flutter/material.dart';

import '../../models/sidebar_menu.dart';
import '../../widgets/customer_sidebar.dart';

import '../../models/job_model.dart';
import '../../models/offer_model.dart';

import '../../screens/Screens_Customer/offer_screen.dart';
import '../../screens/Screens_Customer/partner_profile_screen.dart';

import 'customer_dashboard.dart';
import 'customer_complaint_screen.dart';
import 'notification_screen.dart';
import 'setting_screen.dart';

import '../../sections/payment/payment_screen.dart';

class CustomerMainDashboard extends StatefulWidget {
  const CustomerMainDashboard({super.key});

  @override
  State<CustomerMainDashboard> createState() =>
      _CustomerMainDashboardState();
}

class _CustomerMainDashboardState extends State<CustomerMainDashboard> {
  // ==========================================================
  // STATE
  // ==========================================================

  SidebarMenu selectedMenu = SidebarMenu.beranda;

  JobModel? selectedJob;
  OfferModel? selectedOffer;

  final GlobalKey<CustomerSidebarState> _sidebarKey =
      GlobalKey<CustomerSidebarState>();

  // ==========================================================
  // MENU
  // ==========================================================

  void _onMenuSelected(SidebarMenu menu) {
    setState(() {
      selectedMenu = menu;

      if (menu != SidebarMenu.penawaran) {
        selectedOffer = null;
      }

      if (menu != SidebarMenu.profilMitra) {
        selectedJob = null;
      }
    });

    // Tutup drawer pada mobile.
    final scaffoldState = Scaffold.maybeOf(context);

    if (scaffoldState != null && scaffoldState.isDrawerOpen) {
      Navigator.of(context).pop();
    }
  }

  // ==========================================================
  // HALAMAN AKTIF
  // ==========================================================

  Widget _currentPage() {
    switch (selectedMenu) {
      // ========================================================
      // BERANDA
      // ========================================================

      case SidebarMenu.beranda:
        return CustomerDashboard(
          onOpenOffer: (job) {
            setState(() {
              selectedJob = job;
              selectedOffer = null;
              selectedMenu = SidebarMenu.penawaran;
            });
          },
        );

      // ========================================================
      // PEMBAYARAN
      // ========================================================

      case SidebarMenu.pembayaran:
        return const PaymentScreen(
          role: 'pengguna',
        );

      // ========================================================
      // PENGADUAN
      // ========================================================

      case SidebarMenu.pengaduan:
        return const CustomerComplaintScreen();

      // ========================================================
      // PENAWARAN
      // ========================================================

      case SidebarMenu.penawaran:
        if (selectedJob == null) {
          return _buildEmptyPage(
            icon: Icons.local_offer_outlined,
            title: 'Penawaran',
            message: 'Belum ada pekerjaan yang dipilih.',
          );
        }

        return OfferScreen(
          job: selectedJob!,

          // ----------------------------------------------------
          // KEMBALI
          // ----------------------------------------------------

          onBack: () {
            setState(() {
              selectedMenu = SidebarMenu.beranda;
              selectedJob = null;
              selectedOffer = null;
            });
          },

          // ----------------------------------------------------
          // BUKA PROFIL MITRA
          // ----------------------------------------------------

          onOpenProfile: (offer) {
            setState(() {
              selectedOffer = offer;
              selectedMenu = SidebarMenu.profilMitra;
            });
          },

          // ----------------------------------------------------
          // TERIMA PENAWARAN
          // ----------------------------------------------------

          onAccept: (offer) {
            setState(() {
              selectedOffer = offer;
              selectedMenu = SidebarMenu.beranda;
            });
          },

          // ----------------------------------------------------
          // TOLAK PENAWARAN
          // ----------------------------------------------------

          onReject: (offer) {
            setState(() {
              selectedOffer = offer;
            });
          },
        );

      // ========================================================
      // PROFIL MITRA
      // ========================================================

      case SidebarMenu.profilMitra:
        if (selectedOffer == null) {
          return _buildEmptyPage(
            icon: Icons.person_outline,
            title: 'Profil Mitra',
            message: 'Belum ada mitra yang dipilih.',
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

      // ========================================================
      // NOTIFIKASI
      // ========================================================

      case SidebarMenu.notifikasi:
        return const NotificationScreen();

      // ========================================================
      // PENGATURAN
      // ========================================================

      case SidebarMenu.pengaturan:
        return CustomerSettingScreen(
          onProfileUpdate: () {
            _sidebarKey.currentState?.refreshProfile();
          },
        );
    }
  }

  // ==========================================================
  // EMPTY PAGE
  // ==========================================================

  Widget _buildEmptyPage({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: 6),

            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
            ),

            const SizedBox(height: 24),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 48,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xffE5E7EB),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xffF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      size: 24,
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 14),

                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // DESKTOP
  // ==========================================================

  Widget _buildDesktopLayout() {
    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ====================================================
          // SIDEBAR
          // ====================================================

          CustomerSidebar(
            key: _sidebarKey,
            activeMenu: selectedMenu,
            onMenuSelected: _onMenuSelected,
          ),

          // ====================================================
          // CONTENT
          // ====================================================

          Expanded(
            child: Align(
              alignment: Alignment.topLeft,
              child: _currentPage(),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // MOBILE / TABLET
  // ==========================================================

  Widget _buildMobileLayout() {
    return Scaffold(
      drawer: CustomerSidebar(
        key: _sidebarKey,
        activeMenu: selectedMenu,
        onMenuSelected: _onMenuSelected,
      ),

      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).colorScheme.onSurface,

        title: const Text(
          'Dashboard Pelanggan',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),

      body: _currentPage(),
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1000;

        if (isDesktop) {
          return _buildDesktopLayout();
        }

        return _buildMobileLayout();
      },
    );
  }
}