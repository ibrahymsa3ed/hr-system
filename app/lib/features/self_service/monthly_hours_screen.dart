import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/auth_service.dart';
import '../../l10n/app_localizations.dart';

class MonthlyHoursScreen extends StatefulWidget {
  const MonthlyHoursScreen({super.key});

  @override
  State<MonthlyHoursScreen> createState() => _MonthlyHoursScreenState();
}

class _MonthlyHoursScreenState extends State<MonthlyHoursScreen> {
  Map<String, dynamic>? _data;
  String? _error;
  late String _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    _load();
  }

  Future<void> _load() async {
    setState(() { _data = null; _error = null; });
    try {
      final res = await context.read<AuthService>().api.get('/me/monthly-report', query: {'month': _month});
      setState(() => _data = (res.data as Map).cast<String, dynamic>());
    } catch (e) {
      setState(() => _error = ApiClient.errorMessage(e));
    }
  }

  void _changeMonth(int delta) {
    final parts = _month.split('-');
    var y = int.parse(parts[0]);
    var m = int.parse(parts[1]) + delta;
    if (m > 12) { m = 1; y++; }
    if (m < 1) { m = 12; y--; }
    _month = '$y-${m.toString().padLeft(2, '0')}';
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(onPressed: () => _changeMonth(-1), icon: const Icon(Icons.chevron_left)),
              Text(_month, style: Theme.of(context).textTheme.titleLarge),
              IconButton(onPressed: () => _changeMonth(1), icon: const Icon(Icons.chevron_right)),
            ],
          ),
          const SizedBox(height: 24),
          if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
          if (_data == null && _error == null) const CircularProgressIndicator(),
          if (_data != null) ...[
            _card(Icons.timer, t.totalHours, '${_data!['total_hours']}'),
            _card(Icons.calendar_today, t.presentDays, '${_data!['present_days']}'),
            _card(Icons.warning_amber, t.lateCount, '${_data!['late_count']}'),
            _card(Icons.more_time, t.overtimeHours, '${_data!['overtime_hours']}'),
          ],
        ],
      ),
    );
  }

  Widget _card(IconData icon, String label, String value) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(label),
        trailing: Text(value, style: Theme.of(context).textTheme.headlineSmall),
      ),
    );
  }
}
