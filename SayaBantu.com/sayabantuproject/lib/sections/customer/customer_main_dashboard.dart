import 'package:flutter/material.dart';

import '../../models/sidebar_menu.dart';
import '../../widgets/customer_sidebar.dart';
import '../../services/auth_storage.dart';

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

  static const Color _accent = Color(0xFFF97316);

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();
    _restoreSelectedMenu(); // ✅ BARU
  }

  // ==========================================================
  // ✅ RESTORE SELECTED MENU
  // ==========================================================

  void _restoreSelectedMenu() {
    final savedName = AuthStorage.getString('customer_selected_menu');

    if (savedName == null || savedName.isEmpty) return;

    for (final menu in SidebarMenu.values) {
      if (menu.name == savedName && mounted) {
        // Skip halaman yang butuh state khusus
        if (menu == SidebarMenu.penawaran) return;
        if (menu == SidebarMenu.profilMitra) return;

        setState(() {
          selectedMenu = menu;
        });
        return;
      }
    }
  }

  // ==========================================================
  // ✅ SAVE SELECTED MENU
  // ==========================================================

  void _saveSelectedMenu(SidebarMenu menu) {
    // Skip halaman yang butuh state khusus
    if (menu == SidebarMenu.penawaran) return;
    if (menu == SidebarMenu.profilMitra) return;

    AuthStorage.setString('customer_selected_menu', menu.name);
  }

  // ==========================================================
  // MENU (SIDEBAR — DESKTOP)
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

    _saveSelectedMenu(menu); // ✅ SAVE

    final scaffoldState = Scaffold.maybeOf(context);

    if (scaffoldState != null && scaffoldState.isDrawerOpen) {
      Navigator.of(context).pop();
    }
  }

  // ==========================================================
  // BOTTOM NAVIGATION (MOBILE)
  // ==========================================================

  void _onBottomNavTap(int index) {
    SidebarMenu menu;

    switch (index) {
      case 0:
        menu = SidebarMenu.beranda;
        break;
      case 1:
        menu = SidebarMenu.pembayaran;
        break;
      case 2:
        menu = SidebarMenu.pengaturan;
        break;
      default:
        menu = SidebarMenu.beranda;
    }

    setState(() {
      selectedMenu = menu;
      selectedOffer = null;
      selectedJob = null;
    });

    _saveSelectedMenu(menu); // ✅ SAVE
  }

  int _bottomNavCurrentIndex() {
    switch (selectedMenu) {
      case SidebarMenu.beranda:
        return 0;
      case SidebarMenu.pembayaran:
        return 1;
      case SidebarMenu.pengaturan:
        return 2;
      case SidebarMenu.pengaduan:
      case SidebarMenu.notifikasi:
      case SidebarMenu.penawaran:
      case SidebarMenu.profilMitra:
        return 0;
    }
  }

  // ==========================================================
  // HALAMAN AKTIF
  // ==========================================================

  Widget _currentPage() {
    switch (selectedMenu) {
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

      case SidebarMenu.pembayaran:
        return const PaymentScreen(role: 'pengguna');

      case SidebarMenu.pengaduan:
        return const CustomerComplaintScreen();

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
          onBack: () {
            setState(() {
              selectedMenu = SidebarMenu.beranda;
              selectedJob = null;
              selectedOffer = null;
            });
            _saveSelectedMenu(SidebarMenu.beranda);
          },
          onOpenProfile: (offer) {
            setState(() {
              selectedOffer = offer;
              selectedMenu = SidebarMenu.profilMitra;
            });
          },
          onAccept: (offer) {
            setState(() {
              selectedOffer = offer;
              selectedMenu = SidebarMenu.beranda;
            });
            _saveSelectedMenu(SidebarMenu.beranda);
          },
          onReject: (offer) {
            setState(() {
              selectedOffer = offer;
            });
          },
        );

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

      case SidebarMenu.notifikasi:
        return const NotificationScreen();

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
                border: Border.all(color: const Color(0xffE5E7EB)),
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
                    child: Icon(icon, size: 24, color: Colors.grey),
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
  // DESKTOP LAYOUT
  // ==========================================================

  Widget _buildDesktopLayout() {
    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CustomerSidebar(
            key: _sidebarKey,
            activeMenu: selectedMenu,
            onMenuSelected: _onMenuSelected,
          ),
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
  // MOBILE LAYOUT
  // ==========================================================

  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        toolbarHeight: 52,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        automaticallyImplyLeading: false,
        title: null,
        titleSpacing: 0,
        actions: [
          IconButton(
            tooltip: 'Notifikasi',
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              setState(() {
                selectedMenu = SidebarMenu.notifikasi;
              });
              _saveSelectedMenu(SidebarMenu.notifikasi);
            },
          ),
          IconButton(
            tooltip: 'Pengaduan',
            icon: const Icon(Icons.report_problem_outlined),
            onPressed: () {
              setState(() {
                selectedMenu = SidebarMenu.pengaduan;
              });
              _saveSelectedMenu(SidebarMenu.pengaduan);
            },
          ),
          const SizedBox(width: 4),
        ],
      ),

      body: SafeArea(
        top: false,
        bottom: false,
        child: _currentPage(),
      ),

      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Color(0xFFE5E7EB), width: 1),
          ),
        ),
        child: SafeArea(
          top: false,
          child: BottomNavigationBar(
            currentIndex: _bottomNavCurrentIndex(),
            onTap: _onBottomNavTap,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: _accent,
            unselectedItemColor: const Color(0xFF94A3B8),
            selectedFontSize: 11,
            unselectedFontSize: 11,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
            elevation: 0,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined, size: 22),
                activeIcon: Icon(Icons.home, size: 22),
                label: 'Beranda',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.payment_outlined, size: 22),
                activeIcon: Icon(Icons.payment, size: 22),
                label: 'Pembayaran',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings_outlined, size: 22),
                activeIcon: Icon(Icons.settings, size: 22),
                label: 'Pengaturan',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 700;
        if (isDesktop) return _buildDesktopLayout();
        return _buildMobileLayout();
      },
    );
  }
}