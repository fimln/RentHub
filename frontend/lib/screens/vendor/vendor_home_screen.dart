import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';
import 'vendor_dashboard_screen.dart';
import 'vendor_fleet_screen.dart';
import 'vendor_map_screen.dart';
import 'vendor_booking_list_screen.dart';
import 'vendor_notification_screen.dart';

class VendorHomeScreen extends StatefulWidget {
  const VendorHomeScreen({super.key});
  @override
  State<VendorHomeScreen> createState() => _VendorHomeScreenState();
}

class _VendorHomeScreenState extends State<VendorHomeScreen> {
  int _idx = 0;
  int _unreadCount = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      VendorDashboardScreen(onSwitchTab: _switchTab),
      const VendorFleetScreen(),
      const VendorMapScreen(),
      const VendorBookingListScreen(),
      VendorNotificationScreen(onRead: _decrementUnread),
    ];
    _loadUnreadCount();
  }

  void _switchTab(int i) => setState(() => _idx = i);

  void _decrementUnread() {
    if (_unreadCount > 0) setState(() => _unreadCount--);
  }

  Future<void> _loadUnreadCount() async {
    try {
      final res = await ApiService.getVendorNotifications();
      if (res['success'] == true && mounted) {
        final list = (res['data'] as List?) ?? [];
        setState(() => _unreadCount = list.where((n) => n['is_read'] != true).length);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(index: _idx, children: _screens),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _idx,
      onDestinationSelected: (i) {
        setState(() => _idx = i);
        if (i == 4) _loadUnreadCount();
      },
      backgroundColor: Colors.white,
      indicatorColor: AppTheme.primaryLight,
      destinations: [
        const NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard_rounded, color: AppTheme.primary),
          label: 'Dashboard',
        ),
        const NavigationDestination(
          icon: Icon(Icons.two_wheeler_outlined),
          selectedIcon: Icon(Icons.two_wheeler, color: AppTheme.primary),
          label: 'Armada',
        ),
        const NavigationDestination(
          icon: Icon(Icons.map_outlined),
          selectedIcon: Icon(Icons.map_rounded, color: AppTheme.primary),
          label: 'Peta',
        ),
        const NavigationDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long_rounded, color: AppTheme.primary),
          label: 'Booking',
        ),
        NavigationDestination(
          icon: Badge(
            isLabelVisible: _unreadCount > 0,
            label: Text('$_unreadCount'),
            child: const Icon(Icons.notifications_outlined),
          ),
          selectedIcon: Badge(
            isLabelVisible: _unreadCount > 0,
            label: Text('$_unreadCount'),
            child: const Icon(Icons.notifications_rounded, color: AppTheme.primary),
          ),
          label: 'Notifikasi',
        ),
      ],
    ),
  );
}
