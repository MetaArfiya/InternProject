import 'package:flutter/material.dart';

import '../../models/partner_sidebar_menu.dart';
import '../../models/partner_job_model.dart';
import '../../models/active_offer_model.dart';
import '../../widgets/partner_sidebar.dart';
import '../../services/auth_storage.dart';
import '../../theme/app_colors.dart';

import '../../sections/partner/partner_dashboard.dart';
import '../../sections/partner/active_offer_screen.dart';
import '../../sections/partner/partner_setting_screen.dart';
import '../../sections/partner/offer_job_screen.dart';
import '../../sections/partner/partner_complaint_screen.dart';

import '../../sections/payment/payment_screen.dart';
import 'income_screen.dart';
import '../../sections/partner/partner_notification_screen.dart';
import '../../sections/partner/partner_tracking_page.dart';
import '../../sections/shared/chat_page.dart';

class PartnerMainDashboard extends StatefulWidget {
  const PartnerMainDashboard({super.key});

  @override
  State<PartnerMainDashboard> createState() => _PartnerMainDashboardState();
}

class _PartnerMainDashboardState extends State<PartnerMainDashboard> {
  // ============================================================
  // STATE
  // ============================================================

  PartnerSidebarMenu selectedMenu = PartnerSidebarMenu.cariPekerjaan;
  PartnerJobModel? selectedJob;
  ActiveOfferModel? _trackingOffer;
  int? _activeChatJobId;
  String? _activeChatTitle;

  final GlobalKey<PartnerSidebarState> _sidebarKey =
      GlobalKey<PartnerSidebarState>();

