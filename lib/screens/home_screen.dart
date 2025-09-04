// home_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'auth_screen.dart';
import 'live_map.dart';
import 'heartbeat_panel.dart';
import 'package:url_launcher/url_launcher.dart'; // ADD for launchUrl with Uri [uses tel:]
// If you prefer string helpers, use: import 'package:url_launcher/url_launcher_string.dart';

class HomeScreen extends StatefulWidget {
  final String username;
  const HomeScreen({super.key, required this.username});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  static const List<Widget> _widgetOptions = <Widget>[
    DashboardTab(),
    ProfileTab(),
    SettingsTab(),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeInOut),
      ),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0D1B2A), Color(0xFF1B263B), Color(0xFF415A77)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            'Welcome, ${widget.username}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, size: 22),
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const AuthScreen()),
                      (route) => false,
                );
              },
            ),
          ],
        ),
        body: Stack(
          children: [
            // Background shapes
            Positioned(
              top: -size.width * 0.2,
              left: -size.width * 0.2,
              child: Container(
                width: size.width * 0.6,
                height: size.width * 0.6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.teal.withOpacity(0.1),
                ),
              ),
            ),
            Positioned(
              bottom: -size.width * 0.3,
              right: -size.width * 0.2,
              child: Container(
                width: size.width * 0.7,
                height: size.width * 0.7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.teal.withOpacity(0.1),
                ),
              ),
            ),

            // Tab content anchored at the top (single render path)
            Align(
              alignment: Alignment.topCenter,
              child: SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: _widgetOptions.elementAt(_selectedIndex),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: _buildModernNavBar(),
      ),
    );
  }

  Widget _buildModernNavBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.grey.withOpacity(0.5),
        border: Border.all(color: Colors.teal.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 2,
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_rounded),
              label: 'Settings',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.tealAccent.shade400,
          unselectedItemColor: Colors.grey,
          backgroundColor: Colors.transparent,
          elevation: 0,
          onTap: _onItemTapped,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 12,
          unselectedFontSize: 12,
        ),
      ),
    );
  }
}

// Dashboard Tab (toggle on top, panel directly below)
class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});
  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  int _segment = 0; // 0 = Location, 1 = Heartbeat

  // ADD: Emergency call helpers
  Future<void> _confirmAndCall(BuildContext context, String label, String number) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Confirm $label'),
        content: Text('Call $number now?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Call')),
        ],
      ),
    );
    if (result != true) return;

    final uri = Uri(scheme: 'tel', path: number);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top segmented control
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.teal.withOpacity(0.3)),
            ),
            padding: const EdgeInsets.all(6),
            child: CupertinoSlidingSegmentedControl<int>(
              backgroundColor: Colors.white.withOpacity(0.08),
              thumbColor: Colors.tealAccent.shade400,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
              groupValue: _segment,
              children: const {
                0: Padding(
                  padding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                  child: Text('Location', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
                1: Padding(
                  padding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                  child: Text('Heartbeat', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              },
              onValueChanged: (value) {
                if (value == null) return;
                setState(() => _segment = value);
              },
            ),
          ),

          const SizedBox(height: 10),

          // The active panel directly under the toggle
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: _segment == 0
                ? const LiveMap(key: ValueKey('loc'))          // fixed 350 height inside
                : const HeartbeatPanel(key: ValueKey('hb')),   // fixed 350 height inside
          ),

          const SizedBox(height: 12),

          // Emergency buttons row
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _confirmAndCall(context, 'Ambulance', '108'), // India ambulance
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.local_hospital_rounded),
                  label: const Text('Call ambulance'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _confirmAndCall(context, 'Emergency', '112'), // Single emergency
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: cs.primary),
                    foregroundColor: cs.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.emergency_share_rounded),
                  label: const Text('Call emergency'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Profile Tab (example placeholder)
class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.teal.withOpacity(0.2),
              border: Border.all(color: Colors.teal, width: 2),
            ),
            child: const Icon(Icons.person_rounded, size: 60, color: Colors.teal),
          ),
          const SizedBox(height: 24),
          const Text('Your Profile', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 12),
          const Text('Manage your personal information', style: TextStyle(fontSize: 16, color: Colors.grey)),
        ],
      ),
    );
  }
}

// Settings Tab (example placeholder)
class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Settings', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.grey)),
          SizedBox(height: 12),
          Text('Customize your experience', style: TextStyle(fontSize: 16, color: Colors.grey)),
        ],
      ),
    );
  }
}