import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/auth_service.dart';
import '../../l10n/app_localizations.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _data;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await context.read<AuthService>().api.get('/dashboard');
      setState(() => _data = (res.data as Map).cast<String, dynamic>());
    } catch (e) {
      setState(() => _error = ApiClient.errorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    if (_error != null) return Center(child: Text(_error!));
    if (_data == null) return const Center(child: CircularProgressIndicator());

    final totals = (_data!['totals'] as Map?) ?? {};
    final today = (_data!['today'] as Map?) ?? {};
    final bySection = (_data!['by_section'] as List?)?.cast<Map>() ?? [];

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _StatCard(label: t.totalEmployees, value: '${totals['employees'] ?? 0}', icon: Icons.people),
              _StatCard(label: t.branches, value: '${totals['branches'] ?? 0}', icon: Icons.store),
              _StatCard(label: t.sections, value: '${totals['sections'] ?? 0}', icon: Icons.category),
              _StatCard(label: t.presentToday, value: '${today['present'] ?? 0}', icon: Icons.login),
              _StatCard(label: t.lateToday, value: '${today['late'] ?? 0}', icon: Icons.timer),
              _StatCard(label: t.pendingApprovals, value: '${_data!['pending_approvals'] ?? 0}', icon: Icons.fact_check),
            ],
          ),
          if (bySection.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(t.bySection, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final s in bySection)
              Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text('${s['main_code']}')),
                  title: Text('${s['name']}'),
                  trailing: Text('${s['employees']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 8),
              Text(value, style: Theme.of(context).textTheme.headlineSmall),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
