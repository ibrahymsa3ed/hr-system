import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/auth_service.dart';
import '../../l10n/app_localizations.dart';

class PeriodReportScreen extends StatefulWidget {
  const PeriodReportScreen({super.key});

  @override
  State<PeriodReportScreen> createState() => _PeriodReportScreenState();
}

class _PeriodReportScreenState extends State<PeriodReportScreen> {
  List<dynamic> _rows = [];
  bool _loading = false;
  String? _error;
  DateTime _from = DateTime.now().subtract(const Duration(days: 30));
  DateTime _to = DateTime.now();

  String _fmt(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await context.read<AuthService>().api.get('/reports/period', query: {
        'from': _fmt(_from), 'to': _fmt(_to),
      });
      setState(() => _rows = (res.data['rows'] as List?) ?? []);
    } catch (e) {
      setState(() => _error = ApiClient.errorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context, initialDate: isFrom ? _from : _to,
      firstDate: DateTime(2020), lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() { if (isFrom) _from = picked; else _to = picked; });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
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
            const SizedBox(width: 8),
            FilledButton(onPressed: _loading ? null : _load, child: Text(t.search)),
          ]),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(child: Text(_error!))
                  : _rows.isEmpty
                      ? Center(child: Text(t.noData))
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SingleChildScrollView(
                            child: DataTable(
                              columnSpacing: 16,
                              columns: [
                                DataColumn(label: Text(t.fullCode)),
                                DataColumn(label: Text(t.name)),
                                DataColumn(label: Text(t.section)),
                                DataColumn(label: Text(t.age)),
                                DataColumn(label: Text(t.presentDays), numeric: true),
                                DataColumn(label: Text(t.absentDays), numeric: true),
                                DataColumn(label: Text(t.lateCount), numeric: true),
                                DataColumn(label: Text(t.lateMinutes), numeric: true),
                                DataColumn(label: Text(t.overtimeMinutes), numeric: true),
                                DataColumn(label: Text(t.workingHours), numeric: true),
                                DataColumn(label: Text(t.annualLeave), numeric: true),
                                DataColumn(label: Text(t.sickLeave), numeric: true),
                                DataColumn(label: Text(t.unpaidLeave), numeric: true),
                                DataColumn(label: Text(t.dayOff), numeric: true),
                                DataColumn(label: Text(t.permission), numeric: true),
                                DataColumn(label: Text(t.medicalInsurance)),
                                DataColumn(label: Text(t.socialInsurance)),
                                DataColumn(label: Text(t.remainingPapers), numeric: true),
                                DataColumn(label: Text(t.basicSalary)),
                              ],
                              rows: _rows.map<DataRow>((r) {
                                final row = r as Map;
                                final ld = (row['leave_days'] as Map?) ?? {};
                                return DataRow(cells: [
                                  DataCell(Text('${row['full_code']}')),
                                  DataCell(Text('${row['name']}')),
                                  DataCell(Text('${row['section'] ?? ''}')),
                                  DataCell(Text('${row['age'] ?? '-'}')),
                                  DataCell(Text('${row['present_days']}')),
                                  DataCell(Text('${row['absent_days']}')),
                                  DataCell(Text('${row['late_count']}')),
                                  DataCell(Text('${row['total_late_minutes']}')),
                                  DataCell(Text('${row['overtime_minutes']}')),
                                  DataCell(Text('${row['working_hours']}')),
                                  DataCell(Text('${ld['annual'] ?? 0}')),
                                  DataCell(Text('${ld['sick'] ?? 0}')),
                                  DataCell(Text('${ld['unpaid'] ?? 0}')),
                                  DataCell(Text('${ld['day_off'] ?? 0}')),
                                  DataCell(Text('${row['permissions'] ?? 0}')),
                                  DataCell(Text(row['medical_insurance'] == true ? '✓' : '-')),
                                  DataCell(Text(row['social_insurance'] == true ? '✓' : '-')),
                                  DataCell(Text('${row['remaining_papers'] ?? 0}')),
                                  DataCell(Text('${row['basic_salary'] ?? '-'}')),
                                ]);
                              }).toList(),
                            ),
                          ),
                        ),
        ),
      ],
    );
  }
}
