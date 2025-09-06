// home_screen.dart
import 'dart:async'; // for Timer
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'auth_screen.dart';
import 'live_map.dart';
import 'heartbeat_panel.dart';
import 'package:url_launcher/url_launcher.dart'; // For tel: calls
import 'profile_screen.dart';
import '../services/location_service.dart';
import '../services/api_service.dart';


class HomeScreen extends StatefulWidget {
  final String email;
  final String name;

  const HomeScreen({super.key, required this.email, required this.name});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}


class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Build tabs with per-instance data (widget.username)
  List<Widget> get _tabs => <Widget>[
    const DashboardTab(),
    ProfileScreen(email: widget.email),
    SettingsTab(email: widget.email),
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

    // 🚀 Start live location updates
    LocationService.startLiveUpdates(widget.email);
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
            'Welcome, ${widget.name}',
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

            // Tab content anchored at the top
            Align(
              alignment: Alignment.topCenter,
              child: SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: _tabs.elementAt(_selectedIndex), // <- use getter here
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

  // Panic press-and-hold state
  bool _isPanicHolding = false;
  double _panicProgress = 0.0;
  Timer? _panicTimer;

  // Confirmation + dial
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

  // PANIC: start 2s hold countdown
  void _startPanicHold() {
    _panicTimer?.cancel();
    setState(() {
      _isPanicHolding = true;
      _panicProgress = 0.0;
    });

    // 2 seconds -> 40 ticks of 50ms = progress to 1.0
    _panicTimer = Timer.periodic(const Duration(milliseconds: 50), (t) {
      setState(() {
        _panicProgress += 1 / 40;
        if (_panicProgress >= 1.0) {
          _panicProgress = 1.0;
          _isPanicHolding = false;
          t.cancel();
          _onPanicTriggered();
        }
      });
    });
  }

  void _cancelPanicHold() {
    _panicTimer?.cancel();
    setState(() {
      _isPanicHolding = false;
      _panicProgress = 0.0;
    });
  }

  Future<void> _onPanicTriggered() async {
    final ctx = context;
    if (!mounted) return;
    await showDialog(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        title: const Text('PANIC Triggered'),
        content: const Text('Hold complete. Execute your emergency workflow here.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _panicTimer?.cancel();
    super.dispose();
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
          // Segmented control
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

          // Active panel
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: _segment == 0
                ? const LiveMap(key: ValueKey('loc'))
                : const HeartbeatPanel(key: ValueKey('hb')),
          ),

          const SizedBox(height: 12),

          // Emergency primary row
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _confirmAndCall(context, 'Ambulance', '108'),
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
                  onPressed: () => _confirmAndCall(context, 'Emergency', '112'),
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

          const SizedBox(height: 10),

          // Emergency secondary row: Women and Child helplines
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _confirmAndCall(context, 'Women Helpline', '1091'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.pinkAccent),
                    foregroundColor: Colors.pinkAccent,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.woman_2_rounded),
                  label: const Text('Call women helpline'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _confirmAndCall(context, 'Child Helpline', '1098'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.orange),
                    foregroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.child_care_rounded),
                  label: const Text('Call child helpline'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // PANIC: Full-width press-and-hold button
          GestureDetector(
            onLongPressStart: (_) => _startPanicHold(),
            onLongPressEnd: (_) => _cancelPanicHold(),
            onLongPressCancel: _cancelPanicHold,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.red.shade700,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.shade900.withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                ),
                if (_isPanicHolding)
                  Positioned(
                    right: 14,
                    child: SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                        value: _panicProgress.clamp(0.0, 1.0),
                        strokeWidth: 3,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        backgroundColor: Colors.white24,
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.sos_rounded, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        _isPanicHolding ? 'Hold to trigger...' : 'PANIC',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Press and hold for 2 seconds to activate',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// Settings Tab (example placeholder)
// Settings Tab with privacy toggles
class SettingsTab extends StatefulWidget {
  final String email;

  const SettingsTab({super.key, required this.email});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  bool _shareHealth = false;
  bool _shareLocation = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPrivacySettings();
  }

  Future<void> _loadPrivacySettings() async {
    setState(() => _isLoading = true);

    final result = await ApiService.getPrivacySettings(widget.email);

    if (result['success'] == true) {
      setState(() {
        _shareHealth = result['share_health'] ?? false;
        _shareLocation = result['share_location'] ?? false;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      // Optional: Show error message
    }
  }

  Future<void> _updatePrivacySettings() async {
    setState(() => _isLoading = true);

    final result = await ApiService.updatePrivacySettings(
      widget.email,
      _shareHealth,
      _shareLocation,
    );

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Privacy settings updated'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update: ${result['message']}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Privacy Settings',
            style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Control what data you share for safety features',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 32),

          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            Column(
              children: [
                // Health Data Toggle
                _buildPrivacyToggle(
                  value: _shareHealth,
                  onChanged: (value) => setState(() => _shareHealth = value!),
                  title: 'Share Health Data',
                  subtitle: 'Allow emergency services to access your medical information when needed',
                  icon: Icons.medical_services_outlined,
                ),
                const SizedBox(height: 24),

                // Location Sharing Toggle
                _buildPrivacyToggle(
                  value: _shareLocation,
                  onChanged: (value) => setState(() => _shareLocation = value!),
                  title: 'Share Location',
                  subtitle: 'Enable location sharing for crash detection and emergency services',
                  icon: Icons.location_on_outlined,
                ),
                const SizedBox(height: 32),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _updatePrivacySettings,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.tealAccent.shade400,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Save Privacy Settings',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildPrivacyToggle({
    required bool value,
    required ValueChanged<bool?> onChanged,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2A3A).withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.tealAccent.shade400, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.tealAccent.shade400,
            activeTrackColor: Colors.tealAccent.shade400.withOpacity(0.5),
          ),
        ],
      ),
    );
  }
}