import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/auth_service.dart';
import '../../l10n/app_localizations.dart';

class DailyReportScreen extends StatefulWidget {
  const DailyReportScreen({super.key});

  @override
  State<DailyReportScreen> createState() => _DailyReportScreenState();
}

class _DailyReportScreenState extends State<DailyReportScreen> {
  List<dynamic> _records = [];
  bool _loading = true;
  String? _error;
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _fmt(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await context.read<AuthService>().api.get('/reports/daily', query: {'date': _fmt(_date)});
      setState(() => _records = (res.data['records'] as List?) ?? []);
    } catch (e) {
      setState(() => _error = ApiClient.errorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context, initialDate: _date,
      firstDate: DateTime(2020), lastDate: DateTime.now(),
    );
    if (picked != null) { setState(() => _date = picked); _load(); }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today),
            label: Text('${t.date}: ${_fmt(_date)}'),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(child: Text(_error!))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: _records.isEmpty
                          ? ListView(children: [ListTile(title: Text(t.noData))])
                          : ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: _records.length,
                              itemBuilder: (context, i) {
                                final r = _records[i] as Map;
                                final emp = r['employee'] as Map?;
                                return Card(child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: (r['late_minutes'] ?? 0) > 0 ? Colors.orange : Colors.green,
                                    child: Text('${r['late_minutes'] ?? 0}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                                  ),
                                  title: Text(emp != null ? '${emp['full_code']} ${emp['first_name']} ${emp['last_name']}' : '-'),
                                  subtitle: Text('In: ${r['check_in_at'] ?? '-'}  Out: ${r['check_out_at'] ?? '-'}'),
                                  trailing: Text('${r['worked_minutes'] ?? 0} min'),
                                ));
                              },
                            ),
                    ),
        ),
      ],
    );
  }
}