  // ✅ dari orange → teal
  static const Color _accent = AppColors.primaryTeal;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    _restoreSelectedMenu();
  }

  // ============================================================
  // RESTORE SELECTED MENU
  // ============================================================

  void _restoreSelectedMenu() {
    final savedName = AuthStorage.getString('partner_selected_menu');

    if (savedName == null || savedName.isEmpty) return;

    for (final menu in PartnerSidebarMenu.values) {
      if (menu.name == savedName && mounted) {
        if (menu == PartnerSidebarMenu.offerJob) return;

        setState(() {
          selectedMenu = menu;
        });
        return;
      }
    }
  }

  // ============================================================
  // SAVE SELECTED MENU
  // ============================================================

  void _saveSelectedMenu(PartnerSidebarMenu menu) {
    if (menu == PartnerSidebarMenu.offerJob) return;

    AuthStorage.setString('partner_selected_menu', menu.name);
  }

  // ============================================================
  // HALAMAN AKTIF
  // ============================================================

  Widget currentPage() {
    if (_activeChatJobId != null) {
      return ChatPage(
        jobId: _activeChatJobId!,
        title: _activeChatTitle ?? 'Chat Koordinasi',
        onBack: () => setState(() {
          _activeChatJobId = null;
          _activeChatTitle = null;
        }),
      );
    }

    if (_trackingOffer != null) {
      final offer = _trackingOffer!;
      return PartnerTrackingPage(
        jobId: offer.jobId,
        jobCode: '#JOB-${offer.jobId}',
        title: offer.title,
        onBack: () {
          setState(() => _trackingOffer = null);
        },
        onOpenChat: (title) => setState(() {
          _activeChatJobId = offer.jobId;
          _activeChatTitle = title;
        }),
      );
    }

    switch (selectedMenu) {
      case PartnerSidebarMenu.cariPekerjaan:
        return const PartnerDashboard();

      case PartnerSidebarMenu.offerJob:
        if (selectedJob == null) {
          return const Center(
            child: Text(
              'Silakan pilih pekerjaan terlebih dahulu '
              'dari menu Cari Pekerjaan.',
              style: TextStyle(color: AppColors.grey600),
            ),
          );
        }

        return OfferJobScreen(
          job: selectedJob!,
          onSubmit: () {
            setState(() {
              selectedMenu = PartnerSidebarMenu.penawaranAktif;
            });
            _saveSelectedMenu(PartnerSidebarMenu.penawaranAktif);
          },
          onBack: () {
            setState(() {
              selectedMenu = PartnerSidebarMenu.cariPekerjaan;
            });
            _saveSelectedMenu(PartnerSidebarMenu.cariPekerjaan);
          },
        );

      case PartnerSidebarMenu.penawaranAktif:
        return ActiveOfferScreen(
          onOpenTracking: (offer) {
            setState(() => _trackingOffer = offer);
          },
        );

      case PartnerSidebarMenu.penghasilan:
        return const IncomeScreen();

      case PartnerSidebarMenu.pembayaran:
        return const PaymentScreen(role: 'mitra');

      case PartnerSidebarMenu.notifikasi:
        return PartnerNotificationScreen(
          onOpenChat: (jobId) => setState(() {
            _activeChatJobId = jobId;
            _activeChatTitle = 'Chat Koordinasi';
          }),
        );

      case PartnerSidebarMenu.pengaduan:
        return const PartnerComplaintScreen();

      case PartnerSidebarMenu.pengaturan:
        return PartnerSettingScreen(
          onProfileUpdate: () {
            _sidebarKey.currentState?.refreshProfile();
            setState(() {});
          },
        );
    }
  }

  // ============================================================
  // SIDEBAR MENU SELECTION (DESKTOP)
  // ============================================================

  void _onMenuSelected(PartnerSidebarMenu menu) {
    setState(() {
      _trackingOffer = null;
      _activeChatJobId = null;
      _activeChatTitle = null;
      selectedMenu = menu;
    });
    _saveSelectedMenu(menu);
  }

  // ============================================================
  // BOTTOM NAVIGATION (MOBILE)
  // ============================================================

  int _getBottomNavIndex() {
    switch (selectedMenu) {
      case PartnerSidebarMenu.cariPekerjaan:
        return 0;
      case PartnerSidebarMenu.penawaranAktif:
        return 1;
      case PartnerSidebarMenu.penghasilan:
        return 2;
      case PartnerSidebarMenu.pembayaran:
        return 3;
      case PartnerSidebarMenu.pengaturan:
        return 4;
      case PartnerSidebarMenu.offerJob:
      case PartnerSidebarMenu.notifikasi:
      case PartnerSidebarMenu.pengaduan:
        return 0;
    }
  }

  void _onBottomNavTap(int index) {
    PartnerSidebarMenu menu;

    switch (index) {
      case 0:
        menu = PartnerSidebarMenu.cariPekerjaan;
        break;
      case 1:
        menu = PartnerSidebarMenu.penawaranAktif;
        break;
      case 2:
        menu = PartnerSidebarMenu.penghasilan;
        break;
      case 3:
        menu = PartnerSidebarMenu.pembayaran;
        break;
      case 4:
        menu = PartnerSidebarMenu.pengaturan;
        break;
      default:
        menu = PartnerSidebarMenu.cariPekerjaan;
    }

    setState(() {
      _trackingOffer = null;
      _activeChatJobId = null;
      _activeChatTitle = null;
      selectedMenu = menu;
      selectedJob = null;
    });

    _saveSelectedMenu(menu);
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (_trackingOffer != null || _activeChatJobId != null) {
          return currentPage();
        }

        final bool isDesktop = constraints.maxWidth >= 700;

        if (isDesktop) {
          return Scaffold(
            body: Row(
              children: [
                PartnerSidebar(
                  key: _sidebarKey,
                  activeMenu: selectedMenu,
                  onMenuSelected: _onMenuSelected,
                ),
                Expanded(child: currentPage()),
              ],
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.sectionAltLight, // ← mint muda

          appBar: AppBar(
            toolbarHeight: 52,
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: AppColors.white,
            foregroundColor: AppColors.grey800,
            automaticallyImplyLeading: false,
            title: null,
            titleSpacing: 0,
            actions: [
              IconButton(
                tooltip: 'Notifikasi',
                icon: const Icon(Icons.notifications_outlined),
                color: AppColors.grey700,
                onPressed: () {
                  setState(() {
                    selectedMenu = PartnerSidebarMenu.notifikasi;
                  });
                  _saveSelectedMenu(PartnerSidebarMenu.notifikasi);
                },
              ),
              IconButton(
                tooltip: 'Lapor Masalah',
                icon: const Icon(Icons.report_problem_outlined),
                color: AppColors.grey700,
                onPressed: () {
                  setState(() {
                    selectedMenu = PartnerSidebarMenu.pengaduan;
                  });
                  _saveSelectedMenu(PartnerSidebarMenu.pengaduan);
                },
              ),
              const SizedBox(width: 4),
            ],
          ),

          body: currentPage(),

          bottomNavigationBar: Container(
            decoration: const BoxDecoration(
              color: AppColors.white,
              border: Border(
                top: BorderSide(color: Color(0xFFE5E7EB), width: 1),
              ),
            ),
            child: SafeArea(
              top: false,
              child: BottomNavigationBar(
                currentIndex: _getBottomNavIndex(),
                onTap: _onBottomNavTap,
                type: BottomNavigationBarType.fixed,
                backgroundColor: AppColors.white,
                selectedItemColor: _accent, // ← teal
                unselectedItemColor: AppColors.grey400,
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
                    icon: Icon(Icons.search_outlined, size: 22),
                    activeIcon: Icon(Icons.search, size: 22),
                    label: 'Cari',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.local_offer_outlined, size: 22),
                    activeIcon: Icon(Icons.local_offer, size: 22),
                    label: 'Penawaran',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.bar_chart_outlined, size: 22),
                    activeIcon: Icon(Icons.bar_chart, size: 22),
                    label: 'Penghasilan',
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
      },
    );
  }
}
