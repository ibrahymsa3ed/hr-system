import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/auth_service.dart';
import '../../core/date_utils.dart' as du;
import '../../l10n/app_localizations.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  List<dynamic> _records = [];
  bool _loading = true;
  String? _error;
  DateTime _from = DateTime.now().subtract(const Duration(days: 30));
  DateTime _to = DateTime.now();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await context.read<AuthService>().api.get('/attendance', query: {
        'from': _fmt(_from), 'to': _fmt(_to), 'per_page': 100,
      });
      setState(() => _records = (res.data['data'] as List?) ?? []);
    } catch (e) {
      setState(() => _error = ApiClient.errorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _fmt(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context, initialDate: isFrom ? _from : _to,
      firstDate: DateTime(2020), lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() { if (isFrom) _from = picked; else _to = picked; });
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(child: OutlinedButton.icon(
                onPressed: () => _pickDate(true),
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text('${t.from}: ${_fmt(_from)}'),
              )),
              const SizedBox(width: 8),
              Expanded(child: OutlinedButton.icon(
                onPressed: () => _pickDate(false),
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text('${t.to}: ${_fmt(_to)}'),
              )),
            ],
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
                              itemCount: _records.length,
                              itemBuilder: (context, i) {
                                final r = _records[i] as Map;
                                final emp = r['employee'] as Map?;
                                final checkIn = r['check_in_at'] ?? '-';
                                final checkOut = r['check_out_at'] ?? '-';
                                return Card(
                                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  child: ListTile(
                                    leading: CircleAvatar(child: Text('${r['late_minutes'] ?? 0}', style: const TextStyle(fontSize: 12))),
                                    title: Text(emp != null ? '${emp['first_name']} ${emp['last_name']}' : '${r['employee_id']}'),
                                    subtitle: Text('${du.fmtDate(r['work_date'])}  In: ${du.fmtTime(checkIn)}  Out: ${du.fmtTime(checkOut)}'),
                                    trailing: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('${r['worked_minutes'] ?? 0} min', style: const TextStyle(fontSize: 12)),
                                        if ((r['overtime_minutes'] ?? 0) > 0)
                                          Text('+${r['overtime_minutes']} OT', style: const TextStyle(fontSize: 11, color: Colors.blue)),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
        ),
      ],
    );
  }
}
