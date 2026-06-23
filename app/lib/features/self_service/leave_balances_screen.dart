import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/auth_service.dart';
import '../../l10n/app_localizations.dart';

class LeaveBalancesScreen extends StatefulWidget {
  const LeaveBalancesScreen({super.key});

  @override
  State<LeaveBalancesScreen> createState() => _LeaveBalancesScreenState();
}

class _LeaveBalancesScreenState extends State<LeaveBalancesScreen> {
  List<dynamic> _balances = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await context.read<AuthService>().api.get('/me/leave-balances');
      setState(() => _balances = res.data is List ? res.data : []);
    } catch (e) {
      setState(() => _error = ApiClient.errorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _typeLabel(AppLocalizations t, String type) => switch (type) {
        'annual' => t.annualLeave,
        'sick' => t.sickLeave,
        'unpaid' => t.unpaidLeave,
        'day_off' => t.dayOff,
        _ => type,
      };

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));
    if (_balances.isEmpty) return Center(child: Text(t.noData));

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _balances.length,
        itemBuilder: (context, i) {
          final b = _balances[i] as Map;
          final entitled = (b['entitled'] ?? 0).toDouble();
          final used = (b['used'] ?? 0).toDouble();
          final remaining = (b['remaining'] ?? 0).toDouble();
          final progress = entitled > 0 ? (used / entitled).clamp(0.0, 1.0) : 0.0;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_typeLabel(t, '${b['type']}'), style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(value: progress, minHeight: 8, borderRadius: BorderRadius.circular(4)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${t.entitled}: $entitled'),
                      Text('${t.used}: $used'),
                      Text('${t.remaining}: $remaining', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
