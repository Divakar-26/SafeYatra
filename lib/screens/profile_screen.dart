// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  final String email;
  const ProfileScreen({super.key, required this.email});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Map<String, dynamic>> _load() async {
    final res = await ApiService.getProfileByEmail(widget.email);
    if (res['success'] == true) {
      final data = (res['data'] as Map<String, dynamic>);
      return data;
    } else {
      throw Exception(res['message'] ?? 'Failed to load profile');
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });
    await _future.catchError((_) {});
  }

  // Function to share profile information
  void _shareProfile(Map<String, dynamic> data) {
    final name = (data['name'] ?? data['full_name'] ?? '').toString();
    final email = (data['email'] ?? widget.email).toString();
    final profileId = (data['id'] ?? '').toString();

    final shareText = '''
My Profile Information:
Name: $name
Email: $email
Profile ID: $profileId
Emergency Contact: ${data['emergency_contact'] ?? 'Not set'}
''';

    Share.share(shareText, subject: 'My Profile Information');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorView(
              message: snapshot.error.toString(),
              onRetry: _refresh,
            );
          }

          final data = snapshot.data!;
          final name = (data['name'] ?? data['full_name'] ?? '').toString();
          final email = (data['email'] ?? widget.email).toString();
          final gender = (data['gender'] ?? '').toString();
          final age = data['age']?.toString() ?? '';
          final mobile = (data['mobile_number'] ?? '').toString();
          final aadhar = (data['aadhar_number'] ?? '').toString();
          final passport = (data['passport'] ?? '').toString();
          final emergency = (data['emergency_contact'] ?? '').toString();
          final conditions = (data['medical_conditions'] ?? '').toString();
          final allergies = (data['allergies'] ?? '').toString();
          final profileId = (data['id'] ?? '').toString();

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              children: [
                // Header card with share button
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cs.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: cs.primary.withOpacity(0.12),
                        child: Icon(Icons.person_rounded, color: cs.primary, size: 28),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name.isNotEmpty ? name : email,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              email,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                            if (profileId.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'ID: $profileId',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                  fontFamily: 'Monospace',
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.share_rounded, color: cs.primary),
                        onPressed: () => _shareProfile(data),
                        tooltip: 'Share profile',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Info grid
                _InfoTile(icon: Icons.person_outline, label: 'Gender', value: gender),
                _InfoTile(icon: Icons.cake_outlined, label: 'Age', value: age),
                _InfoTile(icon: Icons.call_outlined, label: 'Mobile', value: mobile),
                _InfoTile(icon: Icons.badge_outlined, label: 'Aadhaar', value: aadhar),
                _InfoTile(icon: Icons.travel_explore_outlined, label: 'Passport', value: passport),
                _InfoTile(icon: Icons.sos_outlined, label: 'Emergency', value: emergency),

                if (conditions.isNotEmpty) _InfoNote(label: 'Medical conditions', value: conditions),
                if (allergies.isNotEmpty) _InfoNote(label: 'Allergies', value: allergies),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _refresh,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Refresh'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _shareProfile(data),
                        icon: const Icon(Icons.share_rounded),
                        label: const Text('Share'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Helper widget for info tiles
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(icon, color: cs.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Text(
            value.isNotEmpty ? value : '—',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: value.isNotEmpty ? cs.onSurface : cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// Helper widget for info notes (multi-line content)
class _InfoNote extends StatelessWidget {
  final String label;
  final String value;
  const _InfoNote({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              )),
          const SizedBox(height: 6),
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

// Error view widget
class _ErrorView extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, color: cs.error, size: 36),
            const SizedBox(height: 8),
            Text(
              'Failed to load profile',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}